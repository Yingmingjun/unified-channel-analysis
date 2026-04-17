# Raw-to-Paper Pipeline Specification

**Scope.** This document is the blueprint for integrating two existing MATLAB
codebases (`D:/NYU-USC/Cross-Processing/` and
`D:/NaveedDipankarMingjunJorgeShare/`) into a single unified MATLAB tree at
`D:/unified-channel-analysis/matlab/` such that running
`matlab/run_all.m` reproduces — end-to-end, from raw measurement files —
every figure and data-generated table in
`D:/Joint-Point-Data-format-USC-NYU-Journal/main_final.tex`.

The goal is a one-shot build: raw PDP `.mat` files → Results `.mat` / `.csv` /
`.xlsx` → `paper_figures/*.m` → offline `.pdf` / `.png` / `.fig` identical to
the publication.

---

## 1. Input inventory

Four raw-data pipelines feed the paper. Each is identified below by
institution (NYU / USC), band (142 GHz / 6.75 GHz), raw data root, file
naming, expected MATLAB variable names, file count, disk footprint, and any
auxiliary antenna-pattern / calibration files consumed.

### 1.1 NYU 142 GHz (sub-THz) — directional-PDP pipeline

- **Raw data root:** `D:/NYU-USC/Cross-Processing/NYU/NYU_Data/142AlignedDataset/`
- **File pattern:** `142GHz_Outdoor_T<i>-R<j>.mat`  e.g. `142GHz_Outdoor_T1-R1.mat`
- **File count:** 27 (16 LOS + 11 NLOS)
- **Size on disk:** 4.9 GB
- **Inside each .mat:** a single cell-array variable (name varies, loaded via `fieldnames`); 10-column layout per row — one row per directional PDP pointing:
  - Col 1:  directional PDP (dB, dilated at 20 samples/ns)
  - Col 2:  TX ID
  - Col 3:  RX ID
  - Col 4:  measurement number
  - Col 5:  rotation number
  - Col 6:  AOD azimuth (deg)
  - Col 7:  AOD elevation (deg)
  - Col 8:  AOA azimuth (deg)
  - Col 9:  AOA elevation (deg)
  - Col 10: Environment ('LOS' / 'NLOS' / numeric flag)
- **Auxiliary inputs (absolute paths, read by the pipeline):**
  - `D:/NYU-USC/Cross-Processing/NYU/NYU_Data/140GHz_Outdoor_BaseStation.csv` — TX-power lookup (columns TX_ID, RX_ID, TX_Power) — 5.8 MB
  - `D:/NYU-USC/Cross-Processing/NYU/4.TCSL/AntennaPattern/HPLANE Pattern Data 261D-27.DAT` — 27 dBi horn H-plane pattern
  - `D:/NYU-USC/Cross-Processing/NYU/4.TCSL/AntennaPattern/EPLANE Pattern Data 261D-27.DAT` — 27 dBi horn E-plane pattern

### 1.2 USC 145.5 GHz (sub-THz) — H-matrix pipeline

- **Raw data root:**
  - LOS:  `D:/NYU-USC/Cross-Processing/USC/USC_Data/THz data PDP/PDP_NYU/LoS/`
  - NLOS: `D:/NYU-USC/Cross-Processing/USC/USC_Data/THz data PDP/PDP_NYU/NLoS/`
- **File pattern:** `PDP_R<i>_<dist>m (LOS|NLOS)_Microcellular.mat`  e.g. `PDP_R01_64.5m LOS_Microcellular.mat`
- **File count:** 26 (13 LOS + 13 NLOS)
- **Size on disk:** ~2.0 GB for the full `THz data PDP/PDP_NYU/` subtree
- **Inside each .mat:** variable `H` — complex 5-D array `[Nf=1001, N_aztx=13, N_eltx=3, N_azrx=36, N_elrx=3]` (frequency-domain channel, antenna gains already calibrated out)
- **Auxiliary inputs:**
  - `D:/NYU-USC/Cross-Processing/ProcessingUSC145GHzData/aziCut.mat`  — USC horn H-plane cut (181×2) — consumed for NYU-style lobe boundary expansion
  - `D:/NYU-USC/Cross-Processing/ProcessingUSC145GHzData/elevCut.mat` — USC horn E-plane cut (181×2)
- **Key frequency/geometry constants (hard-coded inside the script):** BW = 1 GHz, Nf = 1001, TX azimuth grid −60 : 10 : 60 deg, RX azimuth grid 0 : 10 : 350 deg, −1.95 dB correction factor for elevation summing, delay-gate 966.67 ns.

### 1.3 NYU 6.75 GHz (FR1C) — directional-PDP pipeline

- **Raw data root:** `D:/NYU-USC/Cross-Processing/NYU/NYU_Data/7AlignedDataset/`
- **File pattern:** `Data7Pack_TX<i>_RX<j>_Aligned.mat`  e.g. `Data7Pack_TX1_RX1_Aligned.mat`
- **File count:** 18 (mixed LOS / NLOS)
- **Size on disk:** 3.1 GB
- **Inside each .mat:** a single cell-array variable; 13-column layout per row:
  - Col 1:  denoised PDP (dB)
  - Cols 2–5: TX_ID, RX_ID, Meas#, Rot#
  - Col 6:  AOD azimuth, Col 7: AOD elevation
  - Col 8:  AOA azimuth, Col 9: AOA elevation
  - Col 10: Pr (received power)
  - Col 11: peak index
  - Col 12: Environment ('LOS' / 'NLOS')
  - Col 13: raw (un-denoised) PDP
- **Auxiliary inputs:**
  - `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7GHz_Outdoor (1).csv` — TX-power lookup — 3.1 MB
  - `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7_phi0_pd.mat`  — 15 dBi horn azimuth pattern
  - `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7_phi90_pd.mat` — 15 dBi horn elevation pattern

### 1.4 USC 6.75 GHz (FR1C) — H-matrix pipeline

Two raw datasets exist and are processed by *two different scripts*. Both must
be in the unified repo. Only `USC7GHz_NewData_Processing.m` writes
`USC7GHz_Full_Results.mat`, which is the file the paper-figure scripts
consume.

- **Old (8-point NLOS-only) raw root:** `D:/NYU-USC/Cross-Processing/USC/USC_Data/Midband (FR3) data PDP/Midband (FR3) data PDP/`
  - Pattern: `PDP_<dist>m_(NLOS|OLOS)_MIDBAND_<date>.mat`, 8 files, 112 MB
  - Variable inside: `H`, shape `[Nf=1001, 13, 36, 5]`
  - Consumed by: `USC7GHz_Method_Comparison.m` (8 NLOS locations)
- **New (6 LOS + 11 NLOS) raw root:** `D:/NYU-USC/Cross-Processing/ProcessingUSC7GHzData/All Points Full Band-20260226T000717Z-1-001/All Points Full Band/`
  - Subdirs `LOS Study/` (6 LOS files, `RX<i>_<date>.mat`, `H` shape `[12001, 13, 36, 5]`, 6–18 GHz band) and `OLOS Study/` (11 NLOS files, `RX<nn>_<dist>m_calib.mat`, `H` shape `[8001, 13, 36, 5]`, 6–14 GHz band)
  - Total 17 files, 706 MB
  - Variable inside: `H`
  - Consumed by: `USC7GHz_NewData_Processing.m` (full 17 locations — this is the authoritative FR1C USC pipeline for the paper)
- **Auxiliary inputs (antenna pattern):**
  - `D:/NYU-USC/Cross-Processing/ProcessingUSC7GHzData/Antenna Pattern-20260226T000652Z-1-001/Antenna Pattern/USC_Midband_Pattern.mat` — USC FR3 dual-pol horn 3-D pattern — 28 KB
  - (Fallback) `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7_phi0_pd.mat` — used by the *old* 8-point script only

### 1.5 Cross-processing point-data (Codebase A — N3 / U3 generators)

These scripts do **not** re-process raw PDPs end-to-end. They read the
opposite-institution's *already-formatted* point data (.mat summaries) and
re-emit an xlsx of summary statistics per TX-RX pair.

