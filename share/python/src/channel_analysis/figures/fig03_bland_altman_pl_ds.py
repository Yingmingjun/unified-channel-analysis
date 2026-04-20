"""Fig. 3 — Bland-Altman for PL and Omni DS, per band.

Paper layout (from BA_AS_Merged.m / bland_altman_analysis.m): ONE axis per
figure with N3 (NYU data, blue circles) and U3 (USC data, orange squares)
overlaid. Difference convention:
    N3 : diff = PL_USC_method - PL_NYU_method     (re-processed − original)
    U3 : diff = PL_NYU_method - PL_USC_method     (re-processed − original)

Four figures written:
    BA_PL        : sub-THz PL   (27 NYU + 26 USC = 53 dots)
    BA_DS        : sub-THz DS   (53 dots)
    BA_PL7       : 6.75 GHz PL  (18 NYU + 17 USC = 35 dots)
    BA_DS7       : 6.75 GHz DS  (35 dots)
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..bland_altman import bland_altman
from ..io import load_point_data
from ._common import apply_style, save


def _render_one(stem, title, band, metric_a, metric_b, unit, xlabel_metric):
    df = load_point_data()
    sub_nyu = df[(df.institution == "NYU") & (df.band == band)]
    sub_usc = df[(df.institution == "USC") & (df.band == band)]

    a_nyu = sub_nyu[metric_a].to_numpy()
    b_nyu = sub_nyu[metric_b].to_numpy()
    a_usc = sub_usc[metric_a].to_numpy()
    b_usc = sub_usc[metric_b].to_numpy()

    # Paper convention: N3 = B - A (USC_method - NYU_method); U3 = B - A
    diff_n3 = b_nyu - a_nyu
    mean_n3 = 0.5 * (a_nyu + b_nyu)
    diff_u3 = b_usc - a_usc
    mean_u3 = 0.5 * (a_usc + b_usc)

    res_n3 = bland_altman(b_nyu, a_nyu)   # stores bias/SD/loa
    res_u3 = bland_altman(b_usc, a_usc)

    fig, ax = plt.subplots(figsize=(12, 6))
    ax.scatter(mean_n3, diff_n3, s=120, marker="o",
               facecolor=config.COLORS["nyu_face"],
               edgecolor=config.COLORS["nyu"], linewidths=1.8,
               label=f"N3: NYU data (n={len(diff_n3)})")
    ax.scatter(mean_u3, diff_u3, s=120, marker="s",
               facecolor=config.COLORS["usc_face"],
               edgecolor=config.COLORS["usc"], linewidths=1.8,
               label=f"U3: USC data (n={len(diff_u3)})")

    # Bias + LoA lines, one set per side
    for res, color, tag in ((res_n3, config.COLORS["nyu"], "N3"),
                            (res_u3, config.COLORS["usc"], "U3")):
        ax.axhline(res.bias, color=color, linewidth=2.0, linestyle="-")
        ax.axhline(res.loa_low, color=color, linewidth=1.6, linestyle="--")
        ax.axhline(res.loa_high, color=color, linewidth=1.6, linestyle="--")

    ax.axhline(0, color="0.5", linewidth=0.8, linestyle=":")
    ax.set_xlabel(f"Mean of paired {xlabel_metric} [{unit}]")
    ax.set_ylabel(f"Difference (USC method – NYU method) [{unit}]")
    ax.set_title(title)

    ax.text(0.02, 0.98,
            f"N3 bias = {res_n3.bias:+.2f} {unit}\nSD = {res_n3.sd:.2f}",
            transform=ax.transAxes, color=config.COLORS["nyu"],
            ha="left", va="top", fontsize=11, fontweight="bold",
            bbox=dict(facecolor="white", edgecolor=config.COLORS["nyu"], alpha=0.9))
    ax.text(0.98, 0.98,
            f"U3 bias = {res_u3.bias:+.2f} {unit}\nSD = {res_u3.sd:.2f}",
            transform=ax.transAxes, color=config.COLORS["usc"],
            ha="right", va="top", fontsize=11, fontweight="bold",
            bbox=dict(facecolor="white", edgecolor=config.COLORS["usc"], alpha=0.9))
    ax.legend(loc="lower right", fontsize=10)
    fig.tight_layout()
    save(fig, stem)
    return {
        "N3": {"bias": res_n3.bias, "sd": res_n3.sd, "n": res_n3.n,
               "loa_low": res_n3.loa_low, "loa_high": res_n3.loa_high},
        "U3": {"bias": res_u3.bias, "sd": res_u3.sd, "n": res_u3.n,
               "loa_low": res_u3.loa_low, "loa_high": res_u3.loa_high},
    }


def render() -> dict:
    apply_style()
    stats: dict = {}
    stats["BA_PL"]  = _render_one("fig03_BA_PL",  "Bland-Altman: Omni PL (sub-THz)",
                                   "subTHz", "pl_nyu_sum", "pl_usc_pdm",
                                   "dB", "PL")
    stats["BA_DS"]  = _render_one("fig03_BA_DS",  "Bland-Altman: Omni DS (sub-THz)",
                                   "subTHz", "ds_nyu_method", "ds_usc_method",
                                   "ns", "DS")
    stats["BA_PL7"] = _render_one("fig03_BA_PL7", "Bland-Altman: Omni PL (6.75 GHz)",
                                   "FR1C",   "pl_nyu_sum", "pl_usc_pdm",
                                   "dB", "PL")
    stats["BA_DS7"] = _render_one("fig03_BA_DS7", "Bland-Altman: Omni DS (6.75 GHz)",
                                   "FR1C",   "ds_nyu_method", "ds_usc_method",
                                   "ns", "DS")
    return stats
