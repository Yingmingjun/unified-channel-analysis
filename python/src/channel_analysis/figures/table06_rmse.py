"""Table 6 — Cross-processing RMSE (paper Table VI).

For each (metric × band) the paper reports RMSE between paired native and
cross-processed estimates under the two delay-domain thresholds:

    USC data (U3 table) under NYU thres       : RMSE(U3_nyu_thr, U1)
    USC data (U3 table) under USC thres       : RMSE(U3_usc_thr, U1)
    NYU data (N3 table) under USC thres       : RMSE(N3_usc_thr, N1)
    NYU data (N3 table) under NYU thres       : RMSE(N3_nyu_thr, N1)

These are read directly from the two-row-header xlsx tables (the authoritative
Method_Comparison CSVs do not carry the threshold-variant columns).
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import config
from ._common import apply_style


def _col(raw, first, sub=None):
    for c in raw.columns:
        if c[0] != first:
            continue
        if sub is None:
            return c
        if isinstance(c[1], str) and sub.lower() in c[1].lower():
            return c
    return None


def _load_variants(xlsx_path: Path, orig_label: str) -> dict[str, pd.DataFrame]:
    """Returns {'nyu_thr', 'usc_thr', 'orig'} each a frame with TX-RX keys."""
    raw = pd.read_excel(xlsx_path, sheet_name="FinalTable", header=[1, 2])
    tx = _col(raw, "TX")
    raw[tx] = raw[tx].ffill()
    tr = _col(raw, "TR Sep")
    raw = raw[pd.to_numeric(raw[tr], errors="coerce").notna()].copy()
    out: dict[str, pd.DataFrame] = {}
    # USC xlsx reuses RX labels across LOS and NLOS groups, so include the
    # locatype in the key to make it unique.
    lt = raw[_col(raw, "Loc Type")].astype(str).str.upper().str.strip()
    key = (raw[tx].astype(str).str.replace("TX", "T", regex=False)
           + "-"
           + raw[_col(raw, "RX")].astype(str).str.replace("RX", "R", regex=False)
           + "|" + lt)
    for label, sub in (("nyu_thr", "NYU thres"),
                       ("usc_thr", "USC thres"),
                       ("orig",    orig_label)):
        frame = pd.DataFrame({"key": key})
        for metric_label, short in (("Omni PL", "pl"), ("Omni DS", "ds"),
                                    ("Omni ASA", "asa"), ("Omni ASD", "asd")):
            c = _col(raw, metric_label, sub)
            frame[short] = pd.to_numeric(raw[c], errors="coerce") if c is not None else np.nan
        out[label] = frame
    return out


def _rmse(a, b, guard_factor=50.0):
    a = np.asarray(a, dtype=float); b = np.asarray(b, dtype=float)
    m = np.isfinite(a) & np.isfinite(b)
    if m.sum() == 0:
        return float("nan")
    diff = np.abs(a - b)
    # Outlier guard for the one 714° ASA typo
    med = np.nanmedian(diff[m])
    outlier = diff > max(med * guard_factor, 100.0)
    keep = m & ~outlier
    return float(np.sqrt(np.mean((a[keep] - b[keep]) ** 2)))


def _compare_pair(left: pd.DataFrame, right: pd.DataFrame, metric: str):
    merged = left.merge(right, on="key", how="inner", suffixes=("_L", "_R"))
    return _rmse(merged[f"{metric}_L"].values, merged[f"{metric}_R"].values)


def render() -> dict:
    apply_style()
    root = config.DATA_ROOT
    # Load N3 (NYU data) and U3 (USC data) variants, per band
    bands = [("Sub-THz", "N3_142_UMi.xlsx", "U3_142_UMi.xlsx"),
             ("6.75 GHz", "N3_7_UMi.xlsx",  "U3_7_UMi.xlsx")]
    rows = []
    for band_label, n3_file, u3_file in bands:
        n3 = _load_variants(root / n3_file, "NYU orig")
        u3 = _load_variants(root / u3_file, "USC orig")
        for metric, mlabel in (("pl", "PL [dB]"), ("ds", "DS [ns]"),
                                ("asa", "ASA [deg]"), ("asd", "ASD [deg]")):
            rows.append({
                "Band": band_label, "Metric": mlabel,
                "USC data - NYU thres": _compare_pair(u3["nyu_thr"], u3["orig"], metric),
                "USC data - USC thres": _compare_pair(u3["usc_thr"], u3["orig"], metric),
                "NYU data - USC thres": _compare_pair(n3["usc_thr"], n3["orig"], metric),
                "NYU data - NYU thres": _compare_pair(n3["nyu_thr"], n3["orig"], metric),
            })
    tbl = pd.DataFrame(rows)
    config.ensure_output_dirs()
    out = Path(config.FIGURE_DIR) / "table06_rmse.csv"
    tbl.to_csv(out, index=False, float_format="%.3f")
    return {"table_csv": str(out), "rows": rows}