- **USCprocessNYU*_exp.m inputs (run at USC on NYU-sourced point data):**
  - `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/USC/USCformatNYUdata/*.mat` — 27 files (142 GHz, USCformat repackaging of the NYU 142 GHz dataset)
  - `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/USC/USCformatNYUdata7/*.mat` — 18 files (7 GHz)
  - Reference tables `OriginalNYU_pointData/142_UMi.xlsx`, `OriginalNYU_pointData/7_UMi.xlsx`
  - Outputs: `USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi_N3.xlsx`, `142_UMi_N3 RMSE.xlsx`, `7_UMi_N3.xlsx`, plus `USCprocessingResults*.mat`
- **NYUprocessUSC*.m inputs (run at NYU on USC-sourced point data):**
  - `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/NYU/NYUformatUSCdata/*.mat` — 27 files (145.5 GHz NYUformat of USC data)
  - `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/NYU/NYUformatUSCdata7/*.mat` — 18 files (FR1C)
  - Antenna-pattern mat `NYU/NYUprocessUSCdata/USC_antennaPattern/THz_3D_pattern_aver.mat` (plus `aziCut.mat`, `elevCut.mat`, `EPlanePattern7.dat`, `HPlanePattern7.dat`)
  - Reference tables in `OriginalUSC-PointData/` (the `142_UMi_U3.xlsx`, `142_UMi_U3-RMSE.xlsx`, `7_UMi_U3.xlsx` are also written by these scripts)
  - Outputs: `TCSL_USC145results*.mat` (2 thresholds × 2 bands), plus the `*_U3.xlsx` summary tables above.

**Combined raw-data footprint (Pipelines 1.1–1.4, excluding duplicates and zips):** **≈10.9 GB** — broken down as 4.9 + 3.1 + 2.0 + 0.82 GB. The formatted intermediates under `USCformatNYUdata*/` and `NYUformatUSCdata*/` add another ≈8 GB if bundled (they are TX-RX-packed cell-array `.mat` files and not strictly raw, but they are the *inputs* to the N3/U3 generators).

---

## 2. Processing pipeline (MATLAB)

Each of the four raw pipelines is a self-contained MATLAB script that `clear; clc; close all` at the top, reads the raw folder, and writes to a sibling `Results/` folder. The inter-script dependencies are via file I/O, not MATLAB workspace variables.

### 2.1 `NYU142GHz_Method_Comparison.m`

- **Location:** `D:/NYU-USC/Cross-Processing/ProcessingNYU142GHzData/NYU142GHz_Method_Comparison.m` (1824 lines — script + 13 local functions)
- **Inputs consumed:**
  - All 27 `142AlignedDataset/142GHz_Outdoor_T*-R*.mat`
  - `140GHz_Outdoor_BaseStation.csv` (TX-power table)
  - `4.TCSL/AntennaPattern/HPLANE Pattern Data 261D-27.DAT` + `EPLANE Pattern Data 261D-27.DAT`
- **Core computation (per TX-RX):**
  1. Parse `T<i>-R<j>` from filename, look up TX power in csv table (function `load_TX_power_table`, `get_TX_power`).
  2. Load `TRpdpSet` cell; extract environment from col 10.
  3. Apply **NYU per-directional PDP threshold** = max(peak_i − 25 dB, noise_i + 5 dB). Noise per-direction = `pow2db(mean(pdp_lin(end-5000:end)))` (last 250 ns at 20 samples/ns).
  4. Build AOA and AOD PAS (full 360 deg, 1-deg step; `generate_PAS` sums over directions with the same angle in linear).
  5. Omni PDPs two ways: **NYU SUM** (`compute_omni_NYU` — sum linear PDPs) and **USC perDelayMax** (`compute_omni_USC` — max linear PDP per delay bin).
  6. PL = Ptx + G_tx(27) + G_rx(27) − 10 log10(sum(OmniPDP)).
  7. RMS DS via `compute_RMS_DS` (standard E[τ²]−E[τ]²).
  8. Angular spreads: USC method (`compute_AS_USC` — no threshold, circ_std 3GPP sqrt(−2 ln R)) and NYU method (`compute_AS_NYU` — 10/15/20 dB PAS threshold + HPBW=8° lobe detection + antenna-pattern boundary expansion following `boundaryMPCsD.m` logic, then 3GPP formula).
- **Outputs written to `ProcessingNYU142GHzData/Results/`:**
  - `all_comparison_results.mat` — struct `results` (27×N per-location), struct `pas_store` (first LOS + first NLOS), `config`, `params`.  [331 KB]
  - `NYU142GHz_Method_Comparison_Results.csv` — `T_all` table with PL_NYU_SUM_dB, PL_USC_perDelayMax_dB, DS_NYU_SUM_ns, DS_USC_perDelayMax_ns, ASA_NYU_10/15/20dB, ASA_USC, ASD_* (same). [8 KB]
  - `NYU142GHz_Method_Comparison_Results.xlsx` — same table + 4 summary sheets (All_Results, LOS_Summary, NLOS_Summary, Overall_Summary, Method_Comparison). [14 KB]
  - 9 figures (`Figures/Fig1_*.pdf/png/fig` … `Fig9_BlandAltman.pdf/png/fig`) — not consumed downstream by the paper, but left intact.
- **Path dependencies:** none (all 13 helper functions are local to this file — `apply_NYU_PDP_threshold`, `generate_PAS`, `compute_omni_NYU/USC`, `compute_AS_NYU/USC`, `compute_AS_3GPP`, `interpolate_PAS_NYU`, `load_TX_power_table`, `get_TX_power`, `load_antenna_pattern`, `compute_RMS_DS`, `saveFigure`).

### 2.2 `USC142GHz_Method_Comparison_Full.m`

- **Location:** `D:/NYU-USC/Cross-Processing/ProcessingUSC145GHzData/USC142GHz_Method_Comparison_Full.m` (1495 lines)
- **Inputs consumed:**
  - All 26 H-matrix files under `USC/USC_Data/THz data PDP/PDP_NYU/LoS/` and `…/NLoS/`
  - `ProcessingUSC145GHzData/aziCut.mat` (for NYU-style lobe expansion)
- **Core computation (per location):**
  1. Load `H` — shape [1001, 13, 3, 36, 3].
  2. Hann window the frequency axis (normalized so RMS=1), then IFFT along dim 1 → `h_delay`. PDP_dir = |h_delay|².
  3. Per-direction noise floor via `noise_floor_calc_v2`; global threshold = `max(all noise) + 12 dB`. Zero out PDP samples below threshold.
  4. **NYU SUM omni:** sum over `[N_aztx N_eltx N_azrx N_elrx]`; apply −1.95 dB correction; circshift by `-round((d_LOS-5)/0.3)` if `d_LOS >= 5`; apply delay-gate `t <= (d(end)-10+d_LOS)/c`.
  5. **USC perDelayMax omni:** sum RxEl → max RxAz → sum TxEl → max TxAz; same correction / circshift / gate (LOS only applies −1.95 dB).
  6. PL = −10·log10(Σ PDP_omni)  — calibrated H already.
  7. RMS DS via NYU's `computeDSonMPC` (dB power, ns delay, standard formula) on the post-threshold, post-gate omni PDP.
  8. AS: helper `compute_AS_from_PDP` collapses PDP_dir to AOA / AOD PAS then calls NYU and USC AS routines (same HPBW=10° grid, same antenna pattern).
- **Outputs written to `ProcessingUSC145GHzData/Results/`:**
  - `USC145GHz_Full_Results.mat` — `results` struct (26 × N), `params`, `config`. [51 KB]
  - `USC145GHz_Full_Results.csv`  [7 KB]
  - `USC145GHz_Full_Results.xlsx` (All_Results + summary sheets) [14 KB]
  - Figures in sibling `Figures/` — not consumed by paper.
- **Path dependencies:** helper `noise_floor_calc_v2` is a file on disk (`ProcessingUSC145GHzData/noise_floor_calc_v2.m` is absent from that folder but is available in many sibling dirs; the script calls it at line ~351 and must have it on the path — see §4). Similarly `computeDSonMPC` is resolved via MATLAB path (exists in `NYU/4.TCSL/`, `USC/USCprocessNYUdata/` under that name).

### 2.3 `NYU7GHz_Method_Comparison.m`

