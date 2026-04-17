"""Fig. 4 — Bland-Altman plots for ASA and ASD, sub-THz and 6.75 GHz.

Compare the NYU-method result (NYU pipeline: 10-dB SLT, lobe expansion,
3GPP circular-std-dev) against the USC-method result (no spatial threshold,
Fleury equivalent converted to 3GPP). In the N3/U3 xlsx tables we use the
``nyu_thr`` vs. ``usc_thr`` columns for each dataset.
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from .. import config
from ..bland_altman import bland_altman
from ..io import load_point_data
from ._common import apply_style, save


def _pair(df, institution, band, metric, v_a, v_b):
    sub = df[(df.institution == institution) & (df.band == band)]
    a = sub[sub.variant == v_a].set_index(["tx", "rx"])[metric]
    b = sub[sub.variant == v_b].set_index(["tx", "rx"])[metric]
    common = a.index.intersection(b.index)
    return a.loc[common].to_numpy(), b.loc[common].to_numpy()


def _panel(ax, a, b, title, color):
    res = bland_altman(a, b)
    ax.scatter(res.mean, res.diff, s=45, color=color, edgecolor="k",
               linewidths=0.8, alpha=0.85)
    ax.axhline(res.bias, color="k", linewidth=1.3)
    ax.axhline(res.loa_low, color="k", linestyle="--", linewidth=1.0)
    ax.axhline(res.loa_high, color="k", linestyle="--", linewidth=1.0)
    ax.axhline(0.0, color="0.5", linestyle=":", linewidth=0.8)
    ax.set_title(title)
    ax.set_xlabel("Mean (°)")
    ax.set_ylabel("Difference (°)")
    ax.text(0.97, 0.04,
            f"bias = {res.bias:+.2f}\nSD = {res.sd:.2f}\nn = {res.n}",
            transform=ax.transAxes, ha="right", va="bottom",
            fontsize=9, bbox=dict(facecolor="white", edgecolor="0.5", alpha=0.9))
    return {"bias": res.bias, "sd": res.sd, "n": res.n}


def render() -> dict:
    apply_style()
    df = load_point_data(variants=["N3", "U3"])
    stats: dict = {}

    # Sub-THz
    fig, axes = plt.subplots(2, 2, figsize=(12, 9))
    panels = [
        ((0, 0), "NYU", "subTHz", "omni_asa_d", "N3_nyu_thr", "N3_usc_thr", "NYU data — ASA, sub-THz", config.COLORS["nyu"]),
        ((0, 1), "NYU", "subTHz", "omni_asd_d", "N3_nyu_thr", "N3_usc_thr", "NYU data — ASD, sub-THz", config.COLORS["nyu"]),
        ((1, 0), "USC", "subTHz", "omni_asa_d", "U3_nyu_thr", "U3_usc_thr", "USC data — ASA, sub-THz", config.COLORS["usc"]),
        ((1, 1), "USC", "subTHz", "omni_asd_d", "U3_nyu_thr", "U3_usc_thr", "USC data — ASD, sub-THz", config.COLORS["usc"]),
    ]
    for (r, c), inst, band, metric, va, vb, title, color in panels:
        a, b = _pair(df, inst, band, metric, va, vb)
        stats[f"{inst}_{band}_{metric}"] = _panel(axes[r, c], a, b, title, color)
    fig.suptitle("Fig. 4 — Bland-Altman: ASA & ASD cross-processing (sub-THz)", fontsize=14, y=1.00)
    fig.tight_layout()
    save(fig, "fig04_bland_altman_as")

    # 6.75 GHz
    fig7, axes7 = plt.subplots(2, 2, figsize=(12, 9))
    panels7 = [
        ((0, 0), "NYU", "FR1C", "omni_asa_d", "N3_nyu_thr", "N3_usc_thr", "NYU data — ASA, 6.75 GHz", config.COLORS["nyu"]),
        ((0, 1), "NYU", "FR1C", "omni_asd_d", "N3_nyu_thr", "N3_usc_thr", "NYU data — ASD, 6.75 GHz", config.COLORS["nyu"]),
        ((1, 0), "USC", "FR1C", "omni_asa_d", "U3_nyu_thr", "U3_usc_thr", "USC data — ASA, 6.75 GHz", config.COLORS["usc"]),
        ((1, 1), "USC", "FR1C", "omni_asd_d", "U3_nyu_thr", "U3_usc_thr", "USC data — ASD, 6.75 GHz", config.COLORS["usc"]),
    ]
    for (r, c), inst, band, metric, va, vb, title, color in panels7:
        a, b = _pair(df, inst, band, metric, va, vb)
        stats[f"{inst}_{band}_{metric}"] = _panel(axes7[r, c], a, b, title, color)
    fig7.suptitle("Fig. 4 — Bland-Altman: ASA & ASD cross-processing (6.75 GHz)", fontsize=14, y=1.00)
    fig7.tight_layout()
    save(fig7, "fig04_bland_altman_as_fr1c")
    return stats
