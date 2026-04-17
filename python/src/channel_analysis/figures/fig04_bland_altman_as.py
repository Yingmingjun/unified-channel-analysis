"""Fig. 4 — Bland-Altman for Omni ASA and ASD (NYU-method vs USC-method).

Mirrors ``BA_AS_Merged.m``: one axis per figure, N3 (NYU data) blue circles
plus U3 (USC data) orange squares. NYU method = 10 dB PAS threshold with
lobe expansion (``asa_nyu_10`` column in canonical schema); USC method =
no spatial threshold (``asa_usc``). Diff convention: USC - NYU (B − A).

Four output figures:
    BA_ASA       : sub-THz ASA (53 dots)
    BA_ASD       : sub-THz ASD (53 dots)
    BA_ASA7      : 6.75 GHz ASA (35 dots)
    BA_ASD7      : 6.75 GHz ASD (35 dots)
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..bland_altman import bland_altman
from ..io import load_point_data
from ._common import apply_style, save


def _render_one(stem, title, band, metric, unit="°"):
    df = load_point_data()
    nyu_col = f"{metric}_nyu_10"
    usc_col = f"{metric}_usc"
    sub_nyu = df[(df.institution == "NYU") & (df.band == band)]
    sub_usc = df[(df.institution == "USC") & (df.band == band)]

    a_nyu = sub_nyu[nyu_col].to_numpy()
    b_nyu = sub_nyu[usc_col].to_numpy()
    a_usc = sub_usc[nyu_col].to_numpy()
    b_usc = sub_usc[usc_col].to_numpy()

    # Drop non-positive / non-finite (matches MATLAB script)
    m_n = np.isfinite(a_nyu) & np.isfinite(b_nyu) & (a_nyu > 0) & (b_nyu > 0)
    m_u = np.isfinite(a_usc) & np.isfinite(b_usc) & (a_usc > 0) & (b_usc > 0)
    a_nyu, b_nyu = a_nyu[m_n], b_nyu[m_n]
    a_usc, b_usc = a_usc[m_u], b_usc[m_u]

    diff_n3 = b_nyu - a_nyu; mean_n3 = 0.5 * (a_nyu + b_nyu)
    diff_u3 = b_usc - a_usc; mean_u3 = 0.5 * (a_usc + b_usc)
    res_n3 = bland_altman(b_nyu, a_nyu)
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

    for res, color in ((res_n3, config.COLORS["nyu"]), (res_u3, config.COLORS["usc"])):
        ax.axhline(res.bias, color=color, linewidth=2.0)
        ax.axhline(res.loa_low, color=color, linewidth=1.6, linestyle="--")
        ax.axhline(res.loa_high, color=color, linewidth=1.6, linestyle="--")
    ax.axhline(0, color="0.5", linewidth=0.8, linestyle=":")

    ax.set_xlabel(f"Mean of {metric.upper()} (NYU & USC methods) [{unit}]")
    ax.set_ylabel(f"USC method – NYU method [{unit}]")
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
        "N3": {"bias": res_n3.bias, "sd": res_n3.sd, "n": res_n3.n},
        "U3": {"bias": res_u3.bias, "sd": res_u3.sd, "n": res_u3.n},
    }


def render() -> dict:
    apply_style()
    stats: dict = {}
    stats["BA_ASA"]  = _render_one("fig04_BA_ASA",  "Bland-Altman: Omni ASA (sub-THz)",
                                    "subTHz", "asa", "°")
    stats["BA_ASD"]  = _render_one("fig04_BA_ASD",  "Bland-Altman: Omni ASD (sub-THz)",
                                    "subTHz", "asd", "°")
    stats["BA_ASA7"] = _render_one("fig04_BA_ASA7", "Bland-Altman: Omni ASA (6.75 GHz)",
                                    "FR1C",   "asa", "°")
    stats["BA_ASD7"] = _render_one("fig04_BA_ASD7", "Bland-Altman: Omni ASD (6.75 GHz)",
                                    "FR1C",   "asd", "°")
    return stats
