"""Table 7 — Pooled statistical summary.

For each (band, dataset, loc_type) subset:
    * CI path-loss fit — PLE, sigma_SF (dB), 95% PLE CFI width (bootstrap)
    * Lognormal-expectation mean and 95% CFI width for DS, ASA, ASD

Dataset rows (matching paper Table VII):
    NYU only   — NYU institution (NYU-method columns)
    USC only   — USC institution (USC-method columns)
    Pooled     — NYU + USC, with the institution-native method per row
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


def _native_values(df, col_nyu, col_usc):
    """For each row, pick the NYU column if institution=='NYU' else USC."""
    return np.where(df["institution"].values == "NYU",
                    df[col_nyu].values, df[col_usc].values).astype(float)


def _stats_for(sub: pd.DataFrame, freq_ghz: float) -> dict:
    # Prefer the thresholded xlsx-sourced PL (matches paper Table 7); fall back
    # to the per-method CSV columns if needed.
    pl = sub["pl_db"].to_numpy() if "pl_db" in sub.columns \
         else _native_values(sub, "pl_nyu_sum", "pl_usc_pdm")
    fit = ci_fit(sub["d_m"].to_numpy(), pl, freq_ghz=freq_ghz)
    # Prefer the thresholded xlsx-sourced DS (matches paper Table 7); fall back
    # to the per-method CSV columns if needed.
    ds_vals = sub["omni_ds_ns"].to_numpy() if "omni_ds_ns" in sub.columns \
              else _native_values(sub, "ds_nyu_method", "ds_usc_method")
    ds  = lognormal_stats(ds_vals)
    asa = lognormal_stats(_native_values(sub, "asa_nyu_10", "asa_usc"))
    asd = lognormal_stats(_native_values(sub, "asd_nyu_10", "asd_usc"))
    return {
        "n": int(len(sub)),
        "PLE": fit.ple, "sigma_SF_dB": fit.sigma_sf,
        "PLE_CFI_width": fit.cfi_width,
        "DS_mean_ns": ds.mean_lognormal, "DS_CFI_width_ns": ds.cfi_width,
        "ASA_mean_d": asa.mean_lognormal, "ASA_CFI_width_d": asa.cfi_width,
        "ASD_mean_d": asd.mean_lognormal, "ASD_CFI_width_d": asd.cfi_width,
    }


def render() -> dict:
    apply_style()
    df = load_point_data()

    rows = []
    for band, band_label, pooled_freq in (
            ("subTHz", "Sub-THz (142/145.5)", 143.75),
            ("FR1C",   "6.75 GHz",             6.75)):
        for ds_name, inst_filter in (
                ("NYU only", {"NYU"}),
                ("USC only", {"USC"}),
                ("Pooled",   {"NYU", "USC"})):
            for loc in ("LOS", "NLOS"):
                sub = df[(df.band == band)
                         & (df.loc_type == loc)
                         & (df.institution.isin(inst_filter))]
                if len(sub) == 0:
                    continue
                if ds_name == "Pooled":
                    freq = pooled_freq
                elif inst_filter == {"NYU"}:
                    freq = 142.0 if band == "subTHz" else 6.75
                else:
                    freq = 145.5 if band == "subTHz" else 6.75
                rows.append({"Band": band_label, "Dataset": ds_name,
                             "LocType": loc, **_stats_for(sub, freq)})
    tbl = pd.DataFrame(rows)
    config.ensure_output_dirs()
    out = Path(config.FIGURE_DIR) / "table07_pooled_stats.csv"
    tbl.to_csv(out, index=False, float_format="%.4f")
    return {"table_csv": str(out), "rows": rows}
