"""Table 7 — Pooled statistical summary: CI PL parameters, mean omni DS/AS,
and 95 % CFI widths per (band × dataset × loc_type).

This is the single numerical reproduction target for most of Section V of the
paper. Output is a long-format CSV and a json stats dump used by the
``numerical_parity`` report.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import config
from ..ds import lognormal_stats
from ..io import load_point_data
from ..pl import ci_fit
from ._common import apply_style


def _stats_for(df_sub: pd.DataFrame, freq_ghz: float) -> dict:
    fit = ci_fit(df_sub["d_m"].to_numpy(), df_sub["pl_db"].to_numpy(),
                 freq_ghz=freq_ghz)
    ds = lognormal_stats(df_sub["omni_ds_ns"].to_numpy())
    asa = lognormal_stats(df_sub["omni_asa_d"].to_numpy())
    asd = lognormal_stats(df_sub["omni_asd_d"].to_numpy())
    return {
        "n_pl": int(df_sub["pl_db"].notna().sum()),
        "n_ds": int(df_sub["omni_ds_ns"].notna().sum()),
        "PLE": fit.ple, "sigma_SF_dB": fit.sigma_sf,
        "PLE_CFI_width": fit.cfi_width,
        "DS_mean_ns": ds.mean_lognormal, "DS_CFI_width_ns": ds.cfi_width,
        "ASA_mean_d": asa.mean_lognormal, "ASA_CFI_width_d": asa.cfi_width,
        "ASD_mean_d": asd.mean_lognormal, "ASD_CFI_width_d": asd.cfi_width,
    }


def render() -> dict:
    apply_style()
    # Don't drop rows here — each statistic filters its own NaN independently.
    df = load_point_data(variants=["N1", "U1"])

    rows = []
    for band, label, freq_for_fit in [("subTHz", "Sub-THz (142/145.5)", 143.75),
                                      ("FR1C", "6.75 GHz", 6.75)]:
        for (dataset_name, institution_filter) in [
            ("NYU only", ("NYU",)),
            ("USC only", ("USC",)),
            ("Pooled",   ("NYU", "USC")),
        ]:
            for loc in ("LOS", "NLOS"):
                sub = df[(df.band == band)
                         & (df.loc_type == loc)
                         & (df.institution.isin(institution_filter))]
                if len(sub) == 0:
                    continue
                if dataset_name == "Pooled":
                    freq_used = freq_for_fit
                elif institution_filter == ("NYU",):
                    freq_used = 142.0 if band == "subTHz" else 6.75
                else:                              # USC only
                    freq_used = 145.5 if band == "subTHz" else 6.75
                s = _stats_for(sub, freq_used)
                rows.append({"Band": label, "Dataset": dataset_name, "LocType": loc,
                             **s})
    tbl = pd.DataFrame(rows)
    config.ensure_output_dirs()
    out_csv = Path(config.FIGURE_DIR) / "table07_pooled_stats.csv"
    tbl.to_csv(out_csv, index=False, float_format="%.4f")
    return {"table_csv": str(out_csv),
            "rows": rows}
