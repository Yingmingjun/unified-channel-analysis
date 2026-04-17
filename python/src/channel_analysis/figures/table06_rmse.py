"""Table 6 — Cross-processing RMSE for PL, DS, ASA, ASD across threshold choices.

For each (dataset × metric × threshold variant), compute RMSE vs. the *original*
partner-institution values (N1 or U1):
    USC data (U3 table): U3_nyu_thr vs U1  AND  U3_usc_thr vs U1.
    NYU data (N3 table): N3_usc_thr vs N1  AND  N3_nyu_thr vs N1.

Matches ``calculate_AS_RMSE.m`` and ``verify_crossproc_stats.m``.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd

from .. import config
from ..io import load_point_data
from ._common import apply_style


METRICS = [("pl_db", "PL [dB]"), ("omni_ds_ns", "DS [ns]"),
           ("omni_asa_d", "ASA [deg]"), ("omni_asd_d", "ASD [deg]")]


def _rmse(a, b):
    a = np.asarray(a, dtype=float); b = np.asarray(b, dtype=float)
    m = np.isfinite(a) & np.isfinite(b)
    if m.sum() == 0:
        return float("nan")
    return float(np.sqrt(np.mean((a[m] - b[m]) ** 2)))


def _institution_rmse(df, institution, band, orig_variant, cross_variants):
    """Compute RMSE of each cross-variant against the original at common TX-RX keys.

    Drops entries where |cross - orig| exceeds 100× the IQR of the column
    as a robust guard against source-data typos (see docs/issues_log.md —
    one row in 142_UMi_N3.xlsx has an ASA value of 714° where 7.14° was
    intended; we filter such anomalies rather than mutate the input file).
    """
    sub = df[(df.institution == institution) & (df.band == band)]
    orig = sub[sub.variant == orig_variant].set_index(["tx", "rx"])
    out = {}
    for v in cross_variants:
        cross = sub[sub.variant == v].set_index(["tx", "rx"])
        common = orig.index.intersection(cross.index)
        for col, label in METRICS:
            a = orig.loc[common, col].values
            b = cross.loc[common, col].values
            mask = np.isfinite(a) & np.isfinite(b)
            if mask.any():
                diff = np.abs(a - b)
                median_valid = np.nanmedian(diff[mask]) if mask.any() else 0.0
                # Guard against source-data typos: drop outliers that exceed
                # median by more than 50x (typical spread is < 5x median).
                outlier = (diff > max(median_valid * 50.0, 100.0))
                keep = mask & ~outlier
                out[f"{v}:{label}"] = _rmse(a[keep], b[keep])
            else:
                out[f"{v}:{label}"] = float("nan")
    return out


def render() -> dict:
    apply_style()
    df = load_point_data(variants=["N1", "U1", "N3", "U3"])

    rows = []
    for band, label in [("subTHz", "Sub-THz"), ("FR1C", "6.75 GHz")]:
        # USC data vs U1 original
        usc = _institution_rmse(df, "USC", band, "U1",
                                ["U3_nyu_thr", "U3_usc_thr"])
        # NYU data vs N1 original
        nyu = _institution_rmse(df, "NYU", band, "N1",
                                ["N3_nyu_thr", "N3_usc_thr"])
        for (col, mlabel) in METRICS:
            rows.append({
                "Band": label, "Metric": mlabel,
                "USC data – NYU thres": usc[f"U3_nyu_thr:{mlabel}"],
                "USC data – USC thres": usc[f"U3_usc_thr:{mlabel}"],
                "NYU data – USC thres": nyu[f"N3_usc_thr:{mlabel}"],
                "NYU data – NYU thres": nyu[f"N3_nyu_thr:{mlabel}"],
            })
    tbl = pd.DataFrame(rows)
    config.ensure_output_dirs()
    out_csv = Path(config.FIGURE_DIR) / "table06_rmse.csv"
    tbl.to_csv(out_csv, index=False)
    return {"table_csv": str(out_csv), "rows": rows}
