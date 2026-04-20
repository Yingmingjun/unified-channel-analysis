"""Fig. 4 - Bland-Altman for Omni ASA and ASD (NYU-method vs USC-method).

Mirrors the AS half of Plot_BlandAltman_PL_DS_AS.m: one axis per figure,
N3 (NYU data) blue circles plus U3 (USC data) orange squares. NYU method
= 10 dB PAS threshold with lobe expansion (``asa_nyu_10`` column); USC
method = no spatial threshold (``asa_usc``). Diff convention: USC - NYU
(B - A).

Four output figures:
    BA_ASA       : sub-THz ASA (53 dots)
    BA_ASD       : sub-THz ASD (53 dots)
    BA_ASA7      : 6.75 GHz ASA (35 dots)
    BA_ASD7      : 6.75 GHz ASD (35 dots)

Data source: ``load_paper_ba_source`` in ``channel_analysis.io`` -- the
same authoritative xlsx tables the paper's BA script consumed.
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..bland_altman import bland_altman
from ..io import load_paper_ba_source
from ._common import apply_style, save


def _render_one(stem, title, band, metric, unit="deg"):
    df = load_paper_ba_source()
    nyu_col = f"{metric}_nyu_10"
    usc_col = f"{metric}_usc"
    sub_nyu = df[(df.institution == "NYU") & (df.band == band)]
    sub_usc = df[(df.institution == "USC") & (df.band == band)]

    a_nyu = sub_nyu[nyu_col].to_numpy()
    b_nyu = sub_nyu[usc_col].to_numpy()
    a_usc = sub_usc[nyu_col].to_numpy()
    b_usc = sub_usc[usc_col].to_numpy()

    # Drop non-positive / non-finite (matches BA_AS_Merged.m filter).
    m_n = np.isfinite(a_nyu) & np.isfinite(b_nyu) & (a_nyu > 0) & (b_nyu > 0)
    m_u = np.isfinite(a_usc) & np.isfinite(b_usc) & (a_usc > 0) & (b_usc > 0)
    a_nyu, b_nyu = a_nyu[m_n], b_nyu[m_n]
    a_usc, b_usc = a_usc[m_u], b_usc[m_u]

    res_n3 = bland_altman(b_nyu, a_nyu)
    res_u3 = bland_altman(b_usc, a_usc)
    diff_n3 = b_nyu - a_nyu;  mean_n3 = 0.5 * (a_nyu + b_nyu)
    diff_u3 = b_usc - a_usc;  mean_u3 = 0.5 * (a_usc + b_usc)

    fig, ax = plt.subplots(figsize=(12, 6))
    ax.scatter(mean_n3, diff_n3, s=120, marker="o",
               facecolor=config.COLORS["nyu_face"],
               edgecolor=config.COLORS["nyu"], linewidths=1.8,
               label=(f"N3 (NYU data, n(NYU)={res_n3.n}): "
                      f"bias={res_n3.bias:+.2f} {unit}, "
                      f"1.96 SD={1.96*res_n3.sd:.2f}"))
    ax.scatter(mean_u3, diff_u3, s=120, marker="s",
               facecolor=config.COLORS["usc_face"],
               edgecolor=config.COLORS["usc"], linewidths=1.8,
               label=(f"U3 (USC data, n(USC)={res_u3.n}): "
                      f"bias={res_u3.bias:+.2f} {unit}, "
                      f"1.96 SD={1.96*res_u3.sd:.2f}"))

    for res, color, tag, ha in (
        (res_n3, config.COLORS["nyu"], "N3", "left"),
        (res_u3, config.COLORS["usc"], "U3", "right"),
    ):
        ax.axhline(res.bias, color=color, linewidth=2.0, linestyle="-")
        ax.axhline(res.loa_high, color=color, linewidth=1.6, linestyle="--")
        ax.axhline(res.loa_low,  color=color, linewidth=1.6, linestyle="--")
        x_text = 0.01 if ha == "left" else 0.99
        ax.text(x_text, res.loa_high, f" +1.96 SD ({tag}) ",
                transform=ax.get_yaxis_transform(),
                color=color, ha=ha, va="bottom", fontsize=10)
        ax.text(x_text, res.loa_low,  f" -1.96 SD ({tag}) ",
                transform=ax.get_yaxis_transform(),
                color=color, ha=ha, va="top", fontsize=10)

    ax.axhline(0, color="0.5", linewidth=0.8, linestyle=":")
    ax.set_xlabel(f"Mean of {metric.upper()} (NYU & USC methods) [{unit}]")
    ax.set_ylabel(f"USC method - NYU method [{unit}]")
    ax.set_title(title)
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.18),
              ncol=1, fontsize=10, frameon=True)

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
                                    "subTHz", "asa", "deg")
    stats["BA_ASD"]  = _render_one("fig04_BA_ASD",  "Bland-Altman: Omni ASD (sub-THz)",
                                    "subTHz", "asd", "deg")
    stats["BA_ASA7"] = _render_one("fig04_BA_ASA7", "Bland-Altman: Omni ASA (6.75 GHz)",
                                    "FR1C",   "asa", "deg")
    stats["BA_ASD7"] = _render_one("fig04_BA_ASD7", "Bland-Altman: Omni ASD (6.75 GHz)",
                                    "FR1C",   "asd", "deg")
    return stats
