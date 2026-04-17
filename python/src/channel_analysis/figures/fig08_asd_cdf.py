"""Fig. 8 — Omni RMS ASD CDF (pooled) with DKW 95 % bands."""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from ..io import load_point_data
from ._common import apply_style, save
from .fig06_ds_cdf import _cdf_panel


def render() -> dict:
    apply_style()
    df = load_point_data(variants=["N1", "U1"])
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.0))
    stats: dict = {}
    for col, band, label in [(0, "subTHz", "Sub-THz (142/145.5 GHz)"),
                             (1, "FR1C", "FR1(C) 6.75 GHz")]:
        srs = {
            "NYU":    df[(df.band == band) & (df.institution == "NYU")]["omni_asd_d"].to_numpy(),
            "USC":    df[(df.band == band) & (df.institution == "USC")]["omni_asd_d"].to_numpy(),
            "Pooled": df[df.band == band]["omni_asd_d"].to_numpy(),
        }
        _cdf_panel(axes[col], srs, "Omni RMS ASD (°)", label)
        stats[band] = {k: int(np.sum(np.isfinite(v) & (v > 0))) for k, v in srs.items()}
    fig.suptitle("Fig. 8 — Omni RMS ASD CDF (pooled NYU + USC)",
                 fontsize=14, y=1.02)
    fig.tight_layout()
    save(fig, "fig08_asd_cdf")
    return stats
