"""Fig. 6 — Omni RMS delay-spread CDFs (pooled) with DKW 95 % bands."""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..io import load_point_data
from ..stats import dkw_band, ecdf
from ._common import apply_style, save


def _cdf_panel(ax, series_dict: dict[str, np.ndarray], xlabel: str, title: str):
    styles = {
        "NYU":   dict(color=config.COLORS["nyu"],    ls="-",  lw=2.0),
        "USC":   dict(color=config.COLORS["usc"],    ls="--", lw=2.0),
        "Pooled":dict(color=config.COLORS["pooled"], ls="-",  lw=2.4),
    }
    for label, data in series_dict.items():
        data = np.asarray(data, dtype=float)
        data = data[np.isfinite(data) & (data > 0)]
        if data.size == 0:
            continue
        xs, fs = ecdf(data)
        eps = dkw_band(data.size)
        ax.step(xs, fs, where="post", label=f"{label} (n={data.size})", **styles[label])
        ax.fill_between(xs, np.clip(fs - eps, 0, 1), np.clip(fs + eps, 0, 1),
                        step="post", alpha=0.12, color=styles[label]["color"],
                        linewidth=0)
    ax.set_xlabel(xlabel)
    ax.set_ylabel("CDF")
    ax.set_ylim(0, 1)
    ax.set_title(title)
    ax.legend(loc="lower right", fontsize=10)


def render() -> dict:
    apply_style()
    df = load_point_data(variants=["N1", "U1"])

    fig, axes = plt.subplots(1, 2, figsize=(13, 5.0))

    def _series(band: str, loc: str):
        sub = df[(df.band == band) & (df.loc_type == loc)]
        return {
            "NYU":    sub[sub.institution == "NYU"]["omni_ds_ns"].to_numpy(),
            "USC":    sub[sub.institution == "USC"]["omni_ds_ns"].to_numpy(),
            "Pooled": sub["omni_ds_ns"].to_numpy(),
        }

    # Build combined LOS+NLOS CDF per band (paper shows both stacked; we do
    # one CDF per band with LOS/NLOS colored via line style)
    stats: dict = {}
    for col, band, label in [(0, "subTHz", "Sub-THz (142/145.5 GHz)"),
                             (1, "FR1C", "FR1(C) 6.75 GHz")]:
        # Combine LOS+NLOS for the main omni-DS CDF
        srs = {
            "NYU":    df[(df.band == band) & (df.institution == "NYU")]["omni_ds_ns"].to_numpy(),
            "USC":    df[(df.band == band) & (df.institution == "USC")]["omni_ds_ns"].to_numpy(),
            "Pooled": df[df.band == band]["omni_ds_ns"].to_numpy(),
        }
        _cdf_panel(axes[col], srs, "Omni RMS DS (ns)", label)
        stats[band] = {k: {"n": int(np.sum(np.isfinite(v) & (v > 0))),
                            "median_ns": float(np.nanmedian(v[np.isfinite(v) & (v > 0)])) if np.any(np.isfinite(v) & (v > 0)) else float("nan")}
                        for k, v in srs.items()}

    fig.suptitle("Fig. 6 — Omni RMS Delay Spread CDF (pooled NYU + USC)",
                 fontsize=14, y=1.02)
    fig.tight_layout()
    save(fig, "fig06_ds_cdf")
    return stats
