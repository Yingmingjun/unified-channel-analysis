"""Tables 4, 8, 9, 10, 11 — per-location point-data summaries.

These paper tables are essentially pretty-prints of the institutional
point-data xlsx tables. We render each as a CSV under ``figures/python/`` so
readers can diff against the paper.

    Table 4  — partial N1 @ 142 GHz
    Table 8  — partial U3 @ 145.5 GHz
    Table 9  — partial U3 @ 6.75 GHz
    Table 10 — partial N3 @ 142 GHz
    Table 11 — partial N3 @ 6.75 GHz
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd

from .. import config
from ..io import load_point_data


def _sort_key(df: pd.DataFrame) -> pd.DataFrame:
    return df.sort_values(["tx", "rx"]).reset_index(drop=True)


def render() -> dict:
    """Write per-table CSVs. Returns {table_name: path}."""
    config.ensure_output_dirs()
    outputs: dict[str, str] = {}

    # --- Table 4 — N1 @ 142 GHz ----------------------------------------------
    df = load_point_data(variants=["N1"])
    t4 = _sort_key(df[(df.variant == "N1") & (df.freq_ghz == 142.0)])[
        ["tx", "rx", "loc_type", "d_m", "pl_db",
         "omni_ds_ns", "omni_asa_d", "omni_asd_d"]
    ]
    p = Path(config.FIGURE_DIR) / "table04_N1_142.csv"
    t4.to_csv(p, index=False, float_format="%.3f")
    outputs["table04_N1_142"] = str(p)

    # --- Tables 8 & 9 — U3 cross-processed (NYU-thres, USC-thres, USC-orig) --
    dfu3 = load_point_data(variants=["U1", "U3"])
    for freq, tag in [(145.5, "table08_U3_145"), (6.75, "table09_U3_7")]:
        sub = dfu3[dfu3.freq_ghz == freq]
        # Pivot so each row is a TX-RX pair with all three variant columns
        wide = _wide_variant(sub, ["U3_nyu_thr", "U3_usc_thr", "U1"])
        p = Path(config.FIGURE_DIR) / f"{tag}.csv"
        wide.to_csv(p, index=False, float_format="%.3f")
        outputs[tag] = str(p)

    # --- Tables 10 & 11 — N3 cross-processed (USC-thres, NYU-thres, NYU-orig)
    dfn3 = load_point_data(variants=["N1", "N3"])
    for freq, tag in [(142.0, "table10_N3_142"), (6.75, "table11_N3_7")]:
        sub = dfn3[dfn3.freq_ghz == freq]
        wide = _wide_variant(sub, ["N3_usc_thr", "N3_nyu_thr", "N1"])
        p = Path(config.FIGURE_DIR) / f"{tag}.csv"
        wide.to_csv(p, index=False, float_format="%.3f")
        outputs[tag] = str(p)

    return {"outputs": outputs}


def _wide_variant(df: pd.DataFrame, variants: list[str]) -> pd.DataFrame:
    """Pivot from long to wide by variant. Preserves tx/rx/loc/d ordering.

    Uses a left-merge per variant — robust to duplicate (tx, rx) keys which
    can occur when a station name is reused across frequencies.
    """
    metrics = ["pl_db", "omni_ds_ns", "omni_asa_d", "omni_asd_d"]
    base_keys = ["tx", "rx", "loc_type", "d_m"]

    base = (df[df.variant == variants[0]][base_keys]
            .drop_duplicates(subset=["tx", "rx"])
            .reset_index(drop=True))
    out = base.copy()
    for v in variants:
        sub = (df[df.variant == v]
               .drop_duplicates(subset=["tx", "rx"])
               [["tx", "rx"] + metrics]
               .rename(columns={m: f"{m}__{v}" for m in metrics}))
        out = out.merge(sub, on=["tx", "rx"], how="left")
    return out
