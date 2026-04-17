"""Load the per-TX-RX measurement results into a canonical long DataFrame.

The paper's figure scripts use **two** source families:

* **Angular spread (Fig 4, Fig 7, Fig 8)** reads from the ``.mat`` result
  tables produced by ``Comprehensive_NYU_USC_Analysis_v7.m``. We bundle
  the CSV exports of those same tables under ``data/point_data/``:

    NYU142GHz_Method_Comparison_Results.csv   (27 rows: 16 LOS + 11 NLOS)
    NYU7GHz_Method_Comparison_Results.csv     (18 rows:  6 LOS + 12 NLOS)
    USC145GHz_Full_Results.csv                (26 rows: 13 LOS + 13 NLOS)
    USC7GHz_NewData_Results.csv               (17 rows:  6 LOS + 11 NLOS)

  Columns: ``ASA_NYU_10dB`` (NYU method, 10 dB PAS threshold, paper
  canonical), ``ASA_USC`` (USC method, no spatial threshold), and their
  15 / 20 dB sensitivity siblings.

* **Path loss / Delay spread (Fig 3, Fig 5, Fig 6)** reads from the
  two-row-header xlsx point-data tables (``142_UMi_N3.xlsx``, etc.)
  columns labeled ``NYU orig. (N1)`` / ``USC orig. (U1)`` — these carry
  the thresholded / noise-floor-filtered values that the paper's Table 7
  PL and DS columns quote.

We join the two on the ``(institution, band, tx_rx_id)`` key and return
a single long-format DataFrame with both sets of columns populated.

Canonical columns:

    institution, band, freq_ghz, tx_rx_id, d_m,
    loc_type, loc_type_raw,
    pl_db         -- from xlsx "<inst> orig" column (PL for Fig 3/5/6 stats)
    omni_ds_ns    -- from xlsx "<inst> orig" column
    asa_nyu_10, asa_nyu_15, asa_nyu_20, asa_usc  -- from authoritative CSV
    asd_nyu_10, asd_nyu_15, asd_nyu_20, asd_usc  -- from authoritative CSV
    # Native per-institution delay-spread (Bland-Altman sourcing)
    ds_nyu_method, ds_usc_method   -- from authoritative CSV

Counts: 53 sub-THz + 35 FR1C = 88 total (27 NYU 142 + 26 USC 145.5 +
18 NYU 6.75 + 17 USC 6.75).
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from . import config

__all__ = ["load_point_data", "load_all", "expected_counts"]


# =========================================================================
# Expected counts (paper Table III / dataset description)
# =========================================================================
def expected_counts() -> dict:
    return {
        ("NYU", 142.0):  {"LOS": 16, "NLOS": 11, "total": 27},
        ("USC", 145.5):  {"LOS": 13, "NLOS": 13, "total": 26},
        ("NYU", 6.75):   {"LOS":  6, "NLOS": 12, "total": 18},
        ("USC", 6.75):   {"LOS":  6, "NLOS": 11, "total": 17},
    }


def _norm_env(s):
    return pd.Series(s, dtype=str).str.upper().str.strip()


# =========================================================================
# Authoritative AS CSVs (NYU 142 / 6.75, USC 145 / 6.75)
# =========================================================================
def _load_as_nyu_142(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    return pd.DataFrame({
        "institution": "NYU", "band": "subTHz", "freq_ghz": 142.0,
        "tx_rx_id": df["TX_RX_ID"].astype(str),
        "loc_type_raw": _norm_env(df["Environment"]),
        "pl_nyu_sum": df["PL_NYU_SUM_dB"],
        "pl_usc_pdm": df["PL_USC_perDelayMax_dB"],
        "ds_nyu_method": df["DS_NYU_SUM_ns"],
        "ds_usc_method": df["DS_USC_perDelayMax_ns"],
        "asa_nyu_10": df["ASA_NYU_10dB"], "asa_nyu_15": df["ASA_NYU_15dB"],
        "asa_nyu_20": df["ASA_NYU_20dB"], "asa_usc":    df["ASA_USC"],
        "asd_nyu_10": df["ASD_NYU_10dB"], "asd_nyu_15": df["ASD_NYU_15dB"],
        "asd_nyu_20": df["ASD_NYU_20dB"], "asd_usc":    df["ASD_USC"],
    })


def _load_as_nyu_7(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    return pd.DataFrame({
        "institution": "NYU", "band": "FR1C", "freq_ghz": 6.75,
        "tx_rx_id": df["TX_RX_ID"].astype(str),
        "d_m": df["Distance_m"].astype(float),
        "loc_type_raw": _norm_env(df["Environment"]),
        "pl_nyu_sum": df["NYUthr_PL_SUM_dB"],
        "pl_usc_pdm": df["NYUthr_PL_pDM_dB"],
        "ds_nyu_method": df["NYUthr_DS_SUM_ns"],
        "ds_usc_method": df["NYUthr_DS_pDM_ns"],
        "asa_nyu_10": df["NYUthr_ASA_N10"], "asa_nyu_15": df["NYUthr_ASA_N15"],
        "asa_nyu_20": df["NYUthr_ASA_N20"], "asa_usc":    df["NYUthr_ASA_U"],
        "asd_nyu_10": df["NYUthr_ASD_N10"], "asd_nyu_15": df["NYUthr_ASD_N15"],
        "asd_nyu_20": df["NYUthr_ASD_N20"], "asd_usc":    df["NYUthr_ASD_U"],
    })


def _load_as_usc(path: Path, freq_ghz: float) -> pd.DataFrame:
    df = pd.read_csv(path)
    band = "subTHz" if freq_ghz >= 100 else "FR1C"
    return pd.DataFrame({
        "institution": "USC", "band": band, "freq_ghz": freq_ghz,
        "tx_rx_id": df["Location"].astype(str),
        "d_m": df["Distance_m"].astype(float),
        "loc_type_raw": _norm_env(df["Env"]),
        "pl_nyu_sum": df["PL_NYU_dB"],
        "pl_usc_pdm": df["PL_USC_dB"],
        "ds_nyu_method": df["DS_NYU_ns"],
        "ds_usc_method": df["DS_USC_ns"],
        "asa_nyu_10": df["ASA_NYU_10dB"], "asa_nyu_15": df["ASA_NYU_15dB"],
        "asa_nyu_20": df["ASA_NYU_20dB"], "asa_usc":    df["ASA_USC"],
        "asd_nyu_10": df["ASD_NYU_10dB"], "asd_nyu_15": df["ASD_NYU_15dB"],
        "asd_nyu_20": df["ASD_NYU_20dB"], "asd_usc":    df["ASD_USC"],
    })


# =========================================================================
# Thresholded PL/DS from the xlsx tables (paper "N1 orig" / "U1 orig")
# =========================================================================
def _xlsx_orig_cols(xlsx_path: Path, pick_orig: str):
    """Return a DataFrame keyed by (TX, RX) with the 'orig' columns."""
    raw = pd.read_excel(xlsx_path, sheet_name="FinalTable", header=[1, 2])

    def _col(first, sub=None):
        for c in raw.columns:
            if c[0] != first:
                continue
            if sub is None:
                return c
            if isinstance(c[1], str) and sub.lower() in c[1].lower():
                return c
        return None

    tx = _col("TX"); rx = _col("RX"); lt = _col("Loc Type"); tr = _col("TR Sep")
    raw[tx] = raw[tx].ffill()
    raw = raw[pd.to_numeric(raw[tr], errors="coerce").notna()].copy()

    pl_c  = _col("Omni PL",  pick_orig)
    ds_c  = _col("Omni DS",  pick_orig)
    return pd.DataFrame({
        "tx": raw[tx].astype(str).str.replace("TX", "T", regex=False),
        "rx": raw[rx].astype(str).str.replace("RX", "R", regex=False),
        "loc_type_raw": raw[lt].astype(str).str.upper().str.strip(),
        "d_m_xlsx": pd.to_numeric(raw[tr], errors="coerce"),
        "pl_orig": pd.to_numeric(raw[pl_c], errors="coerce"),
        "ds_orig": pd.to_numeric(raw[ds_c], errors="coerce"),
    })


def _xlsx_n1_like_key(raw: pd.DataFrame) -> pd.DataFrame:
    # NYU xlsx single-row header: "TX" like "TX1", "RX" like "RX1"
    raw = raw.copy()
    raw["tx"] = raw["TX"].astype(str).str.replace("TX", "T", regex=False)
    raw["rx"] = raw["RX"].astype(str).str.replace("RX", "R", regex=False)
    return raw


def _load_n1_xlsx_single_header(xlsx_path: Path) -> pd.DataFrame:
    raw = pd.read_excel(xlsx_path, sheet_name="FinalTable", header=0)
    raw = raw.drop(columns=[c for c in ["PL_X"] if c in raw.columns])
    raw["TX"] = raw["TX"].ffill()
    raw = raw[pd.to_numeric(raw["PL"], errors="coerce").notna()]
    raw = _xlsx_n1_like_key(raw)
    return pd.DataFrame({
        "tx": raw["tx"], "rx": raw["rx"],
        "d_m_xlsx": raw["TR Sep"].astype(float),
        "pl_orig": raw["PL"].astype(float),
        "ds_orig": raw["Omni DS"].astype(float),
    })


def _attach_xlsx_pl_ds(frame: pd.DataFrame, xlsx_path: Path,
                       pick_orig: str | None, by: str = "key") -> pd.DataFrame:
    """Join xlsx "orig" PL/DS into an AS-csv-based frame.

    Two join strategies:
      by='key' : normalize CSV tx_rx_id (e.g. "T1-R1", "TX1-RX5") to the
                 xlsx's "T1-R1" form and merge on that string key. Works
                 for NYU data where the CSV uses the same TX-RX scheme.
      by='position' : align the two tables by row order within each
                 loc_type group. Works for USC data where the CSV key
                 ("R01", "LOS_RX1_07-12-2024") doesn't match the xlsx's
                 "T1-R1". Both files list LOS rows first, then NLOS.
    """
    frame = frame.copy()
    if pick_orig is None or not xlsx_path.exists():
        frame["pl_orig"] = np.nan
        frame["ds_orig"] = np.nan
        frame["d_m_xlsx"] = np.nan
        return frame
    aux = _xlsx_orig_cols(xlsx_path, pick_orig)

    if by == "key":
        aux["key"] = aux["tx"] + "-" + aux["rx"]
        key = (frame["tx_rx_id"].astype(str)
               .str.replace("TX", "T", regex=False)
               .str.replace("RX", "R", regex=False))
        frame["key"] = key
        out = frame.merge(aux[["key", "pl_orig", "ds_orig", "d_m_xlsx"]],
                          on="key", how="left")
        return out.drop(columns=["key"])

    # Positional merge within loc_type groups
    aux["loc_sort"] = np.where(
        aux["loc_type_raw"].isin({"LOS"}), 0,
        np.where(aux["loc_type_raw"].isin({"NLOS", "OLOS"}), 1, 2))
    aux = aux.sort_values(["loc_sort"]).reset_index(drop=True)
    # Sort frame the same way
    frame["__loc_sort"] = np.where(
        frame["loc_type_raw"].isin({"LOS"}), 0,
        np.where(frame["loc_type_raw"].isin({"NLOS", "OLOS"}), 1, 2))
    frame = frame.sort_values(["__loc_sort"]).reset_index(drop=True)
    # Attach by position within each loc_sort group
    cols = ["pl_orig", "ds_orig", "d_m_xlsx"]
    for c in cols:
        frame[c] = np.nan
    for s in frame["__loc_sort"].unique():
        f_idx = frame.index[frame["__loc_sort"] == s].tolist()
        a_idx = aux.index[aux["loc_sort"] == s].tolist()
        n = min(len(f_idx), len(a_idx))
        for c in cols:
            frame.loc[f_idx[:n], c] = aux.loc[a_idx[:n], c].values
    return frame.drop(columns=["__loc_sort"])


# =========================================================================
# Public
# =========================================================================
def load_point_data() -> pd.DataFrame:
    root = config.DATA_ROOT
    frames = [
        _load_as_nyu_142(root / "NYU142GHz_Method_Comparison_Results.csv"),
        _load_as_nyu_7  (root / "NYU7GHz_Method_Comparison_Results.csv"),
        _load_as_usc    (root / "USC145GHz_Full_Results.csv",       145.5),
        _load_as_usc    (root / "USC7GHz_NewData_Results.csv",       6.75),
    ]
    df = pd.concat(frames, ignore_index=True)

    # Attach xlsx "orig" PL/DS for NYU (matches paper Table 7 values).
    nyu_142 = _attach_xlsx_pl_ds(
        df[(df.institution == "NYU") & (df.band == "subTHz")].copy(),
        root / "N3_142_UMi.xlsx", "NYU orig")
    nyu_7 = _attach_xlsx_pl_ds(
        df[(df.institution == "NYU") & (df.band == "FR1C")].copy(),
        root / "N3_7_UMi.xlsx", "NYU orig")
    # USC: the U3 xlsx uses T1-R1 style keys, CSV uses R01 / LOS_RX1_*; merge
    # positionally within each loc_type group.
    usc_145 = _attach_xlsx_pl_ds(
        df[(df.institution == "USC") & (df.band == "subTHz")].copy(),
        root / "U3_142_UMi.xlsx", "USC orig", by="position")
    usc_7 = _attach_xlsx_pl_ds(
        df[(df.institution == "USC") & (df.band == "FR1C")].copy(),
        root / "U3_7_UMi.xlsx", "USC orig", by="position")

    df = pd.concat([nyu_142, nyu_7, usc_145, usc_7], ignore_index=True)

    # pl_db / omni_ds_ns = prefer the xlsx "orig" values; fall back to native
    # per-institution method values from the CSV (for USC — keys don't always
    # match).
    df["pl_db"] = df["pl_orig"]
    df["omni_ds_ns"] = df["ds_orig"]
    # Fallback for USC (xlsx uses different RX key format: "RX1" vs "R01_*"):
    missing_pl = df["pl_db"].isna()
    if missing_pl.any():
        native = np.where(df["institution"].values == "NYU",
                          df["pl_nyu_sum"].values, df["pl_usc_pdm"].values)
        df.loc[missing_pl, "pl_db"] = native[missing_pl]
    missing_ds = df["omni_ds_ns"].isna()
    if missing_ds.any():
        native_ds = np.where(df["institution"].values == "NYU",
                              df["ds_nyu_method"].values, df["ds_usc_method"].values)
        df.loc[missing_ds, "omni_ds_ns"] = native_ds[missing_ds]

    # Distance: prefer CSV distance (USC), fall back to xlsx distance (NYU 142)
    if "d_m" not in df.columns:
        df["d_m"] = np.nan
    missing_d = df["d_m"].isna()
    df.loc[missing_d, "d_m"] = df.loc[missing_d, "d_m_xlsx"]

    # OLOS → NLOS for modeling (USC 6.75 GHz)
    df["loc_type"] = df["loc_type_raw"].where(df["loc_type_raw"] != "OLOS", "NLOS")

    keep = ["institution", "band", "freq_ghz", "tx_rx_id", "d_m",
            "loc_type", "loc_type_raw",
            "pl_db", "omni_ds_ns",
            "pl_nyu_sum", "pl_usc_pdm", "ds_nyu_method", "ds_usc_method",
            "asa_nyu_10", "asa_nyu_15", "asa_nyu_20", "asa_usc",
            "asd_nyu_10", "asd_nyu_15", "asd_nyu_20", "asd_usc"]
    return df[keep].reset_index(drop=True)


def load_all() -> pd.DataFrame:
    return load_point_data()
