"""Load institution point-data tables into a canonical long-format DataFrame.

Load strategy per variant:

    N1 (NYU original, 142 GHz & 6.75 GHz)
        — from `142_UMi.xlsx` / `7_UMi.xlsx` (FinalTable sheet).
    U1 (USC original)
        — sub-THz: `usc_microcellular_{LOS,NLOS}_metrics.csv` (13+13 points).
        — 6.75 GHz: `7_UMi_U3.xlsx` "USC orig. (U1)" column (17 points);
          the dedicated 6.75 GHz csvs are truncated (only 8 points).
    N3_{nyu,usc}_thr (NYU data, USC pipeline, two thresholds)
        — from `142_UMi_N3.xlsx` / `7_UMi_N3.xlsx`.
    U3_{nyu,usc}_thr (USC data, NYU pipeline, two thresholds)
        — from `142_UMi_U3.xlsx` / `7_UMi_U3.xlsx`.

Returned columns (one row per TX-RX-variant):

    institution, band, freq_ghz, tx, rx, loc_type, loc_type_raw,
    d_m, pl_db, omni_ds_ns, omni_asa_d, omni_asd_d, variant
"""
from __future__ import annotations

from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd

from . import config

__all__ = ["load_point_data", "load_all"]


def _col(df: pd.DataFrame, first: str, second_contains: str | None = None):
    """Find a column by MultiIndex first-level (+ optional second-level substring)."""
    for c in df.columns:
        if c[0] != first:
            continue
        if second_contains is None:
            return c
        if isinstance(c[1], str) and second_contains.lower() in c[1].lower():
            return c
    return None


# -- N1 loader (single-header xlsx) -------------------------------------------
def _load_n1_xlsx(xlsx_path: Path, freq_ghz: float) -> pd.DataFrame:
    xls = pd.ExcelFile(xlsx_path)
    sheet = "FinalTable" if "FinalTable" in xls.sheet_names else xls.sheet_names[0]
    raw = pd.read_excel(xls, sheet_name=sheet, header=0)
    # 7_UMi xlsx has an extra "PL_X" column between PL and Mean Dir DS — drop it
    raw = raw.drop(columns=[c for c in ["PL_X"] if c in raw.columns])
    raw["TX"] = raw["TX"].ffill()
    mask = pd.to_numeric(raw["PL"], errors="coerce").notna()
    raw = raw[mask].copy()
    out = pd.DataFrame({
        "institution": "NYU",
        "band": "subTHz" if freq_ghz >= 100 else "FR1C",
        "freq_ghz": freq_ghz,
        "tx": raw["TX"].astype(str),
        "rx": raw["RX"].astype(str),
        "loc_type_raw": raw["Loc Type"].astype(str).str.upper().str.strip(),
        "d_m": pd.to_numeric(raw["TR Sep"], errors="coerce"),
        "pl_db": pd.to_numeric(raw["PL"], errors="coerce"),
        "omni_ds_ns": pd.to_numeric(raw["Omni DS"], errors="coerce"),
        "omni_asa_d": pd.to_numeric(raw["Omni ASA"], errors="coerce"),
        "omni_asd_d": pd.to_numeric(raw["Omni ASD"], errors="coerce"),
        "variant": "N1",
    })
    return out


# -- U1 loader (csv for sub-THz, xlsx for 6.75 GHz) ---------------------------
def _load_u1_csvs(los_csv: Path, nlos_csv: Path, freq_ghz: float) -> pd.DataFrame:
    frames = []
    for p, label in ((los_csv, "LOS"), (nlos_csv, "NLOS")):
        df = pd.read_csv(p)
        frames.append(pd.DataFrame({
            "institution": "USC",
            "band": "subTHz" if freq_ghz >= 100 else "FR1C",
            "freq_ghz": freq_ghz,
            "tx": "TX1",
            "rx": df["File"].str.extract(r"^(R\d+)")[0],
            "loc_type_raw": label,
            "d_m": df["Distance_m"].astype(float),
            "pl_db": df["PL_omni_dB"].astype(float),
            "omni_ds_ns": df["OmniDS_ns"].astype(float),
            "omni_asa_d": df["OmniASA_d"].astype(float),
            "omni_asd_d": df["OmniASD_d"].astype(float),
            "variant": "U1",
        }))
    return pd.concat(frames, ignore_index=True)


