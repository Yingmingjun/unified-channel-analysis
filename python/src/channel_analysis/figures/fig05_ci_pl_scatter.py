"""Fig. 5 — Close-in path-loss scatter with CI fits, pooled sub-THz and 6.75 GHz.

LOS and NLOS are fit separately per dataset (NYU-only, USC-only, Pooled).
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from .. import config
from ..io import load_point_data
from ..pl import ci_fit, _fspl_db
from ._common import apply_style, save


def _fit_group(df, loc_type):
    d = df[df.loc_type == loc_type]["d_m"].to_numpy()
    pl = df[df.loc_type == loc_type]["pl_db"].to_numpy()
    freq = float(df["freq_ghz"].iloc[0]) if len(df) else 0.0
    return ci_fit(d, pl, freq_ghz=freq), d, pl


def _plot_band(ax, band_name: str, freq_like: float, nyu, usc, pooled, title: str):
    d_grid = np.logspace(0, np.log10(500), 200)
    fspl_nyu = _fspl_db(nyu.freq_ghz)
    fspl_usc = _fspl_db(usc.freq_ghz)
    fspl_pool = _fspl_db(freq_like)

    # Scatter
    ax.scatter(nyu.data[nyu.data.loc_type == "LOS"]["d_m"],
               nyu.data[nyu.data.loc_type == "LOS"]["pl_db"],
               color=config.COLORS["nyu"], marker="o", s=36, label="NYU LOS", edgecolor="k", linewidths=0.6)
    ax.scatter(nyu.data[nyu.data.loc_type == "NLOS"]["d_m"],
               nyu.data[nyu.data.loc_type == "NLOS"]["pl_db"],
               color=config.COLORS["nyu"], marker="s", s=36, label="NYU NLOS", edgecolor="k", linewidths=0.6)
    ax.scatter(usc.data[usc.data.loc_type == "LOS"]["d_m"],
               usc.data[usc.data.loc_type == "LOS"]["pl_db"],
               color=config.COLORS["usc"], marker="o", s=36, label="USC LOS", edgecolor="k", linewidths=0.6)
    ax.scatter(usc.data[usc.data.loc_type == "NLOS"]["d_m"],
               usc.data[usc.data.loc_type == "NLOS"]["pl_db"],
               color=config.COLORS["usc"], marker="s", s=36, label="USC NLOS", edgecolor="k", linewidths=0.6)

    # Fits (pooled dashed, per-inst solid)
    def _line(fit, color, ls, label):
        y = fit.fspl_1m_db + 10.0 * fit.ple * np.log10(d_grid)
        ax.plot(d_grid, y, color=color, linestyle=ls, linewidth=1.8,
                label=f"{label}: n={fit.ple:.2f}, σ={fit.sigma_sf:.2f} dB")

    _line(nyu.fit_los,  config.COLORS["nyu"], "-", "NYU LOS fit")
    _line(nyu.fit_nlos, config.COLORS["nyu"], "--", "NYU NLOS fit")
    _line(usc.fit_los,  config.COLORS["usc"], "-", "USC LOS fit")
    _line(usc.fit_nlos, config.COLORS["usc"], "--", "USC NLOS fit")
    _line(pooled.fit_los,  config.COLORS["pooled"], "-", "Pooled LOS fit")
    _line(pooled.fit_nlos, config.COLORS["pooled"], "--", "Pooled NLOS fit")

    ax.set_xscale("log")
    ax.set_xlim(1, 500)
    ax.set_xlabel("TX-RX Separation $d$ (m)")
    ax.set_ylabel("Path Loss (dB)")
    ax.set_title(title)
    ax.legend(loc="upper left", fontsize=8.5, ncol=2, framealpha=0.9)


class _Group:
    def __init__(self, data, freq_ghz):
        self.data = data.dropna(subset=["pl_db", "d_m"]).reset_index(drop=True)
        self.freq_ghz = freq_ghz
        los = self.data[self.data.loc_type == "LOS"]
        nlos = self.data[self.data.loc_type == "NLOS"]
        self.fit_los = ci_fit(los["d_m"].to_numpy(),
                              los["pl_db"].to_numpy(), freq_ghz=freq_ghz)
        self.fit_nlos = ci_fit(nlos["d_m"].to_numpy(),
                               nlos["pl_db"].to_numpy(), freq_ghz=freq_ghz)


def render() -> dict:
    apply_style()
    df = load_point_data(variants=["N1", "U1"])

    stats: dict = {}
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.5))

    # Sub-THz
    nyu_sub = _Group(df[(df.institution == "NYU") & (df.band == "subTHz")], 142.0)
    usc_sub = _Group(df[(df.institution == "USC") & (df.band == "subTHz")], 145.5)
    pool_sub = _Group(df[df.band == "subTHz"], 143.75)
    _plot_band(axes[0], "subTHz", 143.75, nyu_sub, usc_sub, pool_sub,
               "Sub-THz (142/145.5 GHz)")

    # FR1C 6.75 GHz
    nyu_7 = _Group(df[(df.institution == "NYU") & (df.band == "FR1C")], 6.75)
    usc_7 = _Group(df[(df.institution == "USC") & (df.band == "FR1C")], 6.75)
    pool_7 = _Group(df[df.band == "FR1C"], 6.75)
    _plot_band(axes[1], "FR1C", 6.75, nyu_7, usc_7, pool_7, "FR1(C) 6.75 GHz")

    fig.suptitle("Fig. 5 — Close-In PL scatter and fits (pooled NYU + USC)",
                 fontsize=14, y=1.02)
    fig.tight_layout()
    save(fig, "fig05_ci_pl_scatter")

    for band_name, triple in (("subTHz", (nyu_sub, usc_sub, pool_sub)),
                              ("FR1C",   (nyu_7,   usc_7,   pool_7))):
        for label, grp in zip(("NYU", "USC", "Pooled"), triple):
            for loc in ("LOS", "NLOS"):
                fit = getattr(grp, f"fit_{loc.lower()}")
                stats[f"{band_name}_{label}_{loc}"] = {
                    "PLE": fit.ple, "sigma_SF_dB": fit.sigma_sf,
                    "PLE_CFI_width": fit.cfi_width,
                    "PLE_CFI_lo": fit.ple_lo, "PLE_CFI_hi": fit.ple_hi,
                }
    return stats