- **Location:** `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/NYU7GHz_Method_Comparison.m` (1795 lines)
- **Inputs consumed:**
  - All 18 `7AlignedDataset/Data7Pack_TX*_RX*_Aligned.mat` (NYU-side dilation factor auto-detected — `detect_dilation_factor`)
  - `7GHz_Outdoor (1).csv` (TX-power + distance table)
  - `7_phi0_pd.mat`, `7_phi90_pd.mat` (antenna cuts in .mat not .DAT)
- **Core computation (per TX-RX):** same as §2.1 but the script runs the full pipeline *twice per location* — once under the NYU PDP threshold (per-dir max(pk−25, noise+5)) and once under the USC PDP threshold (per-dir P25 + 5.41 dB, global max + 12 dB). The resulting `results` struct therefore has 24 numeric fields per location (2 thresholds × {PL_SUM, PL_pDM, DS_SUM, DS_pDM, ASA_N10/15/20/U, ASD_N10/15/20/U}).
- **Outputs written to `ProcessingNYU7GHzData/Results/`:**
  - `all_comparison_results.mat` — identical struct name to the 142 GHz pipeline, but the schema is the dual-threshold one above. [525 KB]
  - `NYU7GHz_Method_Comparison_Results.csv` / `.xlsx` [8 / 14 KB]
  - Figures in sibling `Figures/`.
- **Path dependencies:** local functions only. Antenna patterns loaded via local `load_antenna_pattern_mat`.

### 2.4 `USC7GHz_NewData_Processing.m` (authoritative) and `USC7GHz_Method_Comparison.m` (legacy)

- **Primary:** `ProcessingUSC7GHzData/USC7GHz_NewData_Processing.m` (1001 lines) — processes the 17-point dataset (6 LOS + 11 NLOS) that the paper uses.
- **Legacy:** `ProcessingUSC7GHzData/USC7GHz_Method_Comparison.m` (1347 lines) — older 8-NLOS-only variant; kept for regression.
- **Inputs consumed (primary):**
  - 6 LOS H files in `All Points Full Band/LOS Study/RX<i>_07-12-2024.mat` (H is [12001, 13, 36, 5])
  - 11 NLOS H files in `All Points Full Band/OLOS Study/RX<nn>_<dist>m_calib.mat` (H is [8001, 13, 36, 5])
  - `Antenna Pattern-20260226T000652Z-1-001/Antenna Pattern/USC_Midband_Pattern.mat`