def _load_n1_from_n3_orig(n3_xlsx: Path, freq_ghz: float) -> pd.DataFrame:
    """Load N1 values from the 'NYU orig. (N1)' column of an N3 xlsx.

    These match the paper's Table 7 numbers (the N1 standalone xlsx files
    contain an earlier-stage snapshot that differs numerically).
    """
    raw = pd.read_excel(n3_xlsx, sheet_name="FinalTable", header=[1, 2])
    tx_col = _col(raw, "TX"); raw[tx_col] = raw[tx_col].ffill()
    freq_col = _col(raw, "Freq."); raw[freq_col] = raw[freq_col].ffill()
    tr_col = _col(raw, "TR Sep")
    raw = raw[pd.to_numeric(raw[tr_col], errors="coerce").notna()].copy()
    return pd.DataFrame({
        "institution": "NYU",
        "band": "subTHz" if freq_ghz >= 100 else "FR1C",
        "freq_ghz": freq_ghz,
        "tx": raw[tx_col].astype(str).values,
        "rx": raw[_col(raw, "RX")].astype(str).values,
        "loc_type_raw": raw[_col(raw, "Loc Type")].astype(str).str.upper().str.strip().values,
        "d_m": pd.to_numeric(raw[tr_col], errors="coerce").values,
        "pl_db": pd.to_numeric(raw[_col(raw, "Omni PL", "NYU orig")], errors="coerce").values,
        "omni_ds_ns": pd.to_numeric(raw[_col(raw, "Omni DS", "NYU orig")], errors="coerce").values,
        "omni_asa_d": pd.to_numeric(raw[_col(raw, "Omni ASA", "NYU orig")], errors="coerce").values,
        "omni_asd_d": pd.to_numeric(raw[_col(raw, "Omni ASD", "NYU orig")], errors="coerce").values,
        "variant": "N1",
    })


def _load_u1_from_u3_orig(u3_xlsx: Path, freq_ghz: float) -> pd.DataFrame:
    """Load U1 values from the 'USC orig. (U1)' column of a U3 xlsx."""
    raw = pd.read_excel(u3_xlsx, sheet_name="FinalTable", header=[1, 2])
    tx_col = _col(raw, "TX"); raw[tx_col] = raw[tx_col].ffill()
    freq_col = _col(raw, "Freq."); raw[freq_col] = raw[freq_col].ffill()
    tr_col = _col(raw, "TR Sep")
    raw = raw[pd.to_numeric(raw[tr_col], errors="coerce").notna()].copy()
    out = pd.DataFrame({
        "institution": "USC",
        "band": "subTHz" if freq_ghz >= 100 else "FR1C",
        "freq_ghz": freq_ghz,
        "tx": raw[tx_col].astype(str).values,
        "rx": raw[_col(raw, "RX")].astype(str).values,
        "loc_type_raw": raw[_col(raw, "Loc Type")].astype(str).str.upper().str.strip().values,
        "d_m": pd.to_numeric(raw[tr_col], errors="coerce").values,
        "pl_db": pd.to_numeric(raw[_col(raw, "Omni PL", "USC orig")], errors="coerce").values,
        "omni_ds_ns": pd.to_numeric(raw[_col(raw, "Omni DS", "USC orig")], errors="coerce").values,
        "omni_asa_d": pd.to_numeric(raw[_col(raw, "Omni ASA", "USC orig")], errors="coerce").values,
        "omni_asd_d": pd.to_numeric(raw[_col(raw, "Omni ASD", "USC orig")], errors="coerce").values,
        "variant": "U1",
    })
    return out


