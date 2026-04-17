"""Tables 4, 8, 9, 10, 11 — per-location point-data summaries.

Each paper table is a pretty-print of one of the bundled xlsx point-data
files. We dump them as CSV under ``figures/python/`` so readers can diff
directly against the paper tables.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import config


def _read_xlsx_two_row_header(path: Path) -> pd.DataFrame:
    raw = pd.read_excel(path, sheet_name="FinalTable", header=[1, 2])
    # Forward-fill continuation-row TX/Freq and drop non-numeric TR Sep rows
    def _col(name):
        for c in raw.columns:
            if c[0] == name:
                return c
        return None
    tx = _col("TX"); raw[tx] = raw[tx].ffill()
    fr = _col("Freq."); raw[fr] = raw[fr].ffill()
    tr = _col("TR Sep")
    raw = raw[pd.to_numeric(raw[tr], errors="coerce").notna()].copy()
    raw.columns = [f"{a}__{b}" if (isinstance(b, str) and not b.startswith("Unnamed"))
                   else f"{a}" for a, b in raw.columns]
    return raw.reset_index(drop=True)


def render() -> dict:
    outputs: dict[str, str] = {}
    root = config.DATA_ROOT
    config.ensure_output_dirs()

    pairs = [
        ("table04_N1_142.csv", root / "N1_142_UMi.xlsx"),
        ("table08_U3_145.csv", root / "U3_142_UMi.xlsx"),
        ("table09_U3_7.csv",   root / "U3_7_UMi.xlsx"),
        ("table10_N3_142.csv", root / "N3_142_UMi.xlsx"),
        ("table11_N3_7.csv",   root / "N3_7_UMi.xlsx"),
    ]
    for name, src in pairs:
        if not src.exists():
            continue
        if "N1" in src.name and "N1_" in src.name:
            df = pd.read_excel(src, sheet_name="FinalTable", header=0)
            df = df.drop(columns=[c for c in ["PL_X"] if c in df.columns])
            df["TX"] = df["TX"].ffill()
            df = df[pd.to_numeric(df["PL"], errors="coerce").notna()]
        else:
            df = _read_xlsx_two_row_header(src)
        out_path = Path(config.FIGURE_DIR) / name
        df.to_csv(out_path, index=False, float_format="%.3f")
        outputs[name] = str(out_path)
    return {"outputs": outputs}
