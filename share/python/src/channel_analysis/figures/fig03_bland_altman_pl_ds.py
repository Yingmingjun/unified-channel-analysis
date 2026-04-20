"""Fig. 3 - Bland-Altman for PL and Omni DS, per band.

Paper layout (from Plot_BlandAltman_PL_DS_AS.m): ONE axis per figure with
N3 (NYU data, blue circles) and U3 (USC data, orange squares) overlaid.
Difference convention: USC method - NYU method (B - A) for BOTH sides, so
positive bias means USC reports a larger value than NYU on the same data.

Four figures written:
    BA_PL        : sub-THz PL   (27 NYU + 26 USC = 53 dots)
    BA_DS        : sub-THz DS   (53 dots)
    BA_PL7       : 6.75 GHz PL  (18 NYU + 17 USC = 35 dots)
    BA_DS7       : 6.75 GHz DS  (35 dots)

Data source: ``load_paper_ba_source`` in ``channel_analysis.io`` -- reads
the four authoritative per-location xlsx tables (``nyu_142_results.xlsx``
etc.) that the paper's BA script consumed. Produces paper-identical bias
values (N3 sub-THz +1.76 dB / 1.23, U3 sub-THz +5.84 dB / 2.01, N3
6.75 GHz +3.53 dB / 2.76, U3 6.75 GHz +6.65 dB / 4.95).
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..bland_altman import bland_altman
from ..io import load_paper_ba_source
from ._common import apply_style, save


def _render_one(stem, title, band, metric_a, metric_b, unit, xlabel_metric):
    df = load_paper_ba_source()
    sub_nyu = df[(df.institution == "NYU") & (df.band == band)]
    sub_usc = df[(df.institution == "USC") & (df.band == band)]

    a_nyu = sub_nyu[metric_a].to_numpy()
    b_nyu = sub_nyu[metric_b].to_numpy()
    a_usc = sub_usc[metric_a].to_numpy()
    b_usc = sub_usc[metric_b].to_numpy()

    # Paper convention: diff = USC_method - NYU_method (B - A).
    res_n3 = bland_altman(b_nyu, a_nyu)
    res_u3 = bland_altman(b_usc, a_usc)
    diff_n3 = b_nyu - a_nyu;  mean_n3 = 0.5 * (a_nyu + b_nyu)
    diff_u3 = b_usc - a_usc;  mean_u3 = 0.5 * (a_usc + b_usc)

    fig, ax = plt.subplots(figsize=(12, 6))
    # Legend entries carry n / bias / SD; no free text boxes to collide.
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

    # Bias lines (solid) and +/-1.96 SD lines (dashed) per side, with
    # in-axes labels ("+1.96 SD (N3)" etc.) so the LoA interpretation is
    # visible without a second legend.
    for res, color, tag, ha in (
        (res_n3, config.COLORS["nyu"], "N3", "left"),
        (res_u3, config.COLORS["usc"], "U3", "right"),
    ):
        ax.axhline(res.bias, color=color, linewidth=2.0, linestyle="-")
        ax.axhline(res.loa_high, color=color, linewidth=1.6, linestyle="--")
        ax.axhline(res.loa_low,  color=color, linewidth=1.6, linestyle="--")
        # x=0.01 for N3 (left), x=0.99 for U3 (right) in axes coords
        x_text = 0.01 if ha == "left" else 0.99
        ax.text(x_text, res.loa_high, f" +1.96 SD ({tag}) ",
                transform=ax.get_yaxis_transform(),
                color=color, ha=ha, va="bottom", fontsize=10)
        ax.text(x_text, res.loa_low,  f" -1.96 SD ({tag}) ",
                transform=ax.get_yaxis_transform(),
                color=color, ha=ha, va="top", fontsize=10)

    ax.axhline(0, color="0.5", linewidth=0.8, linestyle=":")
    ax.set_xlabel(f"Mean of paired {xlabel_metric} [{unit}]")
    ax.set_ylabel(f"Difference (USC method - NYU method) [{unit}]")
    ax.set_title(title)

    # Put legend BELOW the plot -- lots of info in the labels, and keeping
    # it outside the data area guarantees no overlap with scatter.
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.18),
              ncol=1, fontsize=10, frameon=True)

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
                                   "subTHz", "ds_nyu_sum", "ds_usc_pdm",
                                   "ns", "DS")
    stats["BA_PL7"] = _render_one("fig03_BA_PL7", "Bland-Altman: Omni PL (6.75 GHz)",
                                   "FR1C",   "pl_nyu_sum", "pl_usc_pdm",
                                   "dB", "PL")
    stats["BA_DS7"] = _render_one("fig03_BA_DS7", "Bland-Altman: Omni DS (6.75 GHz)",
                                   "FR1C",   "ds_nyu_sum", "ds_usc_pdm",
                                   "ns", "DS")
    return stats
