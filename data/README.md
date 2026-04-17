# Data

**The NYU and USC measurement datasets are NOT included in this repository** due to institutional distribution restrictions.

This directory is intentionally empty except for this README. The `.gitignore` at the repo root excludes any path matching `*Data*`, `*.mat`, and measurement-campaign subtrees, so no data can accidentally be committed here.

## Expected folder structure (what the code reads)

The Python and MATLAB loaders expect the following institutional drop:

```
<CHANNEL_DATA_ROOT>/
└── NaveedDipankarMingjunJorgeShare/
    ├── NYU/
    │   ├── NYUprocessUSCdata/
    │   │   └── OriginalUSC-PointData/
    │   │       ├── 142_UMi_U3.xlsx          # USC sub-THz, cross-processed (U3)
    │   │       ├── 7_UMi_U3.xlsx            # USC 6.75 GHz, cross-processed (U3)
    │   │       ├── usc_microcellular_LOS_metrics.csv      # U1 sub-THz LOS (legacy)
    │   │       └── usc_microcellular_NLOS_metrics.csv     # U1 sub-THz NLOS (legacy)
    │   └── NYU_Data/                         # raw NYU measurement records (not used by Python)
    ├── USC/
    │   ├── USCprocessNYUdata/
    │   │   └── OriginalNYU_pointData/
    │   │       ├── 142_UMi_N3.xlsx          # NYU sub-THz, cross-processed (N3)
    │   │       └── 7_UMi_N3.xlsx            # NYU 6.75 GHz, cross-processed (N3)
    │   └── USC_Data/                         # raw USC measurement records (not used by Python)
    └── ...
```

Set the root via the `CHANNEL_DATA_ROOT` environment variable (or override individual paths by editing `channel_analysis.config.DATA_PATHS` for Python, or `matlab/config/paths.m` for MATLAB).

## Point-data xlsx schema

Each cross-processing xlsx (`*_N3.xlsx`, `*_U3.xlsx`) uses a **two-row header**:

- Header row 1 (top): metric group — `Freq.`, `TX`, `RX`, `Loc Type`, `TR Sep`, `Omni PL`, `Omni DS`, `Omni ASA`, `Omni ASD` (each metric spans three sub-columns).
- Header row 2: threshold variant — `NYU thres`, `USC thres`, and the partner-institution *original* (`NYU orig. (N1)` inside N3 files; `USC orig. (U1)` inside U3 files).

One row per TX-RX pair. `Loc Type` is one of `LOS`, `NLOS`, `OLOS` (USC 6.75 GHz only; re-labeled to `NLOS` for modeling).

## Raw-data folders (optional)

`NYU_Data/` and `USC_Data/` contain the directional-PDP recordings that produced the point-data tables. They are **not** read by the Python package — the MATLAB pipelines in Codebase A (`D:/NaveedDipankarMingjunJorgeShare/...`) and Codebase B (`D:/NYU-USC/Cross-Processing/`) are the authoritative path from raw measurements to point data. Large (tens of GB).

## Regenerating the point-data tables (advanced)

If you need to regenerate the xlsx point-data tables from raw measurements, use the original MATLAB pipelines:
- NYU side: `USC/USCprocessNYUdata/USCprocessNYU142M_exp.m` and the 7 GHz twin
- USC side: `NYU/NYUprocessUSCdata/NYUprocessUSC145.m` and the 7 GHz twin

The Python package does NOT re-implement these pipelines; they require proprietary sounder formats and are tightly tied to institution-specific calibration paths.

## Citation note

If you reuse the data drops, please cite the original measurement campaign references as well as this paper:

- NYU sub-THz: Shakya et al., "Propagation Measurements and Channel Models at 142 GHz in Urban Microcell," IEEE TAP, 2024 (`Shakya2024tap`).
- NYU 6.75 GHz: Shakya et al., "Propagation Measurements at 6.75 GHz for 6G FR3," IEEE OJ-COMS, 2024 (`Shakya2024ojcoms`).
- USC sub-THz: Abbasi et al., "THz Band Channel Measurements," IEEE TAP, 2023 (`abbasi2023thz`).
- USC 6.75 GHz: Abbasi et al., IEEE ICC 2025 (`abbasi2025icc`).
