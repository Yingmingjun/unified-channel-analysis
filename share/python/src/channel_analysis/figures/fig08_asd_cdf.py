"""Fig. 8 — Omni ASD CDF (LOS | NLOS, per band). Mirrors fig07 structure."""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..io import load_point_data
from ._common import apply_style, save
from .fig06_ds_cdf import LINE, _ecdf_with_dkw


def _panel(ax, band_df, title, xlabel):
    nyu = band_df.loc[band_df.institution == "NYU", "asd_nyu_10"].to_numpy()
    usc = band_df.loc[band_df.institution == "USC", "asd_usc"].to_numpy()
    pooled = np.concatenate([nyu, usc])
    for label, vals in (("NYU", nyu), ("USC", usc), ("Pooled", pooled)):
        xs, fs, flo, fhi, n = _ecdf_with_dkw(vals)
        if n == 0:
            continue
        st = LINE[label]
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


def _render_band(band, band_label, stem):
    df = load_point_data()
    df = df[df.band == band]
    fig, (ax_los, ax_nlos) = plt.subplots(1, 2, figsize=(13, 5))
    _panel(ax_los,  df[df.loc_type == "LOS"],
           f"Omni ASD CDF (LOS) — {band_label}",  "Omni RMS ASD (°)")
    _panel(ax_nlos, df[df.loc_type == "NLOS"],
           f"Omni ASD CDF (NLOS) — {band_label}", "Omni RMS ASD (°)")
    fig.tight_layout()
    save(fig, stem)


def render() -> dict:
    apply_style()
    _render_band("subTHz", "Sub-THz (142 / 145.5 GHz)", "fig08_OmniASD_merged")
    _render_band("FR1C",   "FR1(C) 6.75 GHz",           "fig08_OmniASD_merged7")
    return {}