# -- N3/U3 loader (two-row header) --------------------------------------------
def _load_cross_xlsx(xlsx_path: Path, freq_ghz: float, kind: str) -> pd.DataFrame:
    """Load the NYU- and USC-threshold cross-processed variants from an N3 or U3 xlsx."""
    raw = pd.read_excel(xlsx_path, sheet_name="FinalTable", header=[1, 2])
    tx_col = _col(raw, "TX"); raw[tx_col] = raw[tx_col].ffill()
    freq_col = _col(raw, "Freq."); raw[freq_col] = raw[freq_col].ffill()
    tr_col = _col(raw, "TR Sep")
    raw = raw[pd.to_numeric(raw[tr_col], errors="coerce").notna()].copy()

    kind = kind.upper()
    institution = "NYU" if kind == "N3" else "USC"
    base = {
        "institution": institution,
        "band": "subTHz" if freq_ghz >= 100 else "FR1C",
        "freq_ghz": freq_ghz,
        "tx": raw[tx_col].astype(str).values,
        "rx": raw[_col(raw, "RX")].astype(str).values,
        "loc_type_raw": raw[_col(raw, "Loc Type")].astype(str).str.upper().str.strip().values,
        "d_m": pd.to_numeric(raw[tr_col], errors="coerce").values,
    }
    frames = []
    for suffix, sub in (("nyu_thr", "NYU thres"), ("usc_thr", "USC thres")):
        pl_c = _col(raw, "Omni PL", sub)
        if pl_c is None:
            continue
        frames.append(pd.DataFrame({
            **base,
            "pl_db": pd.to_numeric(raw[pl_c], errors="coerce").values,
            "omni_ds_ns": pd.to_numeric(raw[_col(raw, "Omni DS", sub)], errors="coerce").values,
            "omni_asa_d": pd.to_numeric(raw[_col(raw, "Omni ASA", sub)], errors="coerce").values,
            "omni_asd_d": pd.to_numeric(raw[_col(raw, "Omni ASD", sub)], errors="coerce").values,
            "variant": f"{kind}_{suffix}",
        }))
    return pd.concat(frames, ignore_index=True)


# -- Public API ---------------------------------------------------------------
def load_point_data(variants: Iterable[str] = ("N1", "U1")) -> pd.DataFrame:
    paths = config.DATA_PATHS
    want = {v.upper() for v in variants}
    frames: list[pd.DataFrame] = []

    if "N1" in want:
        # Authoritative N1 values live in the "NYU orig. (N1)" column of the
        # N3 xlsx; those match the joint-paper Table 7 numbers. The dedicated
        # 142_UMi.xlsx / 7_UMi.xlsx files are an earlier-processing snapshot.
        frames.append(_load_n1_from_n3_orig(paths["n3_142_xlsx"], 142.0))
        frames.append(_load_n1_from_n3_orig(paths["n3_7_xlsx"], 6.75))

    if "U1" in want:
        # Same story for U1: use the "USC orig. (U1)" column of U3 xlsx for both
        # bands — the 142 csv duplicates it and the 7 GHz csv is truncated.
        frames.append(_load_u1_from_u3_orig(paths["u3_142_xlsx"], 145.5))
        frames.append(_load_u1_from_u3_orig(paths["u3_7_xlsx"], 6.75))

    if "N3" in want:
        frames.append(_load_cross_xlsx(paths["n3_142_xlsx"], 142.0, "N3"))
        frames.append(_load_cross_xlsx(paths["n3_7_xlsx"], 6.75, "N3"))

    if "U3" in want:
        frames.append(_load_cross_xlsx(paths["u3_142_xlsx"], 145.5, "U3"))
        frames.append(_load_cross_xlsx(paths["u3_7_xlsx"], 6.75, "U3"))

    df = pd.concat(frames, ignore_index=True)
    df["loc_type"] = df["loc_type_raw"].where(df["loc_type_raw"] != "OLOS", "NLOS")
    return df.reset_index(drop=True)


def load_all() -> pd.DataFrame:
    return load_point_data(variants=["N1", "U1", "N3", "U3"])
