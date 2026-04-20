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
    # General outlier guard (median * guard_factor). Originally introduced
    # to handle a 714 deg ASA typo at N3_142 TX4-RX37 that has since been
    # fixed in the xlsx (2026-04-20); retained as defense-in-depth.
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
    # Paper Table VI was typeset from two different xlsx snapshots:
    #   - PL / DS columns   come from the *-RMSE.xlsx variants (paper snapshot)
    #   - ASA / ASD columns come from the regular *.xlsx (the RMSE variants
    #     have empty ASA/ASD columns).
    # We load both and pick per-metric.
    def _opt(path: Path) -> Path | None:
        return path if path.exists() else None

    bands = [
        ("Sub-THz",
         root / "N3_142_UMi.xlsx", root / "U3_142_UMi.xlsx",
         _opt(root / "N3_142_UMi_RMSE.xlsx"), _opt(root / "U3_142_UMi_RMSE.xlsx")),
        ("6.75 GHz",
         root / "N3_7_UMi.xlsx", root / "U3_7_UMi.xlsx",
         None, None),
    ]
    rows = []
    for band_label, n3_plain, u3_plain, n3_rmse, u3_rmse in bands:
        n3_p = _load_variants(n3_plain, "NYU orig")
        u3_p = _load_variants(u3_plain, "USC orig")
        n3_r = _load_variants(n3_rmse, "NYU orig") if n3_rmse else n3_p
        u3_r = _load_variants(u3_rmse, "USC orig") if u3_rmse else u3_p
        # PL/DS use RMSE-variant; ASA/ASD use the plain variant.
        sources = {"pl": (n3_r, u3_r), "ds": (n3_r, u3_r),
                   "asa": (n3_p, u3_p), "asd": (n3_p, u3_p)}
        for metric, mlabel in (("pl", "PL [dB]"), ("ds", "DS [ns]"),
                                ("asa", "ASA [deg]"), ("asd", "ASD [deg]")):
            n3v, u3v = sources[metric]
            rows.append({
                "Band": band_label, "Metric": mlabel,
                "USC data - NYU thres": _compare_pair(u3v["nyu_thr"], u3v["orig"], metric),
                "USC data - USC thres": _compare_pair(u3v["usc_thr"], u3v["orig"], metric),
                "NYU data - USC thres": _compare_pair(n3v["usc_thr"], n3v["orig"], metric),
                "NYU data - NYU thres": _compare_pair(n3v["nyu_thr"], n3v["orig"], metric),
            })
    tbl = pd.DataFrame(rows)
    config.ensure_output_dirs()
    out = Path(config.FIGURE_DIR) / "table06_rmse.csv"
    tbl.to_csv(out, index=False, float_format="%.3f")
    return {"table_csv": str(out), "rows": rows}
