"""Fig. 6 — Omni RMS Delay Spread CDF (LOS | NLOS, per band).

Mirrors ``cdf_ci_pl_analysis_DS_ref.m`` → ``plot_cdf_group``. Each output
figure has two subplots (LOS | NLOS) with three curves each (NYU, USC,
Pooled) plus DKW 95 % bands shaded at alpha 0.12.

Two output figures:
    fig06_OmniDS_merged   (sub-THz)
    fig06_OmniDS_merged7  (6.75 GHz)
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..io import load_point_data
from ..stats import dkw_band, ecdf
from ._common import apply_style, save


LINE = {
    "NYU":    dict(color=config.COLORS["nyu"],    ls="-",  lw=1.8),
    "USC":    dict(color=config.COLORS["usc"],    ls="--", lw=1.8),
    "Pooled": dict(color=config.COLORS["gray"],   ls="-",  lw=2.2),
}


def _ecdf_with_dkw(vals):
    vals = np.asarray(vals, dtype=float)
    vals = vals[np.isfinite(vals) & (vals > 0)]
    xs, fs = ecdf(vals)
    eps = dkw_band(vals.size)
    flo = np.clip(fs - eps, 0, 1)
    fhi = np.clip(fs + eps, 0, 1)
    return xs, fs, flo, fhi, vals.size


def _panel(ax, band_df, metric_col, title, xlabel):
    nyu_vals    = band_df[band_df.institution == "NYU"][metric_col].to_numpy()
    usc_vals    = band_df[band_df.institution == "USC"][metric_col].to_numpy()
    pooled_vals = band_df[metric_col].to_numpy()

    for label, vals in (("NYU", nyu_vals), ("USC", usc_vals),
                        ("Pooled", pooled_vals)):
        xs, fs, flo, fhi, n = _ecdf_with_dkw(vals)
        if n == 0:
            continue
        st = LINE[label]
        # Extend ECDF to (xs, 1) for proper step plotting
        xs_plot = np.r_[xs, xs[-1]]
        fs_plot = np.r_[fs, fs[-1]]
        ax.step(xs_plot, fs_plot, where="post",
                label=f"{label} (n={n})", **st)
        ax.fill_between(xs, flo, fhi, step="post",
                        color=st["color"], alpha=0.12, linewidth=0)
    ax.set_xlabel(xlabel)
    ax.set_ylabel("CDF")
    ax.set_ylim(0, 1)
    ax.set_title(title)
    ax.legend(loc="lower right", fontsize=9)


def _render_band(band, band_label, stem, metric_col="omni_ds_ns",
                 unit="ns", metric_label="Omni RMS DS"):
    df = load_point_data()
    df = df[df.band == band]

    fig, (ax_los, ax_nlos) = plt.subplots(1, 2, figsize=(13, 5))
    _panel(ax_los,
           df[df.loc_type == "LOS"],
           metric_col,
           f"{metric_label} CDF (LOS) — {band_label}",
           f"{metric_label} ({unit})")
    _panel(ax_nlos,
           df[df.loc_type == "NLOS"],
           metric_col,
           f"{metric_label} CDF (NLOS) — {band_label}",
           f"{metric_label} ({unit})")
    fig.tight_layout()
    save(fig, stem)
    return {
        "n_LOS": int(df[df.loc_type == "LOS"][metric_col].notna().sum()),
        "n_NLOS": int(df[df.loc_type == "NLOS"][metric_col].notna().sum()),
    }


def render() -> dict:
    apply_style()
    stats = {
        "subTHz": _render_band("subTHz", "Sub-THz (142 / 145.5 GHz)",
                                "fig06_OmniDS_merged"),
        "FR1C":   _render_band("FR1C", "FR1(C) 6.75 GHz",
                                "fig06_OmniDS_merged7"),
    }
    return stats
