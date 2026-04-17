"""Fig. 3 — Bland-Altman plots for PL and omni RMS DS, sub-THz and 6.75 GHz.

NYU-data (N3 variants): compare N1 (NYU original) against the USC-pipeline-on-NYU-
data result with the NYU delay threshold (N3_nyu_thr). This mirrors Codebase A's
`bland_altman_analysis.m`.
USC-data (U3 variants): compare U1 (USC original) against U3_nyu_thr.

Subplots:
    (a) PL sub-THz          (b) DS sub-THz
    (c) PL 6.75 GHz         (d) DS 6.75 GHz

Figure is saved as ``fig03_bland_altman_pl_ds.{png,pdf}``.
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from .. import config
from ..bland_altman import bland_altman
from ..io import load_point_data
from ._common import apply_style, save


def _pair(df: pd.DataFrame, institution: str, band: str, metric: str,
          baseline_variant: str, cross_variant: str) -> tuple[np.ndarray, np.ndarray]:
    sub = df[(df.institution == institution) & (df.band == band)]
    b = sub[sub.variant == baseline_variant].set_index(["tx", "rx"])[metric]
    c = sub[sub.variant == cross_variant].set_index(["tx", "rx"])[metric]
    # Align on TX-RX keys that exist in both
    common = b.index.intersection(c.index)
    return b.loc[common].to_numpy(), c.loc[common].to_numpy()


def _ba_panel(ax, baseline: np.ndarray, cross: np.ndarray, title: str,
              unit: str, color):
    res = bland_altman(baseline, cross)
    ax.scatter(res.mean, res.diff, s=45, color=color, edgecolor="k",
               linewidths=0.8, alpha=0.85)
    ax.axhline(res.bias, color="k", linewidth=1.3)
    ax.axhline(res.loa_low, color="k", linestyle="--", linewidth=1.0)
    ax.axhline(res.loa_high, color="k", linestyle="--", linewidth=1.0)
    ax.axhline(0.0, color="0.5", linestyle=":", linewidth=0.8)
    ax.set_title(title)
    ax.set_xlabel(f"Mean ({unit})")
    ax.set_ylabel(f"Difference ({unit})")
    ax.text(0.97, 0.04,
            f"bias = {res.bias:+.2f}\nSD = {res.sd:.2f}\nn = {res.n}",
            transform=ax.transAxes, ha="right", va="bottom",
            fontsize=9, bbox=dict(facecolor="white", edgecolor="0.5", alpha=0.9))
    return {"bias": res.bias, "sd": res.sd, "n": res.n,
            "loa_low": res.loa_low, "loa_high": res.loa_high}


def render() -> dict:
    apply_style()
    df = load_point_data(variants=["N1", "U1", "N3", "U3"])

    fig, axes = plt.subplots(2, 2, figsize=(12, 9))
    stats: dict = {}

    panels = [
        # (row,col),        inst, band,     metric,     baseline, cross,         title,            unit, color
        ((0, 0), "NYU", "subTHz", "pl_db",      "N1", "N3_nyu_thr", "NYU data — PL, sub-THz",       "dB", config.COLORS["nyu"]),
        ((0, 1), "NYU", "subTHz", "omni_ds_ns", "N1", "N3_nyu_thr", "NYU data — Omni DS, sub-THz",  "ns", config.COLORS["nyu"]),
        ((1, 0), "USC", "subTHz", "pl_db",      "U1", "U3_nyu_thr", "USC data — PL, sub-THz",       "dB", config.COLORS["usc"]),
        ((1, 1), "USC", "subTHz", "omni_ds_ns", "U1", "U3_nyu_thr", "USC data — Omni DS, sub-THz",  "ns", config.COLORS["usc"]),
    ]

    for (r, c), inst, band, metric, base_v, cross_v, title, unit, color in panels:
        a, b = _pair(df, inst, band, metric, base_v, cross_v)
        stats[f"{inst}_{band}_{metric}"] = _ba_panel(axes[r, c], a, b, title, unit, color)

    fig.suptitle("Fig. 3 — Bland-Altman: PL & Omni DS cross-processing (sub-THz)",
                 fontsize=14, y=1.00)
    fig.tight_layout()
    save(fig, "fig03_bland_altman_pl_ds")

    # 6.75 GHz variant
    fig7, axes7 = plt.subplots(2, 2, figsize=(12, 9))
    panels7 = [
        ((0, 0), "NYU", "FR1C", "pl_db",      "N1", "N3_nyu_thr", "NYU data — PL, 6.75 GHz",      "dB", config.COLORS["nyu"]),
        ((0, 1), "NYU", "FR1C", "omni_ds_ns", "N1", "N3_nyu_thr", "NYU data — Omni DS, 6.75 GHz", "ns", config.COLORS["nyu"]),
        ((1, 0), "USC", "FR1C", "pl_db",      "U1", "U3_nyu_thr", "USC data — PL, 6.75 GHz",      "dB", config.COLORS["usc"]),
        ((1, 1), "USC", "FR1C", "omni_ds_ns", "U1", "U3_nyu_thr", "USC data — Omni DS, 6.75 GHz", "ns", config.COLORS["usc"]),
    ]
    for (r, c), inst, band, metric, base_v, cross_v, title, unit, color in panels7:
        a, b = _pair(df, inst, band, metric, base_v, cross_v)
        stats[f"{inst}_{band}_{metric}"] = _ba_panel(axes7[r, c], a, b, title, unit, color)

    fig7.suptitle("Fig. 3 — Bland-Altman: PL & Omni DS cross-processing (6.75 GHz)",
                  fontsize=14, y=1.00)
    fig7.tight_layout()
    save(fig7, "fig03_bland_altman_pl_ds_fr1c")
    return stats