- **Core computation (per location):**
  1. Load `H`; extract indices 251:1251 to get the 6.25–7.25 GHz 1001-point slice.
  2. Hann window + IFFT + |·|² → PDP_dir [Nf, 13, 36, 5] (note the 4-D layout: no TX elevation).
  3. USC noise threshold = max(per-dir noise_floor_calc_v2) + 12 dB, capped so DR ≤ 22 dB.
  4. `flip(PDP_dir, 2)` — TX-azimuth flip for USC convention.
  5. Apply 3.7 dB empirical antenna-gain correction (FR3 value, vs. 1.95 dB for sub-THz).
  6. NYU SUM omni = Σ all axes; USC perDelayMax omni = Sum RxEl → Max RxAz → Max TxAz; both circshifted by `-round((d_LOS-50)/0.3)` if `d_LOS >= 50`; delay-gated.
  7. PL = −10·log10(ΣPDP_omni).
  8. DS via `computeDSonMPC` on thresholded omni PDPs.
  9. AS per §2.2, but lobe-expansion uses the USC antenna pattern (not NYU's 7 GHz pattern).
- **Outputs written to `ProcessingUSC7GHzData/Results/`:**
  - `USC7GHz_Full_Results.mat` — 17×N `results` struct — **this is the file the paper figures load.** [40 KB]
  - `USC7GHz_NewData_Results.csv` / `.xlsx` [5 / 7 KB]
  - `USC7GHz_Method_Comparison_Results.csv` / `.xlsx` (written by the legacy script) [2.6 / 7.5 KB]
  - Figures in sibling `Figures/`.

### 2.5 `USCprocessNYU142M_exp.m` and `USCprocessNYU7M_exp.m` (Codebase A N3 generators)

- **Location:** `D:/NaveedDipankarMingjunJorgeShare/.../USC/USCprocessNYUdata/`
- **Inputs:** `USC/USCformatNYUdata/USCformat_142GHz_*.mat` (27 files) for the 142 GHz twin; `USC/USCformatNYUdata7/USCformat_LOS|NLOS_Data7Pack_*.mat` (18 files) for the 7 GHz twin. Reference xlsx `OriginalNYU_pointData/142_UMi.xlsx` and `7_UMi.xlsx` supply PL / DS reference values for validation.
- **Core computation:** call `USCprocessing_NYUth_Sp` (or `USCprocessing_NYUth_Sp7`) per TX-RX pair — this is USC's TCSL-style processor applied with NYU's thresholding. Writes a 12-column cell array per pair: omni-PDP, omni-PL, omni-DS, omni-ASA, omni-ZSA, omni-ASD, omni-ZSD, noise-threshold, un-dilated omni-PDP.
- **Outputs:** `USCprocessingResults_NYUth_Sp2.mat` (and `…7GHz_NYUth_Sp.mat` for 7 GHz). Combined with the reference xlsx, the scripts generate the `142_UMi_N3.xlsx` / `7_UMi_N3.xlsx` point-data summary tables that the paper figures consume (the `N3` column is USC-processed NYU data).
- **Path dependencies (all live in the same folder — `USC/USCprocessNYUdata/`):** `USCprocessing_NYUth_Sp.m`, `USCprocessing_NYUth_Sp7.m`, `natsort.m`, `natsortfiles.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`, `rrc_window.m`, `Num_tapsv5.m`, `ASfleury.m`, `bland_altman_analysis.m`, `cdf_ci_pl_analysis.m`.

### 2.6 `NYUprocessUSC145.m`, `NYUprocessUSC145_USCthresh.m`, `NYUprocessUSC7.m`, `NYUprocessUSC7_USCthresh.m` (Codebase A U3 generators)

- **Location:** `D:/NaveedDipankarMingjunJorgeShare/.../NYU/NYUprocessUSCdata/`
- **Inputs:** `NYU/NYUformatUSCdata/NYUformat_PDP_R*_Microcellular.mat` (27 files, 145 GHz); `NYU/NYUformatUSCdata7/NYUformat_PDP_*_MIDBAND_*.mat` (18 files, 6.75 GHz). Antenna pattern `USC_antennaPattern/THz_3D_pattern_aver.mat` (+ `aziCut.mat`, `elevCut.mat`, `EPlanePattern7.dat`, `HPlanePattern7.dat`). Each file's first row col 10 contains environment.
- **Core computation:** NYU's TCSL-style processor (`PASgenerator` → `lobeShaperCounterD` → `boundaryMPCsD` → `SubPathPwrDirs(D)` → `clusterSearch` → `SecondaryStats_circD`), but the PDP-threshold step uses NYU's per-dir max(pk−25, noise+5). The `_USCthresh.m` variants use USC's P25+5.41 dB per-dir / global+12 dB threshold instead. PDPs are in linear scale; antenna gains calibrated out; empirical correction 1.95 dB.
- **Outputs:** `TCSL_USC145results.mat`, `TCSL_USC145results_NYUth.mat`, `TCSL_USC145results_USCth.mat`, and 7 GHz twins `TCSL_USC7results_NYUth.mat`, `TCSL_USC7results_USCth.mat` / `_NYUth2.mat` / `_USCth2.mat`. Combined with reference xlsx in `OriginalUSC-PointData/`, these write `142_UMi_U3.xlsx`, `142_UMi_U3-RMSE.xlsx`, `7_UMi_U3.xlsx` (the point-data summary tables the paper figures consume — the `U3` column is NYU-processed USC data). Also emit `PL_comparison_LOS.csv` / `PL_comparison_NLOS.csv`, `usc_microcellular_{LOS,NLOS}_metrics{,7}.csv`.
- **Path dependencies:** all utilities live in the same `NYU/NYUprocessUSCdata/` folder — the `D`-suffixed variants are the active ones: `boundaryMPCsD.m`, `lobeShaperCounterD.m`, `SubPathPwrDirs.m`, `SubPathPwrDirsD.m`, `SecondaryStats_circD.m`, `clusterSearch.m`, `computeDSonMPC.m`, `computeDirDS.m`, `compute_angular_spread.m`, `getdirRMSDS.m`, `meanSLangles.m`, `mmsefit.m`, `PASgenerator.m`, `PASplotter.m`, `PDPdenoise.m`, `circ_mean.m`, `circ_r.m`, `circ_std.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`, `natsort.m`, `natsortfiles.m`. Supporting `temp_statTable.mat` (182 KB) is loaded at start of 145 GHz script.

---

## 3. Figure generation pipeline (MATLAB)

The paper has 8 parent figures (Fig. 1 is a TikZ flow diagram only; Fig. 2 is a
pair of raw directional-PDP snapshots — neither is regenerated from point
data). Data-driven figures are Fig. 3–Fig. 8 and data-driven tables are Table
6 and Table 7.

| Paper element          | Authoritative MATLAB script (absolute path)                                                                              | Inputs consumed                                                                                                                                                      | Outputs written                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Fig. 3 (a–d)** BA PL/DS sub-THz + 6.75 GHz | `D:/NYU-USC/Cross-Processing/Plot_BlandAltman_PL_DS_AS.m`                                                                         | `Processing{NYU142,USC145}GHzData/Results/*_Results.xlsx` for sub-THz; analogous 7 GHz xlsx for the lower band (hard-coded to read from xlsx)                   | `BlandAltman_Figures/BlandAltman_PL.{fig,png,pdf}`, `BlandAltman_DS.{fig,png,pdf}`. Per-panel stats printed to stdout.                                              |
| Alt BA PL/DS generator (xlsx-based, also used during drafting) | `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/bland_altman_analysis.m`                                                 | `142_UMi_N3.xlsx`, `142_UMi_U3.xlsx` (uses the two-row-header "FinalTable" sheet, reads `NYU thres` / `NYU orig. (N1)` / `USC thres` / `USC orig. (U1)` columns) | Figures to MATLAB window (no disk save). Used to validate bias/SD values.                                                                                          |
| **Fig. 4 (a–d)** BA ASA/ASD sub-THz + 6.75 GHz | `D:/NYU-USC/Cross-Processing/BA_AS_Merged.m` (function `generate_ba_figure`)                                              | `ProcessingNYU142GHzData/Results/all_comparison_results.mat`, `ProcessingUSC145GHzData/Results/USC145GHz_Full_Results.mat`, `ProcessingNYU7GHzData/Results/all_comparison_results.mat`, `ProcessingUSC7GHzData/Results/USC7GHz_Full_Results.mat` | `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/BA_ASA.{jpg,png,fig}`, `BA_ASD.{jpg,png,fig}`, `BA_ASA7.{jpg,png,fig}`, `BA_ASD7.{jpg,png,fig}`.                 |
| **Fig. 5 (a–b)** CI PL scatter (sub-THz, 6.75 GHz) | `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/cdf_ci_pl_analysis.m` (function `plot_ci_models`)       | `USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi_N3.xlsx`, `NYU/NYUprocessUSCdata/OriginalUSC-PointData/142_UMi_U3.xlsx` (hard-coded C:\ path — see §6)     | Figures to MATLAB window only. Final published PDFs `PLcombinedPlot.jpg`, `PLcombinedPlot7.jpg` are hand-saved / merged (see `docs/authoritative_figure_scripts.md`). |
| Paired ref script (DS + CI merge) | `D:/NYU-USC/Cross-Processing/cdf_ci_pl_analysis_DS_ref.m`                                                                        | Same N3/U3 xlsx plus DS-specific overlays                                                                                                                           | Used for reference / style-matching for Fig. 5 and Fig. 6.                                                                                                         |
| **Fig. 6 (a–b)** Omni RMS DS CDF sub-THz + 6.75 GHz | `D:/NYU-USC/Cross-Processing/cdf_ci_pl_analysis_DS_ref.m` (produces the merged-style DS figures)                          | `142_UMi_N3.xlsx`, `142_UMi_U3.xlsx`, `7_UMi_N3.xlsx`, `7_UMi_U3.xlsx` (via `load_stats_table` with `FinalTable` sheet, two-row header)                            | `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/OmniDS_merged.{jpg,fig}`, `OmniDS_merged7.{jpg,fig}`                                                             |
| **Fig. 7 (a–b)** Omni RMS ASA CDF sub-THz + 6.75 GHz | `D:/NYU-USC/Cross-Processing/AS_CDF_Merged.m` (function `generate_as_cdf_figure`)                                         | Same four `Results/*.mat` files as Fig. 4                                                                                                                           | `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/OmniASA_merged.{jpg,fig}`, `OmniASA_merged7.{jpg,fig}`                                                            |
| **Fig. 8 (a–b)** Omni RMS ASD CDF sub-THz + 6.75 GHz | `D:/NYU-USC/Cross-Processing/AS_CDF_Merged.m`                                                                              | Same                                                                                                                                                                | `OmniASD_merged.{jpg,fig}`, `OmniASD_merged7.{jpg,fig}`                                                                                                               |
| **Table 6** Cross-processing RMSE | `D:/NYU-USC/Cross-Processing/Generate_AS_CrossProcessing_Table.m` (referenced by `docs/paper_to_code_mapping.md` as `calculate_AS_RMSE.m` / `verify_crossproc_stats.m`) | Same four Results `.mat` files — computes RMSE(N3 − N1) and RMSE(U3 − U1) for PL, DS, ASA, ASD | Prints to stdout; tee'd into `Table6_rmse.csv` by the unified driver.                                                                                              |
| **Table 7** Pooled stats summary (means, CFI widths) | `cdf_ci_pl_analysis.m` (bootstrap_ci_summary + bootstrap_logstat_summary) + `cdf_ci_pl_analysis_DS_ref.m` (log-domain means) | The four N3/U3 xlsx files                                                                                                                                          | Prints 95% CIs / widths for n, σ, linear-domain DS/ASA/ASD means to stdout; tee'd to `Table7_pooled_stats.csv`.                                                     |

Fig. 1 (TikZ flow diagram `CrossProcessingDiag_rev.pdf`) and Fig. 2
(`USC_dirPDP.jpg`, `NYU_dirPDP.jpg`) are **paper-source** PDFs/JPGs. They are
passthroughs — copied verbatim into `figures/matlab/` by `run_all.m` because
there is no point-data route to recreate them.

---

## 4. Minimum file set to copy into the unified repo

Every file below is **required** to bring `run_all.m` through the full
raw-to-figure pipeline offline. Paths are given as source → suggested
destination under `D:/unified-channel-analysis/`.

### 4.1 Raw datasets (large; staged under `data/raw/`)

| Source (absolute)                                                                                                                                | Destination                                      | Size   | File count |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ | ------ | ---------- |
| `D:/NYU-USC/Cross-Processing/NYU/NYU_Data/142AlignedDataset/`                                                                                    | `data/raw/nyu_142/142AlignedDataset/`            | 4.9 GB | 27         |
| `D:/NYU-USC/Cross-Processing/NYU/NYU_Data/7AlignedDataset/`                                                                                      | `data/raw/nyu_7/7AlignedDataset/`                | 3.1 GB | 18         |
| `D:/NYU-USC/Cross-Processing/NYU/NYU_Data/140GHz_Outdoor_BaseStation.csv`                                                                        | `data/raw/nyu_142/`                              | 5.8 MB | 1          |
| `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7GHz_Outdoor (1).csv`                                                                         | `data/raw/nyu_7/`                                | 3.1 MB | 1          |
| `D:/NYU-USC/Cross-Processing/USC/USC_Data/THz data PDP/PDP_NYU/`                                                                                 | `data/raw/usc_145/THz_data_PDP/PDP_NYU/`         | 2.0 GB | 26+readme  |
| `D:/NYU-USC/Cross-Processing/USC/USC_Data/Midband (FR3) data PDP/Midband (FR3) data PDP/`                                                         | `data/raw/usc_7_old/Midband_FR3_PDP/`            | 112 MB | 8+readme   |
| `D:/NYU-USC/Cross-Processing/ProcessingUSC7GHzData/All Points Full Band-20260226T000717Z-1-001/All Points Full Band/`                             | `data/raw/usc_7_new/All_Points_Full_Band/`       | 706 MB | 17         |

**Raw-only subtotal:** ~10.9 GB.

### 4.2 Antenna patterns and calibration files

| Source (absolute)                                                                                                                                 | Destination                                   | Size  |
| ------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | ----- |
| `D:/NYU-USC/Cross-Processing/NYU/4.TCSL/AntennaPattern/HPLANE Pattern Data 261D-27.DAT`                                                           | `data/antenna_patterns/nyu_142/`              | 6 KB  |
| `D:/NYU-USC/Cross-Processing/NYU/4.TCSL/AntennaPattern/EPLANE Pattern Data 261D-27.DAT`                                                           | `data/antenna_patterns/nyu_142/`              | 6 KB  |
| `D:/NYU-USC/Cross-Processing/ProcessingUSC145GHzData/aziCut.mat`                                                                                  | `data/antenna_patterns/usc_145/`              | 2 KB  |
| `D:/NYU-USC/Cross-Processing/ProcessingUSC145GHzData/elevCut.mat`                                                                                 | `data/antenna_patterns/usc_145/`              | 1 KB  |
| `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7_phi0_pd.mat`                                                                                 | `data/antenna_patterns/nyu_7/`                | 2 KB  |
| `D:/NYU-USC/Cross-Processing/ProcessingNYU7GHzData/7_phi90_pd.mat`                                                                                | `data/antenna_patterns/nyu_7/`                | 2 KB  |
| `D:/NYU-USC/Cross-Processing/ProcessingUSC7GHzData/Antenna Pattern-20260226T000652Z-1-001/Antenna Pattern/USC_Midband_Pattern.mat`                | `data/antenna_patterns/usc_7/`                | 28 KB |
| `D:/NaveedDipankarMingjunJorgeShare/.../NYU/NYUprocessUSCdata/USC_antennaPattern/THz_3D_pattern_aver.mat`                                         | `data/antenna_patterns/usc_145/`              | varies|

### 4.3 Codebase B raw-processing pipelines (`.m` scripts)

Copy the following four scripts **verbatim** into `matlab/processing/<band>/`:

| Source script                                                                                                      | Destination                                               |
| ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------- |
| `ProcessingNYU142GHzData/NYU142GHz_Method_Comparison.m`                                                            | `matlab/processing/nyu_142/`                              |
| `ProcessingUSC145GHzData/USC142GHz_Method_Comparison_Full.m`                                                       | `matlab/processing/usc_145/`                              |
| `ProcessingNYU7GHzData/NYU7GHz_Method_Comparison.m`                                                                | `matlab/processing/nyu_7/`                                |
| `ProcessingUSC7GHzData/USC7GHz_NewData_Processing.m`                                                               | `matlab/processing/usc_7/` (primary)                       |
| `ProcessingUSC7GHzData/USC7GHz_Method_Comparison.m`                                                                | `matlab/processing/usc_7/legacy/` (kept for regression)    |

### 4.4 Codebase A N3/U3 point-data generators and supporting utilities

Bundle these subtrees verbatim under `matlab/processing_xproc/`:

- `USC/USCprocessNYUdata/` (all 30+ `.m` files — including `USCprocessNYU142M_exp.m`, `USCprocessNYU7M_exp.m`, `USCprocessing_NYUth_Sp.m`, `USCprocessing_NYUth_Sp7.m`, `ASfleury.m`, `Num_tapsv5.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`, `rrc_window.m`, `natsort.m`, `natsortfiles.m`, `bland_altman_analysis.m`, `cdf_ci_pl_analysis.m`, plus all `*.mat` / `*.xlsx` in `OriginalNYU_pointData/` and `NYU_Data_thresholded/` — the last is 1.3 GB of pre-thresholded intermediates used by the NYUth_Sp variants and required for reproducibility)
- `NYU/NYUprocessUSCdata/` (all 25+ `.m` files — `NYUprocessUSC145.m`, `NYUprocessUSC145_USCthresh.m`, `NYUprocessUSC7.m`, `NYUprocessUSC7_USCthresh.m`, `PASgenerator.m`, `PASplotter.m`, `PDPdenoise.m`, `SubPathPwrDirs.m`, `SubPathPwrDirsD.m`, `SecondaryStats_circD.m`, `clusterSearch.m`, `boundaryMPCsD.m`, `lobeShaperCounterD.m`, `computeDSonMPC.m`, `computeDirDS.m`, `compute_angular_spread.m`, `getdirRMSDS.m`, `meanSLangles.m`, `mmsefit.m`, `circ_mean.m`, `circ_r.m`, `circ_std.m`, `natsort.m`, `natsortfiles.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`, `USC_antennaPattern/`, `TCSL_USC145results*.mat`, `TCSL_USC7results*.mat`, `temp_statTable.mat`, `PL_comparison_*.csv`, plus `OriginalUSC-PointData/` reference xlsx and CSV metric files).
- `USC/USCformatNYUdata/` (27 `.mat` files, 142 GHz, ~4 GB if kept)
- `USC/USCformatNYUdata7/` (18 `.mat` files, 7 GHz)
- `NYU/NYUformatUSCdata/` (27 `.mat` files, 145 GHz)
- `NYU/NYUformatUSCdata7/` + `NYUformatUSCdata7backup/` (18 + 8 `.mat` files)

Utility fan-in (also available in `D:/NYU-USC/Cross-Processing/NYU/4.TCSL/`
which is the "canonical" USC-TCSL toolbox):
- `4.TCSL/*.m` — `TCSL142D.m`, `ProcessingUSCwith_NYU_TCSL142D.m`, `SecondaryStats*.m`, `Count_TC_SP*.m`, `CDFplots.m`, `Kfactor.m`, `angularSpread.m`, `chi2gof_trial.m`, `test.m`. Also `TCSL142_Results_v1.mat`. Ship under `matlab/lib_tcsl/`.
- `USC/Codes4Reference/` — `NYU_Code_Milcom/` subtree (optional; reference-only).

### 4.5 Paper-figure scripts

Copy verbatim into `matlab/paper_figures/`:

| Source                                                                                             | Destination                                   |
| -------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `D:/NYU-USC/Cross-Processing/AS_CDF_Merged.m`                                                      | `matlab/paper_figures/AS_CDF_Merged.m`         |
| `D:/NYU-USC/Cross-Processing/BA_AS_Merged.m`                                                       | `matlab/paper_figures/BA_AS_Merged.m`          |
| `D:/NYU-USC/Cross-Processing/Plot_BlandAltman_PL_DS_AS.m`                                          | `matlab/paper_figures/Plot_BlandAltman_PL_DS_AS.m` |
| `D:/NYU-USC/Cross-Processing/cdf_ci_pl_analysis_DS_ref.m`                                          | `matlab/paper_figures/cdf_ci_pl_analysis_DS_ref.m` |
| `D:/NaveedDipankarMingjunJorgeShare/.../cdf_ci_pl_analysis.m`                                      | `matlab/paper_figures/cdf_ci_pl_analysis.m`    |
| `D:/NaveedDipankarMingjunJorgeShare/.../bland_altman_analysis.m`                                   | `matlab/paper_figures/bland_altman_analysis.m` |
| `D:/NYU-USC/Cross-Processing/Generate_AS_CrossProcessing_Table.m`                                  | `matlab/paper_figures/Generate_AS_CrossProcessing_Table.m` |

Pre-existing passthrough figure sources to copy into `matlab/paper_figures_passthrough/`:
- `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/CrossProcessingDiag_rev.pdf` (Fig. 1)
- `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/USC_dirPDP.jpg`, `NYU_dirPDP.jpg` (Fig. 2a/b)

### 4.6 MATLAB file totals

- **Raw-processing scripts:** 5 (§4.3)
- **N3/U3 cross-processing drivers + utilities:** ~60 `.m` files in `USCprocessNYUdata/` and `NYUprocessUSCdata/` (every file in those directories is either a function callee or a diagnostic — the safest course is to copy the directories wholesale)
- **TCSL-toolbox fan-in (`4.TCSL/`):** ~35 `.m` files + 1 large `.mat`
- **Paper-figure scripts:** 7 (§4.5)
- **Existing unified-repo Python-parity helpers under `matlab/lib/`:** 11 (`angular_spread_3gpp.m`, `angular_spread_fleury.m`, `bland_altman.m`, `bootstrap_ci.m`, `ci_pl_fit.m`, `dkw_band.m`, `fleury_to_gpp.m`, `load_point_data.m`, `lognormal_stats.m`, `rms_delay_spread.m`, `save_figure.m`) — retained.

**Grand total .m count for a self-contained unified repo:** **≈120 `.m` files**
(5 + 60 + 35 + 7 + 11 existing + ~2 orchestration files described in §5). Plus
~80 intermediate `.mat` / `.xlsx` / `.csv` / `.dat` / `.fig` files.

### 4.7 Result intermediates (generated, not copied)

The following files are *produced* by §2 and consumed by §3. They do not need
to be bundled if `run_all.m` regenerates them from raw; but shipping them as
pre-baked fallbacks lets users skip the 10.9 GB raw data and still reproduce
figures:

- `matlab/results/nyu_142/all_comparison_results.mat` + `.csv` + `.xlsx`
- `matlab/results/usc_145/USC145GHz_Full_Results.mat` + `.csv` + `.xlsx`
- `matlab/results/nyu_7/all_comparison_results.mat` + `.csv` + `.xlsx`
- `matlab/results/usc_7/USC7GHz_Full_Results.mat` + `USC7GHz_NewData_Results.csv` + `.xlsx`
- `matlab/results/point_data/142_UMi_N3.xlsx`, `7_UMi_N3.xlsx`, `142_UMi_U3.xlsx`, `7_UMi_U3.xlsx`, `142_UMi_U3-RMSE.xlsx`, `142_UMi_N3 RMSE.xlsx`

---

## 5. Proposed unified layout

```
D:/unified-channel-analysis/
├── CITATION.cff, LICENSE, LICENSE_FULL.txt, README.md, ... (existing)
├── data/
│   ├── raw/
│   │   ├── nyu_142/142AlignedDataset/*.mat                  (§4.1)
│   │   ├── nyu_142/140GHz_Outdoor_BaseStation.csv
│   │   ├── nyu_7/7AlignedDataset/*.mat
│   │   ├── nyu_7/7GHz_Outdoor (1).csv
│   │   ├── usc_145/THz_data_PDP/PDP_NYU/{LoS,NLoS}/*.mat
│   │   ├── usc_7_old/Midband_FR3_PDP/*.mat                  (legacy)
│   │   └── usc_7_new/All_Points_Full_Band/{LOS Study,OLOS Study}/*.mat
│   ├── antenna_patterns/
│   │   ├── nyu_142/{HPLANE,EPLANE} Pattern Data 261D-27.DAT
│   │   ├── nyu_7/7_phi{0,90}_pd.mat
│   │   ├── usc_145/{aziCut,elevCut,THz_3D_pattern_aver}.mat
│   │   └── usc_7/USC_Midband_Pattern.mat
│   ├── formatted_intermediates/       (§4.4)
│   │   ├── USCformatNYUdata/   27 .mat (142 GHz, USCformat)
│   │   ├── USCformatNYUdata7/  18 .mat (7 GHz)
│   │   ├── NYUformatUSCdata/   27 .mat (145 GHz, NYUformat)
│   │   └── NYUformatUSCdata7/  18 .mat (7 GHz)
│   ├── point_data/                   (existing — used by Python port too)
│   │   ├── N1_142_UMi.xlsx, N1_7_UMi.xlsx    (= N3 xlsx, NYU-orig column)
│   │   ├── N3_142_UMi.xlsx, N3_7_UMi.xlsx
│   │   ├── U3_142_UMi.xlsx, U3_7_UMi.xlsx
│   │   └── README.md
│   └── paper_reference/              (existing)
│
├── matlab/
│   ├── run_all.m                     ← orchestrator (see below)
│   ├── config/
│   │   ├── paths.m                   ← extended to expose every RAW/INTER/RESULT/FIG root
│   │   └── plot_style.m
│   ├── lib/                          ← existing: load_point_data, bootstrap_ci, …
│   ├── lib_tcsl/                     ← 4.TCSL utilities (ship from Cross-Processing/NYU/4.TCSL/)
│   ├── processing/
│   │   ├── nyu_142/NYU142GHz_Method_Comparison.m + Results/, Figures/
│   │   ├── usc_145/USC142GHz_Method_Comparison_Full.m + Results/, Figures/
│   │   ├── nyu_7/NYU7GHz_Method_Comparison.m + Results/, Figures/
│   │   └── usc_7/USC7GHz_NewData_Processing.m + legacy/USC7GHz_Method_Comparison.m + Results/, Figures/
│   ├── processing_xproc/             ← Codebase A (N3 / U3 generators)
│   │   ├── USCprocessNYUdata/ (verbatim, 30+ .m + .mat + xlsx)
│   │   ├── NYUprocessUSCdata/ (verbatim, 25+ .m + .mat + xlsx)
│   │   ├── USC2NYU.m, NYU2USC.m (naming converters at the roots)
│   │   └── README_xproc.md
│   ├── paper_figures/                ← VERBATIM: AS_CDF_Merged, BA_AS_Merged,
│   │   ├── AS_CDF_Merged.m                      Plot_BlandAltman_PL_DS_AS,
│   │   ├── BA_AS_Merged.m                       cdf_ci_pl_analysis_DS_ref,
│   │   ├── Plot_BlandAltman_PL_DS_AS.m          cdf_ci_pl_analysis,
│   │   ├── cdf_ci_pl_analysis_DS_ref.m          bland_altman_analysis,
│   │   ├── cdf_ci_pl_analysis.m                 Generate_AS_CrossProcessing_Table
│   │   ├── bland_altman_analysis.m
│   │   └── Generate_AS_CrossProcessing_Table.m
│   ├── paper_figures_passthrough/
│   │   ├── CrossProcessingDiag_rev.pdf  (Fig. 1)
│   │   ├── USC_dirPDP.jpg, NYU_dirPDP.jpg (Fig. 2)
│   │   └── copy_passthrough_figures.m
│   └── figures/                      ← existing: fig03 … fig08 + table drivers
│
├── figures/
│   ├── matlab/                       ← all outputs of matlab/run_all.m
│   └── python/                       ← parallel Python outputs (already present)
│
├── python/, environment.yml, requirements.txt   (existing Python reference port)
└── docs/
    ├── raw_to_paper_pipeline_spec.md (this document)
    ├── architecture.md, code_inventory.md, …  (existing)
```

### 5.1 `config/paths.m` additions

Extend the existing struct returned by `paths()` with every root each script
needs. Proposed fields:

```matlab
% Inside config/paths.m (extend existing struct P):
P.repo_root   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
% ---- raw data roots ----
P.raw_nyu_142     = fullfile(P.repo_root, 'data/raw/nyu_142/142AlignedDataset');
P.raw_nyu_142_csv = fullfile(P.repo_root, 'data/raw/nyu_142/140GHz_Outdoor_BaseStation.csv');
P.raw_nyu_7       = fullfile(P.repo_root, 'data/raw/nyu_7/7AlignedDataset');
P.raw_nyu_7_csv   = fullfile(P.repo_root, 'data/raw/nyu_7/7GHz_Outdoor (1).csv');
P.raw_usc_145_los  = fullfile(P.repo_root, 'data/raw/usc_145/THz_data_PDP/PDP_NYU/LoS/');
P.raw_usc_145_nlos = fullfile(P.repo_root, 'data/raw/usc_145/THz_data_PDP/PDP_NYU/NLoS/');
P.raw_usc_7_new    = fullfile(P.repo_root, 'data/raw/usc_7_new/All_Points_Full_Band');
P.raw_usc_7_old    = fullfile(P.repo_root, 'data/raw/usc_7_old/Midband_FR3_PDP');
% ---- antenna patterns ----
P.antpat_nyu_142 = fullfile(P.repo_root, 'data/antenna_patterns/nyu_142');
P.antpat_usc_145 = fullfile(P.repo_root, 'data/antenna_patterns/usc_145');
P.antpat_nyu_7   = fullfile(P.repo_root, 'data/antenna_patterns/nyu_7');
P.antpat_usc_7   = fullfile(P.repo_root, 'data/antenna_patterns/usc_7');
% ---- results roots (written by processing/*.m) ----
P.results_nyu_142 = fullfile(P.repo_root, 'matlab/processing/nyu_142/Results');
P.results_usc_145 = fullfile(P.repo_root, 'matlab/processing/usc_145/Results');
P.results_nyu_7   = fullfile(P.repo_root, 'matlab/processing/nyu_7/Results');
P.results_usc_7   = fullfile(P.repo_root, 'matlab/processing/usc_7/Results');
% ---- point-data xlsx roots (already present; kept) ----
P.n3_142_xlsx, P.n3_7_xlsx, P.u3_142_xlsx, P.u3_7_xlsx, …
% ---- paper figure output root (consumed by AS_CDF_Merged, BA_AS_Merged) ----
P.paper_fig_out = fullfile(P.repo_root, 'figures/matlab');
```

Every paper-figure script must be minimally edited to replace
`basePath = 'D:\NYU-USC\Cross-Processing'` and
`figOutputPath = 'D:\Joint-Point-Data-format-USC-NYU-Journal\figures'`
with a `P = paths(); basePath = P.results_root_parent; figOutputPath = P.paper_fig_out;`
pair (see §6).

### 5.2 `run_all.m` orchestration

Proposed new top-level driver:

```
run_all.m
│
├─ plot_style();  P = paths();                  (existing)
│
├─ STAGE 1: Raw directional-PDP → Results
│   run(fullfile('processing','nyu_142','NYU142GHz_Method_Comparison'));
│   run(fullfile('processing','usc_145','USC142GHz_Method_Comparison_Full'));
│   run(fullfile('processing','nyu_7','NYU7GHz_Method_Comparison'));
│   run(fullfile('processing','usc_7','USC7GHz_NewData_Processing'));
│
├─ STAGE 2: Cross-processing (Codebase-A style) → N3/U3 xlsx
│   run(fullfile('processing_xproc','USCprocessNYUdata','USCprocessNYU142M_exp'));
│   run(fullfile('processing_xproc','USCprocessNYUdata','USCprocessNYU7M_exp'));
│   run(fullfile('processing_xproc','NYUprocessUSCdata','NYUprocessUSC145'));
│   run(fullfile('processing_xproc','NYUprocessUSCdata','NYUprocessUSC145_USCthresh'));
│   run(fullfile('processing_xproc','NYUprocessUSCdata','NYUprocessUSC7'));
│   run(fullfile('processing_xproc','NYUprocessUSCdata','NYUprocessUSC7_USCthresh'));
│
├─ STAGE 3: Paper figures (verbatim paper scripts)
│   copy_passthrough_figures();                  % Fig. 1 & 2 passthrough
│   run('paper_figures/Plot_BlandAltman_PL_DS_AS'); % Fig. 3
│   run('paper_figures/BA_AS_Merged');            % Fig. 4
│   run('paper_figures/cdf_ci_pl_analysis');      % Fig. 5 (+ Table 7 stats)
│   run('paper_figures/cdf_ci_pl_analysis_DS_ref'); % Fig. 6
│   run('paper_figures/AS_CDF_Merged');           % Fig. 7 + Fig. 8
│   run('paper_figures/Generate_AS_CrossProcessing_Table'); % Table 6
│
└─ STAGE 4: Python-parity drivers (existing fig03…fig08, table06, table07) — optional, for parity checks.
```

---

## 6. Drift items to flag

Each paper-figure script contains hard-coded absolute paths and assumptions
that must be surfaced / overridden. Every item below was confirmed by direct
read; line numbers are approximate but reliable.

### 6.1 `AS_CDF_Merged.m` (Fig. 7 & 8)

- Line 29: `basePath = 'D:\NYU-USC\Cross-Processing';`
- Line 30: `figOutputPath = 'D:\Joint-Point-Data-format-USC-NYU-Journal\figures';`
- Lines 33–36 resolve `nyu142Path`, `usc145Path`, `nyu7Path`, `usc7Path` from `basePath`. **No other paths are hard-coded.** No location exclusions.
- **Minimum rewiring:** replace the two lines with
  ```matlab
  P = paths();
  basePath      = fileparts(P.results_nyu_142);  % parent of all four <band>/Results/
  figOutputPath = P.paper_fig_out;
  ```
  and adjust the 4 `fullfile(basePath, …)` lines to use the per-band `P.results_*` fields directly. **Net change: 6 lines.**

### 6.2 `BA_AS_Merged.m` (Fig. 4)

- Lines 35–44: identical `basePath` + `figOutputPath` + per-band results paths. Same rewiring as §6.1. **Net change: 6 lines.**

### 6.3 `Plot_BlandAltman_PL_DS_AS.m` (Fig. 3)

- Line 28: `nyuPath = fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Results', 'NYU142GHz_Method_Comparison_Results.xlsx');`
- Line 30: `uscPath = fullfile('D:\NYU-USC\Cross-Processing\ProcessingUSC145GHzData\Results', 'USC145GHz_Full_Results.xlsx');`
- Line 34: `saveDir = fullfile('D:\NYU-USC\Cross-Processing', 'BlandAltman_Figures');`
- **Important gap:** this script covers only the sub-THz band (Fig. 3 a/b). The 6.75 GHz Fig. 3 c/d subplots (`BA_PL7.png`, `BA_DS7.png`) are **not** produced by this script. Search for an authoritative 7 GHz variant shows none exists — they must be generated by cloning this script with the 7 GHz xlsx inputs, or by extending `BA_AS_Merged.m` to emit PL/DS as well. Flag to the integration engineer: **add a 7 GHz twin `Plot_BlandAltman_PL_DS_AS_7GHz.m` reading `NYU7GHz_Method_Comparison_Results.xlsx` + `USC7GHz_NewData_Results.xlsx`.** Net change: 3 path lines + add 1 sibling script.
- No location exclusions ("TX1-RX18" etc.) in the combined plot; warnings issued only when a column name is missing.

### 6.4 `cdf_ci_pl_analysis.m` (Fig. 5, Table 7 — pooled CI sub-THz)

- Line 7: `n3Path = fullfile('C:\Users\Dipankar\Documents\MATLABExperiments\NaveedDipankarMingjunJorgeShare\USC\USCprocessNYUdata\OriginalNYU_pointData', '142_UMi_N3.xlsx');`
- Line 8: `u3Path = fullfile('C:\Users\Dipankar\Documents\MATLABExperiments\NaveedDipankarMingjunJorgeShare\NYU\NYUprocessUSCdata\OriginalUSC-PointData', '142_UMi_U3.xlsx');`
- Line 62: `fGHz = 142;` — this is **correct** for sub-THz; the 7 GHz twin (`cdf_ci_pl_analysis_DS_ref.m`) sets `fGHz = 6.75` in a similar location.
- Line 63: `d0 = 1;` — CI reference distance, paper-correct.
- No location exclusions. Uses `bootstrap_ci_summary` with `nboot = 1000` and `prctile(…, [2.5 97.5])` — log into docs/numerical_parity for reproducibility.
- **Minimum rewiring:** 2 lines (replace both `fullfile(…)` paths with `P.n3_142_xlsx` / `P.u3_142_xlsx`).

### 6.5 `cdf_ci_pl_analysis_DS_ref.m` (Fig. 6, + shared helpers for Fig. 5/7/8 parity)

- Lines 8 & 9 (commented-out sub-THz case) / lines 9 & 10 (active 6.75 GHz case): same `C:\Users\Dipankar\…` paths pointing at `7_UMi_N3.xlsx` / `7_UMi_U3.xlsx`. Line 66 switches `fGHz` between 6.75 and 142.
- Treats USC-side `OLOS` locations as NLOS (masks include `u3_isOLOS`); LOS comparison is unchanged.
- **Minimum rewiring:** 2 lines + an `fGHz` switch driven by a band argument.

### 6.6 `bland_altman_analysis.m` (reference Fig. 3 generator, xlsx-based)

- Lines 11 & 12: same `C:\Users\Dipankar\…` paths.
- No location exclusions. Reads `FinalTable` sheet via the two-row-header loader shared with §6.4.
- **Minimum rewiring:** 2 lines.

### 6.7 `USCprocessNYU142M_exp.m` / `…7M_exp.m`

- Line 8 in `USCprocessNYU142M_exp.m`: `basePath="C:\Users\Dipankar\…\USC\USCformatNYUdata\";` (trailing backslash preserved). The 7 GHz twin has `USCformatNYUdata7`. The scripts also call `save("USCprocessingResults_NYUth_Sp2.mat","omniRes");` — a relative path, which means the CWD must be `USCprocessNYUdata/`. In a unified repo we must prepend `addpath(fullfile(repo_root,'matlab','processing_xproc','USCprocessNYUdata'))` and rely on `P.inter_usc_fmt_nyu_142` / `_7` for the input folder.
- Line 319 in `USCprocessNYU142M_exp.m`: `refXlsx = fullfile(pwd, 'OriginalNYU_pointData', '142_UMi.xlsx');` — relies on CWD again. Replace with `P.ref_NYU_142_xlsx`.
- Per-link TX-power table is hard-coded lines 31–72; those are empirical measurement values, not drift items — keep them but surface as a constants block at top of file for auditability.
- **Minimum rewiring:** 4 lines (basePath + refXlsx + save path + initial CWD-ensure).

### 6.8 `NYUprocessUSC145.m` / `…_USCthresh.m` / `…7.m` / `…7_USCthresh.m`

- Line 5: `root_path='G:\My Drive\NaveedDipankarMingjunJorgeShare\NYU\';` (with an alt commented-out `C:\Users\Dipankar\…`).
- Line 7: `Adata_path="\NYUformatUSCdata\NYUformat_PDP_R*";` (pattern).
- Line 11: `patternFile = 'USC_antennaPattern\THz_3D_pattern_aver.mat';` — relative to CWD. Must be resolved via `fullfile(P.antpat_usc_145,'THz_3D_pattern_aver.mat')`.
- Lines 56–57: `elevCut.mat` / `aziCut.mat` loads are also relative. Replace both with absolute paths from `P.antpat_usc_145`.
- HPBW = 10°, MTI = 25 ns, correction factors 1.95 dB — these are paper values, not drift.
- **Minimum rewiring:** 4 lines per script × 4 scripts = 16 lines.

### 6.9 Raw-processing scripts (§2.1–§2.4)

All four scripts hard-code `D:\NYU-USC\Cross-Processing\…` paths in their
configuration section (typically `paths.data`, `paths.output`, `paths.results`
+ the antenna-pattern / CSV lookups). Each needs 3–5 lines rewired to read
from `P = paths()`:

- NYU 142 GHz (`NYU142GHz_Method_Comparison.m`): lines 62 (csv), 83 (antenna pattern path), 121–123 (paths.data / output / results).  **5 lines.**
- USC 145 GHz (`USC142GHz_Method_Comparison_Full.m`): lines 136 (antenna pattern path), 175–180 (paths).  **4 lines.**
- NYU 7 GHz (`NYU7GHz_Method_Comparison.m`): lines 75 (csv), 83 (data path), 112–113 (antenna pattern paths), 147–149 (paths).  **6 lines.**
- USC 7 GHz new (`USC7GHz_NewData_Processing.m`): lines 102 (antenna pattern), 108–114 (paths).  **5 lines.**

**All four scripts have no location exclusions ("exclude TX1-RX18" etc.) — no
per-pair blacklists found in any of the five raw pipelines.** Empirical
correction factors (−1.95 dB sub-THz, 3.7 dB FR3, HPBW 8°/10°/30°) are paper
values and must be preserved verbatim.

### 6.10 Common themes

- **Universal find-and-replace targets** (highest-impact drift items):
  1. `D:\NYU-USC\Cross-Processing\`      → `fullfile(P.repo_root,'data'|'matlab')`
  2. `C:\Users\Dipankar\Documents\MATLABExperiments\NaveedDipankarMingjunJorgeShare\` → `fullfile(P.repo_root,'matlab','processing_xproc')`
  3. `G:\My Drive\NaveedDipankarMingjunJorgeShare\NYU\`                   → `fullfile(P.repo_root,'matlab','processing_xproc','NYU')`
  4. `D:\Joint-Point-Data-format-USC-NYU-Journal\figures`                  → `P.paper_fig_out` (= `<repo>/figures/matlab/`)
  Every hard-coded absolute path in every script reduces to one of these four.

- **Fixed-point assumption:** every figure script assumes `exportgraphics(..., 'BackgroundColor', 'white')` and `Position = [140 140 1400 520]` (CDF) or `[140 140 1200 600]` (BA). Do not change those — the paper's `\includegraphics[...]` commands rely on these aspect ratios.

---

## 7. Python scope

The Python port (`python/src/channel_analysis/`) is table-driven: it reads the
point-data `.xlsx` output of the MATLAB pipelines (N1 / N3 / U1 / U3
summaries) and computes bootstrap CIs, CI PL fits, DKW CDF bands, and
Bland-Altman statistics. It does **not** reprocess raw directional PDPs.
Coverage per figure / table:

| Paper element                              | Reproducible in Python from MATLAB's intermediate outputs? | Notes                                                                                                                                                                                                                                                              |
| ------------------------------------------ | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Fig. 1 (flow diagram, TikZ)                | No (passthrough)                                           | Static TikZ source in paper. Python port just copies the PDF.                                                                                                                                                                                                      |
| Fig. 2 a/b (calibrated directional PDPs)   | **No — MATLAB-only**                                       | Requires the raw H matrix (USC) and the 13-column PDP cell (NYU). Python intentionally does not ingest raw PDPs — the paper justifies that choice as a separation of concerns.                                                                                    |
| Fig. 3 (BA PL/DS, 4 panels)                | **Yes**                                                    | Already reproduced by `python/…/figures/fig03_bland_altman_pl_ds.py` from the N3/U3 xlsx point-data files. Inputs are `PL_NYU_SUM_dB` / `PL_USC_perDelayMax_dB` / `DS_*` columns.                                                                                   |
| Fig. 4 (BA ASA/ASD, 4 panels)              | **Yes**                                                    | Already reproduced by `fig04_bland_altman_as.py` from N3/U3 xlsx. 7 GHz panel needs `ASA_NYUthr_N10` vs `ASA_NYUthr_U` mapping (dual-threshold fields specific to the NYU 7 GHz script).                                                                           |
| Fig. 5 (CI PL scatter, pooled)             | **Yes**                                                    | Already reproduced by `fig05_ci_pl_scatter.py` — CI model with fixed `PL(d0=1m) = 32.44 + 20log10(fGHz)` and bootstrap CI for `n`, `σ`. Matches `cdf_ci_pl_analysis.m` fit function.                                                                               |
| Fig. 6 (DS CDF, pooled)                    | **Yes**                                                    | `fig06_ds_cdf.py`. DKW bands computed from `ε = sqrt(log(2/0.05)/(2n))`.                                                                                                                                                                                           |
| Fig. 7 (ASA CDF, pooled)                   | **Yes**                                                    | `fig07_asa_cdf.py`.                                                                                                                                                                                                                                                |
| Fig. 8 (ASD CDF, pooled)                   | **Yes**                                                    | `fig08_asd_cdf.py`.                                                                                                                                                                                                                                                |
| Table 4 / Table 8–11 (partial point-data)  | **Yes** (format-only)                                      | Python drivers `table04_N1_142.py` … `table11_N3_7.py` pretty-print the xlsx sheets. No numerical recomputation.                                                                                                                                                   |
| **Table 6 (cross-processing RMSE)**        | **Yes**                                                    | `table06_rmse.py` computes RMSE of (N3 − N1) and (U3 − U1) for PL / DS / ASA / ASD per band.                                                                                                                                                                       |
| **Table 7 (pooled stats summary)**         | **Yes**                                                    | `table07_pooled_stats.py` — bootstrap 95% CI widths on PLE `n`, σ, and log-domain means of DS / ASA / ASD.                                                                                                                                                         |
| Table 5 (methodology comparison, static)   | No (static LaTeX)                                          | Same for Tables 1, 2, 3.                                                                                                                                                                                                                                           |

**Boundary conclusion:** PDP-derived artefacts (Fig. 2a/b, and any future
figure that needs a per-delay or per-angle power slice) are MATLAB-only.
Everything else — all point-data-derived figures (3, 4, 5, 6, 7, 8) and
generated tables (6, 7) — is reproducible in Python from the same N3/U3 xlsx
that MATLAB emits, and is already wired up through
`python/src/channel_analysis/figures/fig{03…08}_*.py` and
`table{06,07}_*.py`. A run of `matlab/run_all.m` followed by
`python -m channel_analysis.run_all` produces the two figure sets
side-by-side in `figures/matlab/` and `figures/python/` for numerical parity
verification (see `docs/numerical_parity.md`).

---

*End of specification.*
