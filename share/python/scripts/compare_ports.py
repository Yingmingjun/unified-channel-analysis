"""Compare Python vs. MATLAB port outputs cell-by-cell (numeric and categorical).

After running both ports (`channel-run-all` in Python, `run_all` in MATLAB),
this script diffs the two sets of table CSVs and writes a markdown summary
to docs/matlab_python_diff.md.

Column-name normalization: MATLAB's writetable sanitizes column names (strips
spaces and punctuation, CamelCases) so we normalize Python and MATLAB names
to a comparable key before aligning numeric columns.

Usage:
    python python/scripts/compare_ports.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd

REPO = Path(__file__).resolve().parents[2]
PY = REPO / "figures" / "python"
ML = REPO / "figures" / "matlab"
OUT = REPO / "docs" / "matlab_python_diff.md"

PAIRS = [
    "table04_N1_142.csv",
    "table06_rmse.csv",
    "table07_pooled_stats.csv",
    "table08_U3_145.csv",
    "table09_U3_7.csv",
    "table10_N3_142.csv",
    "table11_N3_7.csv",
]

TOLERANCE_ABS = 0.05   # absolute tolerance for near-zero cells
TOLERANCE_REL = 0.02   # 2% relative tolerance for non-zero cells


def _norm_col(name: str) -> str:
    """Normalize column name for cross-port alignment."""
    s = str(name)
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "", s)          # drop spaces, _, punctuation
    # Simple synonyms
    s = s.replace("tresp", "tsep")
    return s


def _numeric_df(df: pd.DataFrame) -> pd.DataFrame:
    """Keep only numeric columns; rename to normalized keys."""
    cols = [c for c in df.columns if pd.api.types.is_numeric_dtype(df[c])]
    out = df[cols].copy()
    out.columns = [_norm_col(c) for c in out.columns]
    return out


def _align_rows(p: pd.DataFrame, m: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """If both have the same row count, return as-is aligned; otherwise None."""
    if len(p) == len(m):
        return p.reset_index(drop=True), m.reset_index(drop=True)
    return None, None


def _stringify_row(row: pd.Series, non_numeric_cols) -> str:
    parts = []
    for c in non_numeric_cols:
        if c in row:
            parts.append(f"{c}={row[c]}")
    return "; ".join(str(x) for x in parts[:3])


def compare_one(name: str, py_path: Path, ml_path: Path) -> list[str]:
    out: list[str] = [f"## `{name}`\n"]
    if not py_path.exists():
        out.append(f"- ❌ Python CSV missing: `{py_path}`\n")
        return out
    if not ml_path.exists():
        out.append(f"- ❌ MATLAB CSV missing: `{ml_path}` — run `matlab/run_all.m` first\n")
        return out

    p = pd.read_csv(py_path)
    m = pd.read_csv(ml_path)

    p_num = _numeric_df(p)
    m_num = _numeric_df(m)

    common = [c for c in p_num.columns if c in m_num.columns]
    py_only = [c for c in p_num.columns if c not in m_num.columns]
    ml_only = [c for c in m_num.columns if c not in p_num.columns]

    out.append(f"- Python rows: {len(p)}, MATLAB rows: {len(m)}")
    out.append(f"- Common numeric columns (after name normalization): {len(common)}")
    if py_only:
        out.append(f"- Python-only: {py_only}")
    if ml_only:
        out.append(f"- MATLAB-only: {ml_only}")

    if not common:
        out.append("- ⚠️ No numeric columns aligned. Likely a column-name sanitization mismatch.")
        out.append("")
        return out
    if len(p) != len(m):
        out.append(f"- ⚠️ Row count mismatch ({len(p)} vs {len(m)}) — skipping cell diff.")
        out.append("")
        return out

    p_aligned = p_num[common].reset_index(drop=True)
    m_aligned = m_num[common].reset_index(drop=True)
    abs_diff = (p_aligned.values - m_aligned.values)
    denom = np.maximum(np.abs(p_aligned.values), 1e-9)
    rel_diff = np.abs(abs_diff) / denom

    # Per-cell tolerance: pass if |Δ|<ABS or rel_Δ<REL
    per_cell_pass = (np.abs(abs_diff) < TOLERANCE_ABS) | (rel_diff < TOLERANCE_REL)
    fails = ~per_cell_pass & np.isfinite(abs_diff)
    abs_max = float(np.nanmax(np.abs(abs_diff)))
    rel_max = float(np.nanmax(rel_diff))

    n_fail = int(fails.sum())
    status = "✅ all cells within tolerance" if n_fail == 0 else f"⚠️ {n_fail} cell(s) exceed tolerance"
    out.append(f"- Max |Δ|: **{abs_max:.4g}**   Max rel Δ: **{rel_max:.4g}** — {status}")

    # If there are failures, surface the worst 5
    if n_fail > 0:
        non_numeric = [c for c in p.columns if not pd.api.types.is_numeric_dtype(p[c])]
        flat_rel = rel_diff.flatten()
        flat_fail = fails.flatten()
        masked = np.where(flat_fail, flat_rel, -1)
        idx = np.argsort(-masked)[: min(5, n_fail)]
        out.append("")
        out.append("| Row | Column (normalized) | Python | MATLAB | |Δ| | Δ/Py |")
        out.append("|-----|---------------------|--------|--------|-----|------|")
        for k in idx:
            r, c = divmod(int(k), len(common))
            label = _stringify_row(p.iloc[r], non_numeric)
            out.append(
                f"| {label} | {common[c]} | "
                f"{p_aligned.iloc[r, c]:.4g} | {m_aligned.iloc[r, c]:.4g} | "
                f"{abs(abs_diff[r, c]):.4g} | {rel_diff[r, c]:.4g} |"
            )
    out.append("")
    return out


def main() -> int:
    if not PY.exists():
        print(f"Python output directory missing: {PY}", file=sys.stderr)
        return 1
    if not ML.exists():
        print(f"MATLAB output directory missing: {ML}", file=sys.stderr)
        return 1
    lines = [
        "# MATLAB ↔ Python port — cell-level diff report",
        "",
        f"Tolerance: |Δ| < {TOLERANCE_ABS} OR relative Δ < {TOLERANCE_REL*100:.0f} %.",
        "",
    ]
    for name in PAIRS:
        lines.extend(compare_one(name, PY / name, ML / name))
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
