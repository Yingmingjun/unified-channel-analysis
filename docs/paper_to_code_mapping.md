# Paper → Code Mapping

For every paper figure and table, this document specifies which Python driver produces it, and which upstream MATLAB script it originated from.

All Python drivers live under `python/src/channel_analysis/figures/`. The central orchestrator `run_all` invokes them in sequence.

Input point-data tables (xlsx/csv — shipped by the measurement teams, not by this repo) live under the paths set in `channel_analysis.config.DATA_PATHS`. This Python package treats those tables as the canonical input; raw directional-PDP re-processing from measurement data is **not** part of the Python port — the MATLAB originals are the reference for that step, see Phase 6.

## Figures

| Paper Fig.       | Subpanels | Metric                              | Python driver                          | MATLAB origin (authoritative)                                     |
|------------------|-----------|-------------------------------------|----------------------------------------|-------------------------------------------------------------------|
| Fig. 1           | —         | Flow diagram (schematic, no data)   | `figures/fig01_flow_diagram.py` (TikZ → PDF passthrough, documented only) | Tex TikZ block in `main_final.tex` lines ~30–54 |
| Fig. 2 (a,b)     | 2         | Calibrated directional PDPs (USC/NYU, NLOS) | Not reproducible from point-data (requires raw PDP); documented as PNG passthrough from paper `figures/` | NYU `NYUprocessUSCdata/*.m` + USC processing scripts |
| Fig. 3 (a–d)     | 4         | Bland–Altman PL and DS, sub-THz and 6.75 GHz | `figures/fig03_bland_altman_pl_ds.py` | `bland_altman_analysis.m`, `Plot_BlandAltman_PL_DS_AS.m`, `BA_AS_Merged.m` |
| Fig. 4 (a–d)     | 4         | Bland–Altman ASA and ASD, sub-THz and 6.75 GHz | `figures/fig04_bland_altman_as.py` | `BA_AS_Merged.m`, `Plot_BlandAltman_PL_DS_AS.m` |
| Fig. 5 (a,b)     | 2         | Close-in PL scatter with fits (pooled) | `figures/fig05_ci_pl_scatter.py` | `cdf_ci_pl_analysis.m`, `cdf_ci_pl_analysis_DS_ref.m` |
| Fig. 6 (a,b)     | 2         | Omni RMS DS CDF + DKW bands (pooled) | `figures/fig06_ds_cdf.py` | `cdf_ci_pl_analysis_DS_ref.m`, `CDF_7GHz_Combined.m` |
| Fig. 7 (a,b)     | 2         | Omni RMS ASA CDF + DKW bands (pooled) | `figures/fig07_asa_cdf.py` | `AS_CDF_Merged.m`, `cdf_ci_as_analysis.m` |
| Fig. 8 (a,b)     | 2         | Omni RMS ASD CDF + DKW bands (pooled) | `figures/fig08_asd_cdf.py` | `AS_CDF_Merged.m` |

## Tables

| Paper Table | Content | Python driver                        | MATLAB origin                         |
|-------------|---------|--------------------------------------|---------------------------------------|
| Table 1     | Literature survey (static)           | Not generated (static LaTeX table)    | None                                  |
| Table 2     | Metadata schema (static)             | Not generated (static LaTeX table)    | None                                  |
| Table 3     | NYU/USC metadata comparison (static) | Not generated (static LaTeX table)    | None                                  |
| Table 4     | Partial N1 @ 142 GHz                 | `figures/table04_N1_142.py` (pretty-print) | Provided as xlsx `OriginalNYU_pointData/142_UMi.xlsx` |
| Table 5     | Methodology comparison (static)      | Not generated (static LaTeX table)    | None                                  |
| Table 6     | Cross-processing RMSE                | `figures/table06_rmse.py`             | `calculate_AS_RMSE.m`, `verify_crossproc_stats.m` |
| Table 7     | Pooled stats summary                 | `figures/table07_pooled_stats.py`     | `cdf_ci_pl_analysis.m`, `compute_updated_stats.m` |
| Table 8     | Partial U3 @ 145.5 GHz               | `figures/table08_U3_145.py`           | `OriginalUSC-PointData/142_UMi_U3.xlsx` (read-through) |
| Table 9     | Partial U3 @ 6.75 GHz                | `figures/table09_U3_7.py`             | `7_UMi_U3.xlsx`                       |
| Table 10    | Partial N3 @ 142 GHz                 | `figures/table10_N3_142.py`           | `142_UMi_N3.xlsx`                     |
| Table 11    | Partial N3 @ 6.75 GHz                | `figures/table11_N3_7.py`             | `7_UMi_N3.xlsx`                       |

## Numerical claims (paper text) → reproduction sites

All text numerical claims are reproduced in `docs/numerical_parity.md`. They are computed in `figures/table07_pooled_stats.py` (PL / DS / AS means and CFI widths), `figures/table06_rmse.py` (RMSE values), and `figures/fig03_bland_altman_pl_ds.py` / `figures/fig04_bland_altman_as.py` (BA biases and SDs).

## Data flow

```
point-data xlsx/csv (N1, U1, N3, U3 tables — provided by institutions)
    │
    ├─> channel_analysis.io.load_point_data  (canonical long-format DataFrame)
    │
    ├─> channel_analysis.pl.ci_fit           (CI model: PLE, σ, CFI width)
    ├─> channel_analysis.ds.stats            (mean, CFI on DS)
    ├─> channel_analysis.as.gpp / fleury / nyu_rms  (AS definitions)
    ├─> channel_analysis.stats.bootstrap_ci / dkw_band
    │
    └─> channel_analysis.figures.*           (per-figure drivers)
           │
           └─> figures/python/*.{png,pdf}
```

## Unmapped / diagnostic MATLAB scripts (logged as informational only)

Scripts like `Diagnose_LobeProcessing_ThirdLobeValid.m`, `Test_Threshold_Effect.m`, `USC_Method_Visualization*.m`, and many `Verify_USC_Method_v*.m` variants are diagnostic tools used during development of the cross-processing protocol. They produce sanity-check plots not published in the paper; they are not reproduced in Python. Full list and disposition in `docs/issues_log.md`.

## Version disambiguation

- `Comprehensive_NYU_USC_Analysis_v7.m` is the authoritative version; v2–v6 are superseded (see `docs/code_conflicts.md`).
- Several `USCprocessing*.m` variants exist; the active paper variant for cross-processing is `USCprocessing_NYUth_Sp.m` (and its 7 GHz twin), confirmed by the NYU-threshold Sp naming.
- `D`-suffixed boundaryMPCs / lobeShaperCounter / SubPathPwrDirs / SecondaryStats_circ are the active versions.
