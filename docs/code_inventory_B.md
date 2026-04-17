# Code Inventory B — MATLAB AS Cross-Processing Codebase

**Codebase root:** `D:/NYU-USC/Cross-Processing/`
**Scope:** MATLAB scripts that compute Angular Spread (AS) statistics from
propagation measurements (USC 145/7 GHz microcellular, NYU 142/7 GHz outdoor).
**Goal:** Provide a structural map adequate to drive a Python port.

Total `.m` files surveyed: **142** (including Microcell subdirs).
`.asv` autosave backups and `.zip` archives are excluded. Live-script `.mlx`
files are twins of the corresponding `.m` and are not documented separately.

---

## 1. Top-Level Paper / Analysis Scripts

### 1.1 Comprehensive_NYU_USC_Analysis_v7.m (AUTHORITATIVE)
- **Path:** `Comprehensive_NYU_USC_Analysis_v7.m` (708 lines)
- **Description:** Reference "TRUE method comparison" harness. Runs 5 method
  variants (M1–M5) on USC THz Microcell raw H data and compares against the
  GT CSV (`usc_microcellular_{LOS,NLOS}_metrics.csv`).
- **Inputs:**
  - `USC/Codes4Reference/NYU_Code_Milcom/Microcell/{LoS,NLoS}/*.mat` — H matrix
  - `USC/OriginalUSC-PointData/usc_microcellular_{LOS,NLOS}_metrics.csv` — GT
- **Outputs:** Console tables (ASD/ASA per location and summary stats).
- **Algorithm sketch (AS-centric):** 5 methods share PDP pipeline
  (Hann window → IFFT → |·|² → delay gate 966.67 ns). They differ by
  `{PDP-threshold, AS-formula}`:
  - **M1 (GT CSV):** per-PDP 25 dB below peak + `circ_std` (3GPP) AS
  - **M2 (USC Original):** global noise-floor + 12 dB + **Fleury** AS (× 180/π)
  - **M3 (NYU Original simplified):** 10 dB below APS peak (spatial lobe) +
    RMS AS with 360° δ-search (no boundary MPCs in this simplified port)
  - **M4:** USC PDP threshold + 3GPP AS
  - **M5:** no threshold + 3GPP AS
  APS formation common to all: `APS_Total = sum(sum(sum(PDP, delay), rxEl), txEl)`,
  then `APS_Tx = sum(APS_Total, rxAz)` and `APS_Rx = sum(APS_Total, txAz)'`.
- **Dependencies:** self-contained (all local functions).
- **Plotting style:** `DefaultAxesFontSize=11`, `DefaultLineLineWidth=1.5`,
  `DefaultFigureColor='w'`. No figures produced — table output only.

### 1.2 AS_CDF_Merged.m
- **Path:** `AS_CDF_Merged.m` (332 lines)
- **Description:** Produces LOS|NLOS CDF subplot figures for ASA & ASD at both
  sub-THz (142/145 GHz) and FR1(C)/6.75 GHz, matching style of the DS paper figure.
- **Inputs:** pre-computed results .mat files from the four `Processing*/Results/`
  folders (`all_comparison_results.mat`, `USC145GHz_Full_Results.mat`, etc.).
  For AS uses: `ASA_NYU_10dB` / `ASA_USC` (sub-THz), `ASA_NYUthr_N10` / `ASA_USC` (7 GHz).
- **Outputs:** `OmniASA_merged{,7}.{jpg,fig}` and `OmniASD_merged{,7}.{jpg,fig}`
  in `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/`.
- **Algorithm:** ECDF with DKW 95% band (`eps = sqrt(ln(2/0.05)/(2n))`);
  lognormal log10 stats annotation (μ, σ). NYU violet `[0.49 0.13 0.55]`,
  USC red `[0.85 0.00 0.10]`, Pooled blue `[0.10 0.15 0.90]`.
- **Style:** axis FontSize 19, legend 15, stat text 17 bold, main CDF LineWidth 2.2,
  scatter marker size 70 (o for LOS, d for NLOS), pooled band dashed LineWidth 1.5,
  fill alpha 0.12 (individual) / 0.10 (pooled), `exportgraphics` at 300 DPI.

### 1.3 BA_AS_Merged.m
- **Path:** `BA_AS_Merged.m` (288 lines)
- **Description:** Bland–Altman plots for ASA & ASD at sub-THz and 6.75 GHz.
  N3 = NYU data processed by both methods; U3 = USC data processed by both methods.
- **Inputs:** same four results `.mat` files as AS_CDF_Merged.
- **Outputs:** `BA_ASA{,7}.{jpg,png,fig}`, `BA_ASD{,7}.{jpg,png,fig}` in journal
  figures folder.
- **Algorithm:** diff = `ASA_USC − ASA_NYU_10dB` (method B − method A), plotted
  against mean. Bias, ±1.96 SD per group drawn as `yline`. Dual-axis trick:
  two stacked axes with linked y-limits; left axis blue (N3), right axis red (U3).
- **Style:** Figure `[1200 × 600]`, scatter size 120 (o blue / s salmon),
  edge LineWidth 1.8, bias line 2.0, 1.96σ dashes 1.8, text 22–28 pt,
  colors `colorN3=[0 0.45 0.74]`, `colorU3=[0.85 0.33 0.10]`, light fills
  `colorN3fill=[0.60 0.78 0.92]`, `colorU3fill=[0.98 0.78 0.68]`.

### 1.4 CDF_7GHz_Combined.m
- **Path:** `CDF_7GHz_Combined.m` (~700 lines total)
- **Description:** Combined CDF + Bland–Altman for all four metrics
  (PL, DS, ASA, ASD) at 7 GHz. Creates set A (NYU method) and set B (USC method).
- **Inputs:** `ProcessingNYU7GHzData/Results/all_comparison_results.mat`,
  `ProcessingUSC7GHzData/Results/USC7GHz_Full_Results.mat`.
- **Outputs:** `.pdf/.png/.fig` in `Figures/` and `BlandAltman_Figures/`.
- **Style:** IEEE preset — Times New Roman 10 pt, LineWidth 1.5, axes
  LineWidth 0.8, grid `:` alpha 0.3, LaTeX interpreter, white figure color.
  NYU blue `[0 0.45 0.74]`, USC orange `[0.85 0.33 0.10]`, Pooled dark-gray `[0.2 0.2 0.2]`.

### 1.5 Plot_BlandAltman_PL_DS_AS.m
- **Path:** `Plot_BlandAltman_PL_DS_AS.m`
- **Description:** Produces BA plots for PL, DS, ASA (10 dB threshold), ASD from
  the 142 GHz and 145 GHz Excel result tables.
- **Inputs:** `NYU142GHz_Method_Comparison_Results.xlsx`, `USC145GHz_Full_Results.xlsx`.
- **Outputs:** `BlandAltman_Figures/BlandAltman_{PL,DS,ASA,ASD}.{pdf,png,fig}`.
- **Algorithm:** diff = NYU method − USC method. For AS: `ASA_NYU_10dB − ASA_USC`.
  For PL/DS: compares SUM vs perDelayMax synthesis.
- **Style:** ScatterMarkerSize varies; otherwise same BA style as BA_AS_Merged.

### 1.6 Plot_Threshold_Sensitivity.m
- **Path:** `Plot_Threshold_Sensitivity.m`
- **Description:** Generates 2×2 PDP-threshold (peak−{20,25,30,35} dB) and 1×2
  PAS-threshold (10/15/20 dB + USC no-threshold) CDF sensitivity panels.
- **Inputs:** raw 142 GHz dataset `NYU/NYU_Data/142AlignedDataset/*.mat` +
  `NYU/NYU_Data/aziCut.mat` (antenna pattern).
- **Outputs:** `ThresholdSensitivity_Figures/CDF_{PDP,PAS}_Sensitivity.{pdf,png,fig}`
  plus `ThresholdSensitivity_6panel.*`, `_BoxPlot.*`, `_RMSE_Heatmap.*`.
- **Algorithm:** runs `compute_AS_NYU` across the grid of (PDP thr, PAS thr) pairs,
  then ECDF per config. Baseline PDP=peak−25 dB, PAS=10 dB.

### 1.7 Comprehensive_AS_Analysis.m
- **Path:** `Comprehensive_AS_Analysis.m` (~850 lines)
- **Description:** Narrative Live-Script-style analysis documenting GT data-format
  discovery (Fleury unitless vs 3GPP degrees), threshold effects, formula comparisons.
- **Inputs:** USC CSV GT + MAT parameter GT files.
- **Outputs:** `AS_Analysis_Figures.fig`, console prose.
- **Dependencies:** none (self-contained).

### 1.8 Compare_NYU_USC_Methods_Full.m
- **Path:** `Compare_NYU_USC_Methods_Full.m` (~900 lines)
- **Description:** Full NYU-style lobe + boundary MPC interpolation driver vs
  USC method, comparing four scenarios (A: USC Fleury, B: USC 3GPP, C: NYU-lobe+3GPP,
  D: NYU-lobe+Fleury).
- **Inputs:** NYU antenna pattern `EPLANE Pattern Data 261D-27.DAT` + USC GT CSVs.
- **Outputs:** console tables and figures.
- **Algorithm:** implements `lobeShaperCounter` / `boundaryMPC` logic locally.

### 1.9 Generate_AS_CrossProcessing_Table.m
- **Path:** `Generate_AS_CrossProcessing_Table.m`
- **Description:** Assembles AS_CrossProcessing_Results_v2.xlsx with N1, U1,
  NYU_thres, USC_thres columns for each dataset.
- **Inputs:** both Processing-folder XLSX result files + CSV distance table.
- **Outputs:** `C:/Users/mingj/Downloads/.../AS_CrossProcessing_Results_v2.xlsx`.

### 1.10 cdf_ci_as_analysis.m
- **Path:** `cdf_ci_as_analysis.m`
- **Description:** Stand-alone LOS|NLOS CDF for ASA and ASD with DKW bands
  (NYU 10 dB thresh vs USC no-thresh). Forerunner of AS_CDF_Merged.
- **Outputs:** `Figures/CDF_ASA.{pdf,png,fig}`, `CDF_ASD.{...}`.
- **Colors:** NYU blue `[0 0.45 0.74]`, USC orange `[0.85 0.33 0.10]`, Pooled gray `[0.2 0.2 0.2]`.

### 1.11 cdf_ci_pl_analysis.m  /  cdf_ci_pl_analysis_DS_ref.m
- **Paths:** `cdf_ci_pl_analysis.m`, `cdf_ci_pl_analysis_DS_ref.m`
- **Description:** CI (close-in) path-loss models + DS/ASA/ASD CDFs from the
  N3 and U3 stats Excel workbooks. `_DS_ref.m` is the canonical reference
  template for figure style (font 14, line 2.2, scatter 70, alpha 0.12/0.10).
- **Outputs:** CI model figures and CDF comparison figures.

### 1.12 calculate_AS_RMSE.m, verify_crossproc_stats.m, compute_updated_stats.m
- Small diagnostic scripts that hard-code AS values from the paper tables
  (`N3_ASA`, `N3_ASD`, `U3_ASA`, `U3_ASD`) and compute RMSE, Bland–Altman
  summaries, or refreshed USC-only mean / 95 % CI width.
- Useful as oracle tests when porting.

### 1.13 Viz_* and USC_Method_Visualization* (Live-script explainers)
- `Viz_AS_NYU_vs_USC_Detailed.m`, `MJ_Viz_AS_NYU_vs_USC_Detailed.m`,
  `Viz_DelaySpread_Validation.m`, `Viz_PathLoss_Validation.m`,
  `Viz_Complete_Validation_Summary.m`, `USC_Method_Visualization.m`,
  `USC_Method_Visualization_AllFiles.m`.
- **Description:** Step-by-step didactic walkthroughs of USC's perDelayMax
  omni synthesis (Sum-RxEl → Max-RxAz → Sum-TxEl → Max-TxAz) and DS/AS
  derivation. `_AllFiles` variant sweeps all 26 USC locations.
- **Dependencies:** `USC/USC_Data/THz data PDP/PDP_NYU/*`, `NYU/NYUformatUSCdata/*`.

### 1.14 Validate_USC_with_NYU_Method.m
- Runs NYU TCSL-style pipeline on USC data; hard-codes USC LOS GT (13×8
  matrix of file, distance, PL, DS, ASA, ASD, ZSA, ZSD) and reports PL/DS/ASA/ASD
  mismatches.

### 1.15 Verify_USC_Method_Exact.m / Verify_USC_Method_v2.m / _v3.m / _on_USC_Data.m
- Progressive verification attempts that explore whether USC's CSV GT can be
  reproduced. `v3` documents the key finding: USC uses noise-floor (NF+0),
  not NF+12 dB, for APS (12 dB was omni-PDP only).
- `_on_USC_Data.m` runs the full pipeline on USC raw H.

### 1.16 Diagnose_* scripts
- `Diagnose_LobeProcessing_ThirdLobeValid.m` — edge case: only third lobe above
  threshold.
- `Diagnose_Single_Location.m` — deep-dive one TX–RX (e.g., R01 LOS).
- `Diagnose_USC_vs_Computed_Differences.m` — enumerates all sources of divergence
  (noise threshold, APS formation, angle grids, formula).

### 1.17 Test_Threshold_Effect.m, test_sum_vs_max_detailed.m, test_threshold_diagnostic.m, test_usc_exact_method.m
- Unit-style scripts for the exact 5-D omni PDP operations. Useful as Python
  test fixtures.

---

## 2. ProcessingNYU142GHzData/

| File | Description |
|---|---|
| `NYU142GHz_Method_Comparison.m` | **Primary 142 GHz driver.** Loads NYU 142 GHz aligned dataset, applies per-directional PDP threshold `max(peak−25 dB, noise+5 dB)` with `noise = 10·log10(mean(PDP_lin(end−5000:end)))` over last 250 ns, forms APS and PAS. Runs NYU method with PAS thresholds 10/15/20 dB (lobe detection + antenna-pattern boundary MPC expansion, 3GPP AS) alongside USC method (no PAS thr, full APS). IEEE double-column figure style: Times New Roman 9 pt, LineWidth 1.2, axes LineWidth 0.8, grid `:` alpha 0.3, LaTeX interpreter. Colors: NYU_10dB blue, NYU_15dB orange, NYU_20dB gold, USC green. Outputs `Results/NYU142GHz_Method_Comparison_Results.xlsx`/`.csv` and `all_comparison_results.mat`. Contains `apply_NYU_PDP_threshold`, `generate_PAS`, `compute_omni_NYU`, `compute_omni_USC`, `compute_RMS_DS`, `compute_AS_NYU`, `compute_AS_USC`, `compute_AS_3GPP`, `load_TX_power_table`, `get_TX_power`, `load_antenna_pattern`, `interpolate_PAS_NYU`. |
| `Plot_Outage_Locations.m` | Diagnostic: plot raw PDP + PAS for outage locations (TX1-R18, TX4-R38) to illustrate why AS ≈ 0 (insufficient SNR). |

Data: `NYU/NYU_Data/142AlignedDataset/*.mat` (27 TX–RX pairs, 10-column cell per pair). Results folder: CSV, XLSX, MAT.

## 3. ProcessingNYU7GHzData/

| File | Description |
|---|---|
| `NYU7GHz_Method_Comparison.m` | **Dual-threshold 7 GHz driver.** Runs the pipeline twice per TX-RX pair: pipeline A uses NYU PDP threshold, pipeline B uses USC PDP threshold. For each, synthesises both NYU (SUM) and USC (perDelayMax) omni, then computes PL/DS/AS. Exports XLSX with NYU-Thr and USC-Thr column groups. TX/RX gain 15 dBi, HPBW 30°, frequency 6.75 GHz. Also emits `all_comparison_results.mat` with fields `ASA_NYUthr_N10`, `ASA_NYUthr_U`, `ASA_USCthr_*`, etc. |
| `7GHz_Outdoor (1).csv` | TX-power lookup CSV. |
| `7_phi0_pd.mat`, `7_phi90_pd.mat` | 7 GHz antenna pattern cuts. |

Data: `NYU/NYU_Data/7AlignedDataset/*.mat` (18 pairs, 13-column cell).

## 4. ProcessingUSC145GHzData/

| File | Description |
|---|---|
| `USC142GHz_Method_Comparison_Full.m` | **Primary 145 GHz driver.** Loads H-matrix from `USC/USC_Data/THz data PDP/PDP_NYU/`, applies USC ground-truth pipeline: Hann window (normalized to unit mean-square), IFFT, |·|², global noise threshold (25th percentile + 5.41 dB + 12 dB margin), elevation-summed APS with −1.95 dB correction, delay gate at `(d(end)−10+d_LOS)/3e8`. Computes PL (`−10·log10(sum(PDP_omni))`), DS (NYU `computeDSonMPC` formula), AS (3GPP `sqrt(−2·ln R)` with `compute_AS_NYU` + `compute_AS_USC`). Local functions: `noise_floor_calc_v2`, `computeDSonMPC`, `load_antenna_pattern`, `compute_AS_NYU_method`, `compute_AS_3GPP`. HPBW = 10 (grid step); Az_step = El_step = 10°. |
| `USC_Antenna_Pattern_Analysis.m` | HPBW visualization / polar plot of horn antenna pattern from `aziCut.mat`, `elevCut.mat` (H-plane 17.2°, E-plane 14°). Arial 11 pt style. |
| `aziCut.mat`, `elevCut.mat` | USC 145 GHz horn antenna cuts. |
| `18HPBW.fig` | Saved HPBW figure. |

## 5. ProcessingUSC7GHzData/

| File | Description |
|---|---|
| `USC7GHz_Method_Comparison.m` | FR3 Midband (6.25–7.25 GHz) comparison. H shape `[1001, 13, 36, 5]` (no TX elevation). PDP flip on TX azimuth; noise+12 dB with DR=22 dB cap. `omni_USC = Max-RxAz (after Sum-RxEl) then Max-TxAz`. Writes `USC7GHz_Method_Comparison_Results.csv/.xlsx`. |
| `USC7GHz_NewData_Processing.m` | Replacement driver for the new full FR3 dataset (6 LOS + 11 NLOS = 17 points). Uses USC-Midband antenna pattern `USC_Midband_Pattern.mat` for lobe expansion (not NYU 7 GHz). Writes `USC7GHz_Full_Results.mat` and `USC7GHz_NewData_Results.{csv,xlsx}`. IEEE 9-pt Times style. |
| Subfolders: `All Points Full Band-.../`, `Antenna Pattern-.../`, `Figures/`, `Results/`. |

---

## 6. Mingjun/ (first-pass personal analysis)

| File | Description |
|---|---|
| `AS_Comparison_Visualization.m` | Journal-quality AS comparison figures using NYU (SUM + 10/20/30 dB PAS + antenna-pattern boundary) vs USC (SUM + no-PAS). Uses 3GPP formula for both for fairness. Times New Roman 11. |
| `NYU_AS_Analysis.m` | Reference doc + code for NYU's two AS formulas (per-lobe `angularSpread.m` using linear interpolation over 1:360 vs `compute_angular_spread` with RMS 360° search). |
| `USC_AS_Analysis.m` | USC preprocessing with 3GPP AS formula (rather than Fleury) for like-for-like comparison. |
| `README_Analysis_Summary.txt` | Prose summary. |

## 7. NYU/ (original NYU code and ported variants)

### 7.1 NYU/4.TCSL/ — NYU's canonical 142 GHz TCSL pipeline
Key reusable modules (used downstream by every 142 GHz NYU-method script):
- `TCSL142D.m` — top-level driver producing 45-column `statTable` per TX-RX.
- `PASgenerator.m` — builds 1:360° PAS by `pow2db(sum(db2pow(PDPs per angle)))`;
  empty angles filled with `multipath_low_bound = −100 dB`.
- `lobeShaperCounter.m`, `lobeShaperCounterD.m` — detect lobes when angle gap > HPBW (8° for 142 GHz).
- `boundaryMPCsD.m` — insert interpolated boundary MPCs at angles where the
  measured antenna pattern drops to the spatial-lobe threshold (SLT) below peak.
- `angularSpread.m` — per-lobe 3GPP AS with linear interpolation refill of the 360° grid.
- `compute_angular_spread.m` — NYU's **RMS AS with 360° offset search**
  (the "min-δ" form).
- `circ_std.m`, `circ_r.m`, `circ_mean.m` — Berens circular statistics toolbox
  (Zar 26.20/26.21): `s = sqrt(2(1−r))`, `s0 = sqrt(−2·ln r)`.
- `SecondaryStats_circD.m` — computes Omni PL/DS/ASD/ZSD/ASA/ZSA per location
  using `circ_std` with MPC powers + boundary MPCs expanded.
- `SubPathPwrDirs{D}.m`, `meanSLangles.m`, `clusterSearch.m`, `Count_TC_SPOmni.m`,
  `Count_TC_SPDir.m`, `PDPdenoise.m`, `PASplotter.m`, `CDFplots.m`, `Kfactor.m`,
  `boundaryMPCs.m`, `getdirRMSDS.m`, `computeDirDS.m`, `computeDirDS73.m`,
  `computeDSonMPC.m`, `AS_PAS.m`, `chi2gof_trial.m`, `mmsefit.m`,
  `natsort.m`, `natsortfiles.m`, `test.m` — supporting utilities.
- `AntennaPattern/` — `EPLANE Pattern Data 261D-27.DAT` (azimuth),
  `HPLANE Pattern Data 261D-27.DAT` (elevation), required for boundary MPCs.

### 7.2 NYU/NYUformatUSCdata/ — USC data converted to NYU format
- 26 `.mat` files (LOS + NLOS) named `NYUformat_PDP_Rxx_*`, holding `PDP_dir` in
  NYU dimension ordering.

### 7.3 NYU/NYUprocessUSCdata/
- `NYUprocessUSC145.m` / `.mlx` — runs NYU TCSL pipeline on USC-formatted data.
- `TCSL_USC145results.mat`, `temp_statTable.mat` — saved intermediate tables.
- Same supporting `.m` files as `4.TCSL/` (duplicated).

### 7.4 NYU/OriginalNYU_pointData/
- Point data (xlsx and parameter mat files) for the 142 GHz outdoor campaign.

### 7.5 NYU/NYU_Data/
- `140GHz_Outdoor_BaseStation.csv`, `7GHz_Outdoor.csv`, `17GHz_Outdoor.csv`
- `142AlignedDataset/` — 27 `142GHz_Outdoor_Tx-Rx.mat` files.
- `7AlignedDataset/` — 18 `.mat` files for 7 GHz.
- `aziCut.mat` — 7 GHz antenna azimuth cut.
- `Mat data README.txt`.

### 7.6 NYU/USC2NYU.m
- Converter script: USC format → NYU 13-column cell.

## 8. USC/ (original USC code and ported variants)

### 8.1 USC/Codes4Reference/ — canonical USC pipeline
- **`AS_fleury_and_3gpp_fromAPS.m`** — reference function computing BOTH
  Fleury (unitless, and mapped to deg) and 3GPP circular std-dev from an APS.
  Exact formulas (see §11).
- **`ASfleury.m`** — Fleury-only implementation (used by `USCprocessing.m`).
- **`printAS_real.m`** — prints AS tables.
- **`rms_delay_spread_calc.m`** — USC's RMS-DS with noise threshold.
- **`noise_floor_calc_v2.m`** — USC's per-PDP noise-floor estimator.
- **`rrc_window.m`** — root-raised-cosine window helper.
- **`Num_tapsv5.m`** — tap-counting helper.
- **`Parameter_comp_THz_fullelev.mlx` / `_exported.m`** — THz campaign ground-truth driver.
- **`Parameter_eval_multielev_6_14GHz.mlx` / `_exported.m`** — FR3 ground-truth driver.
- **`NYU_Code_Milcom/NYU_Directional_5.m`** — source of truth for the GT CSV
  (per-PDP 25 dB, `omni_rule='perDelayMax'`, APS sum, `circ_std`).
- `NYU_Code_Milcom/THz_3D_pattern_aver.mat` — 3-D antenna pattern (361×91 az×el).

### 8.2 USC/USCprocessNYUdata/ — USC pipeline run on NYU data
- `USCprocessing.m` — main function producing PL/DS/AS (Fleury-based).
  The canonical source of USC's AS path (see algorithm details in §11).
- `USCprocessNYU142M.m`, `USCprocessNYU142.mlx` — wrapper scripts.
- `USCprocessingResults.mat` — saved outputs.
- Plus duplicates of `ASfleury`, `Num_tapsv5`, `rms_delay_spread_calc`,
  `rrc_window`, `noise_floor_calc_v2`, `natsort*`.

### 8.3 USC/OriginalUSC-PointData/
- `usc_microcellular_LOS_metrics.csv`, `usc_microcellular_NLOS_metrics.csv` —
  **ground-truth** PL, DS, ASA, ASD in degrees.

### 8.4 USC/USCformatNYUdata/
- 27 `.mat` files named `USCformat_142GHz_{LOS,NLOS}_Tn-Rxx_*.m` storing H in
  USC dimension order.

### 8.5 USC/USC_Data/
- `Midband (FR3) data PDP/`, `Parameters FR3 Campaign/`,
  `Parameters THz Microcell Campaign/`, `THz data PDP/` (with `PDP_NYU/` inside).

### 8.6 USC/NYU2USC.m
- Converter script: NYU → USC format.

## 9. USC_ver/ — Snapshot of Mingjun's AS analysis variants
- `AS_Comparison_Visualization.m` / `.mlx` — copy of Mingjun/.
- `NYU_AS_Analysis.m`, `USC_AS_Analysis.m` — copies.
- `USC142GHz_Method_Comparison.m` — earlier version of the 145 GHz driver.
- `RMS_DS.m` / `.mlx` — DS-focused variant.
- `Figures_10_15_20dB_th/`, `Figures_10_20_30dB_th/`, `Figures/` — saved outputs.
- `Results/`, `Results_PL_DS/` — saved tables.
- `README_Analysis_Summary.txt`.

Treat this folder as an older sibling of `Mingjun/` (duplicates). Prefer
`Mingjun/` + the top-level `Comprehensive_NYU_USC_Analysis_v7.m`.

---

## 10. Entry Points (scripts that generate paper figures)

1. **`AS_CDF_Merged.m`** — 4 AS CDF figures (sub-THz & 7 GHz × ASA/ASD).
2. **`BA_AS_Merged.m`** — 4 AS Bland–Altman figures.
3. **`Plot_BlandAltman_PL_DS_AS.m`** — PL/DS/ASA/ASD BA (sub-THz only).
4. **`Plot_Threshold_Sensitivity.m`** — PDP/PAS threshold sensitivity sweeps.
5. **`CDF_7GHz_Combined.m`** — Consolidated 7 GHz CDF + BA.
6. **`cdf_ci_pl_analysis_DS_ref.m`** — DS reference CDF (and template).
7. **`cdf_ci_as_analysis.m`** — earlier AS CDF generator (superseded by #1).
8. **`Comprehensive_AS_Analysis.m`** — educational figure bundle (not paper-critical).
9. **`Comprehensive_NYU_USC_Analysis_v7.m`** — method-comparison oracle tables.

Upstream data-producing entry points (produce the `Results/*.mat` consumed above):
- `ProcessingNYU142GHzData/NYU142GHz_Method_Comparison.m`
- `ProcessingNYU7GHzData/NYU7GHz_Method_Comparison.m`
- `ProcessingUSC145GHzData/USC142GHz_Method_Comparison_Full.m`
- `ProcessingUSC7GHzData/USC7GHz_NewData_Processing.m` (latest FR3 full dataset)

---

## 11. AS Algorithm Details (exact formulas)

### 11.1 Fleury (USC `ASfleury.m`)

```matlab
Power      = sum(aps);
mean_power = sum(exp(1j*ang).*aps) / Power;
AS_fleury  = sqrt(sum((abs(exp(1j*ang) - mean_power).^2).*aps) / Power);
% returns unitless in [0, sqrt(2)]; × 180/π to report as "degrees"
```

Equivalent closed form used by `AS_fleury_and_3gpp_fromAPS.m`:

```matlab
R         = |Σ w·e^{jα}|
AS_fleury = sqrt(max(0, 1 - R^2))
```

### 11.2 3GPP / circ_std (NYU `circ_std.m` line 54, used by GT CSV)

```matlab
r  = abs(Σ w·e^{jα}) / Σ w           % circular mean resultant
s0 = sqrt(-2 · log(r))               % radians → rad2deg() for degrees
% (USC AS_fleury_and_3gpp_fromAPS clamps r to max(r, 1e-12))
```

Equivalent mapping: `R^2 = 1 − AS_fleury^2`, so
`AS_3gpp_rad = sqrt(-ln(1 - AS_fleury^2))`.

### 11.3 RMS with 360° search (NYU `compute_angular_spread.m`)

```matlab
for d = 0:359
    θ_δ   = mod(angle + d + 180, 360) - 180;       % wrap
    μ     = sum(power_lin.*θ_δ) / sum(power_lin);
    θ_μ   = mod(θ_δ - μ + 180, 360) - 180;
    σ_AS(d+1) = sqrt(sum(power_lin.*θ_μ.^2) / sum(power_lin));
end
AS = min(σ_AS);                                     % degrees (linear-MPC σ)
```

This is used only for per-lobe AS inside the TCSL pipeline; the final "omni"
AS reported by `SecondaryStats_circD` uses `circ_std` on MPC powers plus
boundary MPC expansions (3GPP formula).

### 11.4 Spatial lobe detection (NYU `lobeShaperCounterD.m`)
1. Sort PAS angles/powers by angle.
2. Keep only angles whose power > `Thres10 = max(PAS) − 10 dB` (spatial-lobe threshold).
3. Lobes are contiguous runs where consecutive angular gaps ≤ HPBW (8° for 142 GHz; 10° for USC grid; 30° for 7 GHz system).
4. Wrap-around is handled (last→first lobe stitch).
5. `boundaryMPCsD.m` appends two boundary MPCs per lobe at angles where the
   measured antenna pattern drops to the threshold — `start − |azi(off_at_thr)|`
   and `end + |azi(off_at_thr)|`, both at power = SLT.

### 11.5 PDP thresholds (three variants)

| Method | Rule | Source |
|---|---|---|
| USC Original (omni-PDP) | `thr = max_over_dirs(noise_floor_per_dir) + 12 dB` applied once | `USCprocessing.m:43` |
| USC Original (APS path) | Uses `noise_floor` without +12 dB (per `Verify_USC_Method_v3`) | inference |
| NYU (per-direction) | `thr_i = max(peak_i − 25 dB, noise_i + 5 dB)`, where `noise_i = 10·log10(mean(PDP_lin(end−5000:end)))` | `NYU142GHz_Method_Comparison.m` |
| GT CSV | `thr = max(pdp_i) · 10^(−25/10)` per-direction, zero below | `NYU_Directional_5.m:168` |

### 11.6 APS formation
- USC: `Power_per_antenna = sum(PDP_dir, delay)` (linear);
  `APS_Total = sum(sum(Power_per_antenna, rxEl), txEl)`;
  `APS_Tx = sum(APS_Total, rxAz)`, `APS_Rx = sum(APS_Total, txAz).'`.
- NYU: via `PASgenerator.m` → 1:360° grid filled with `multipath_low_bound` (−100 dB)
  at unmeasured angles, `pow2db(sum(db2pow(.)))` at measured ones.

### 11.7 Omni-PDP synthesis
- USC `perDelayMax`: `Sum-RxEl → Max-RxAz → Sum-TxEl → Max-TxAz` (with
  `−1.95 dB` elevation-sum correction).
- NYU `sum`: `Σ_directions db2pow(PDP_dir)` in dB domain via
  `pow2db(sum(db2pow([AOA_PAS_set{:,1}]), 2))`.

---

## 12. Shared Utilities (reusable functions)

| Function | Signature | Where defined (primary) |
|---|---|---|
| `ASfleury` | `as = ASfleury(ang, aps)` | `USC/Codes4Reference/ASfleury.m` |
| `AS_fleury_and_3gpp_fromAPS` | `out = AS_fleury_and_3gpp_fromAPS(phi, APS)` → struct | `USC/Codes4Reference/` |
| `circ_std` | `[s, s0] = circ_std(alpha, w, d, dim)` | `NYU/4.TCSL/circ_std.m` (dup in `NYUprocessUSCdata/`) |
| `circ_r` | `r = circ_r(alpha, w, d, dim)` | NYU Berens toolbox |
| `compute_angular_spread` | `[μ, σ] = compute_angular_spread(angle, power, in_fmt, out_fmt)` | `NYU/4.TCSL/` |
| `angularSpread` | `AS = angularSpread(lobeCount, lobeWidths, ends, starts, PAS_angles, PAS_powers, 'Global', bool)` | `NYU/4.TCSL/` |
| `lobeShaperCounter` / `lobeShaperCounterD` | detect lobes on PAS | `NYU/4.TCSL/` |
| `boundaryMPCsD` | append antenna-pattern-derived MPCs | `NYU/4.TCSL/` |
| `PASgenerator` | `[PAS_ang, PAS_pow, PAS_set] = PASgenerator(TRpdpSet, refCol, altCol, floor_dB)` | `NYU/4.TCSL/` |
| `noise_floor_calc_v2` | `nf_dB = noise_floor_calc_v2(pdp_dB)` | `USC/Codes4Reference/`; re-embedded in `USC142GHz_Method_Comparison_Full.m` |
| `rms_delay_spread_calc` | `[rms_ds, tmp_pdp] = rms_delay_spread_calc(pdp_omni, tau, thr)` | `USC/Codes4Reference/` |
| `computeDSonMPC` | `rmsDS = computeDSonMPC(dly, pow, thr)` | `NYU/4.TCSL/`; also local in `USC142GHz_Method_Comparison_Full.m:1106` |
| `computeDirDS`, `getdirRMSDS` | directional DS with antenna pattern | `NYU/4.TCSL/` |
| `clusterSearch` | time-cluster detection (MTI 25 ns) | `NYU/4.TCSL/` |
| `load_antenna_pattern` | `pat = load_antenna_pattern(path)` | embedded in `NYU142GHz_Method_Comparison.m:1724` |
| `interpolate_PAS_NYU` | 1:360 interpolation of sparse PAS | embedded in `NYU142GHz_Method_Comparison.m:1746` |
| `compute_AS_NYU` | wraps lobe + boundary + 3GPP | embedded in `NYU142GHz_Method_Comparison.m:1399` |
| `compute_AS_USC` | no-threshold 3GPP | embedded at `:1590` |
| `compute_AS_3GPP` | weighted circ_std in degrees | embedded at `:1621` |
| `compute_AS_circ_std`, `compute_AS_fleury`, `compute_AS_rms` | three AS formulas in one place | `Comprehensive_NYU_USC_Analysis_v7.m:426–515` |
| `load_TX_power_table` / `get_TX_power` | lookup TX power per TX-RX ID | `NYU142GHz_Method_Comparison.m`, `NYU7GHz_Method_Comparison.m` |
| `natsort`, `natsortfiles` | natural sorting helpers | duplicated in `NYU/`, `USC/`, inner folders |

**Python-port target (canonical set):** port these three AS formulas, the
four PDP-threshold variants, and lobe detection / boundary expansion as
stand-alone library functions; then unit-test against
`Comprehensive_NYU_USC_Analysis_v7.m` outputs.

---

## 13. Plotting Style Summary (extracted from code)

| Preset | FontSize | FontName | LineWidth | Grid | Interpreter | Typical use |
|---|---|---|---|---|---|---|
| **IEEE-double-column** (used by all `Processing*/` drivers, `Plot_Outage_Locations`, `USC7GHz_NewData_Processing`) | axes 9, text 9 | Times New Roman | 1.2 | `:`, alpha 0.3 | latex | journal |
| **Paper-figure** (used by `AS_CDF_Merged`, `BA_AS_Merged`, `cdf_ci_pl_analysis_DS_ref`) | axes 14–19, legend 15, stat text 17 bold, BA labels 22–28 | default (Helvetica on Win) | 2.0–2.2 | on | tex | 300-DPI export |
| **Live-script / explanatory** (Comprehensive_*, USC_Method_Visualization*, Comprehensive_NYU_USC_Analysis_v*) | axes 11–12 | default | 1.5 | default | default | tables + pedagogical figures |
| **Antenna pattern** (`USC_Antenna_Pattern_Analysis`) | axes 11 | Arial | 1.5 | on | default | polar plots |

Color palette (consistent across AS-focused figures):

```matlab
colorNYU     = [0.00 0.45 0.74];  % blue (method + 142-GHz data)
colorNYU_alt = [0.49 0.13 0.55];  % violet in AS_CDF_Merged only
colorUSC     = [0.85 0.33 0.10];  % orange (method + USC data)
colorUSC_alt = [0.85 0.00 0.10];  % pure red in AS_CDF_Merged only
colorPooled  = [0.10 0.15 0.90];  % blue in AS_CDF_Merged
colorPooled_gray = [0.20 0.20 0.20];  % dark gray in cdf_ci_*
% Threshold series (NYU 142GHz):
colors.NYU_10dB = [0.0000 0.4470 0.7410];  % blue
colors.NYU_15dB = [0.8500 0.3250 0.0980];  % orange
colors.NYU_20dB = [0.9290 0.6940 0.1250];  % gold
colors.USC      = [0.4660 0.6740 0.1880];  % green
% Bland-Altman overlay:
colorN3     = [0 0.45 0.74];      colorN3fill = [0.60 0.78 0.92];
colorU3     = [0.85 0.33 0.10];   colorU3fill = [0.98 0.78 0.68];
```

Markers: `o` for LOS / NYU-data, `d` for NLOS (in CDFs), `s` for USC-data (in BA).
Scatter sizes: 70 (CDF dots), 120 (BA dots). Band fill alpha: 0.10–0.12.
Export: `exportgraphics(fig, path, 'Resolution', 300, 'BackgroundColor', 'white')`
followed by `saveas(fig, path_fig)`.

---

## 14. Data Structures (inferred)

### 14.1 Input H-matrix (USC raw / all backends)
- Shape `[Nf, N_aztx, N_eltx, N_azrx, N_elrx]` for 5D (THz Microcell / 145 GHz
  = `[1001, 13, 3, 36, 3]`, `Fs = 1.5 GHz`, delay gate 966.67 ns).
- FR3 Midband (USC 7 GHz) is 4-D `[Nf, N_aztx, N_azrx, N_elrx]`
  = `[1001, 13, 36, 5]`.

### 14.2 NYU aligned dataset (cell-array per TX-RX)
- 10-column (142 GHz) or 13-column (7 GHz) cell per pair. Columns:
  1. Denoised PDP (dB)
  2. TX_ID, 3. RX_ID, 4. Meas #, 5. Rot #
  6. AOD Az, 7. AOD El, 8. AOA Az, 9. AOA El
  10. Pr (power)
  11. pkIdx, 12. Propagation delay (142 GHz) / Environment (7 GHz)
  13. Raw PDP (7 GHz only)

### 14.3 Results .mat produced by each `*_Method_Comparison*.m`
Fields (as referenced by `AS_CDF_Merged.m` / `BA_AS_Merged.m`):
- `results.TX_RX_ID`, `results.Environment` ("LOS" / "NLOS" / "OLOS")
- PL: `PL_NYU_SUM_dB`, `PL_USC_perDelayMax_dB`, `PL_NYU_dB`, `PL_USC_dB`, `PL_USC`, `PL_NYU`
- DS: `DS_NYU_SUM_ns`, `DS_USC_perDelayMax_ns`, `DS_NYU_ns`, `DS_USC_ns`, `DS_USC`, `DS_NYU`
- ASA/ASD: `ASA_NYU_10dB`, `ASA_NYU_15dB`, `ASA_NYU_20dB`, `ASA_USC` (and ASD mirror).
  7 GHz adds dual-threshold variants `ASA_NYUthr_N10`, `ASA_NYUthr_U`, `ASA_USCthr_N10`, etc.

### 14.4 Ground-truth CSVs (USC)
- Columns: `File, Distance_m, PL_omni_dB, MeanDirDS_ns, OmniDS_ns, MeanLobeASA_d, OmniASA_d, MeanLobeASD_d, OmniASD_d, …`
- Values in degrees (3GPP `circ_std`).

### 14.5 Parameter MAT (USC THz Microcell)
- `parameters_Rxx_*.mat` with Fleury unitless AS (see
  `Comprehensive_AS_Analysis.m` Section 1 for format discovery).

### 14.6 Antenna patterns
- NYU 142 GHz: `NYU/4.TCSL/AntennaPattern/{EPLANE,HPLANE} Pattern Data 261D-27.DAT`
  (two-column ASCII: `[angle_offset_deg, gain_dB]`).
- USC 145 GHz: `ProcessingUSC145GHzData/{aziCut,elevCut}.mat` (H-plane / E-plane).
- USC FR3 Midband: `USC_Midband_Pattern.mat`.
- NYU 7 GHz: `ProcessingNYU7GHzData/7_phi0_pd.mat`, `7_phi90_pd.mat`; plus
  `NYU/NYU_Data/aziCut.mat`.

---

## 15. Version conflicts / duplicates

See `docs/code_conflicts.md` for the explicit selection rationale. Summary:

- **Comprehensive_NYU_USC_Analysis_v{1..7}.m**
  - v1 (`Comprehensive_NYU_USC_Analysis.m`, 842 lines): first pass.
  - v2 (618 lines): "CORRECTED" — switched to raw H, per-PDP 25 dB, 3GPP formula.
  - v3 (943 lines): added Live-Script structure + documented USC AS path.
  - v4 (1259 lines): full NYU threshold + noise-floor-aware rule; swaps in 3GPP formula everywhere.
  - v5 (974 lines): step-by-step A–F scenarios for method diffing.
  - v6 (664 lines): focus on Omni synthesis (SUM vs perDelayMax) × PDP threshold combinations (M1..M6).
  - **v7 (708 lines, Feb 2 2026) — AUTHORITATIVE.** Documents the three PDP
    thresholding methods, three omni methods, three AS formulas in ASCII tables;
    implements M1–M5 in one script; matches GT CSV by construction via M1.
- **USC_Method_Visualization_AllFiles.m** supersedes `..._OLD.mlx`.
- **ProcessingUSC7GHzData:** `USC7GHz_NewData_Processing.m` (Feb 26 2026)
  supersedes `USC7GHz_Method_Comparison.m` (Feb 21 2026). Use the NewData driver
  because it includes 6 LOS + 11 NLOS with correct USC-Midband antenna pattern.
- **USC_ver/** and **Mingjun/** duplicate the AS visualization scripts; prefer
  the top-level / `Processing*/` copies.
- **Verify_USC_Method_{Exact,v2,v3,on_USC_Data}.m** — only `v3` (noise floor
  without +12 dB) yields the correct AS match; others are historical attempts.
- **cdf_ci_as_analysis.m** is superseded by **AS_CDF_Merged.m**.

---

## 16. Unmapped / auxiliary scripts (not tied to a paper figure)

- `test_sum_vs_max_detailed.m`, `test_threshold_diagnostic.m`,
  `test_usc_exact_method.m`, `Test_Threshold_Effect.m` — algorithm-level tests.
- `Diagnose_Single_Location.m`, `Diagnose_LobeProcessing_ThirdLobeValid.m`,
  `Diagnose_USC_vs_Computed_Differences.m` — interactive diagnostics.
- `Verify_USC_Method_*.m` family — verification history.
- `Viz_AS_NYU_vs_USC_Detailed.m`, `MJ_Viz_AS_NYU_vs_USC_Detailed.m`,
  `Viz_DelaySpread_Validation.m`, `Viz_PathLoss_Validation.m`,
  `Viz_Complete_Validation_Summary.m` — educational walk-throughs.
- `USC2NYU.m`, `NYU2USC.m` — format converters.
- `natsort.m`, `natsortfiles.m` (duplicated) — natural-order sorting.
- `calculate_AS_RMSE.m`, `verify_crossproc_stats.m`,
  `compute_updated_stats.m` — paper-table sanity checks on hard-coded values.

---

## 17. Python-port notes (actionable)

1. Port `circ_std`, `ASfleury`, `compute_angular_spread`,
   `AS_fleury_and_3gpp_fromAPS` to a single module — unit-test against the
   M1–M5 outputs of `Comprehensive_NYU_USC_Analysis_v7.m` on the 26 USC locations.
2. Re-implement the 4 PDP-threshold rules exactly as tabulated in §11.5.
   Note: USC's `noise_floor_calc_v2` is based on sorted/percentile logic — inspect
   that function for the exact definition.
3. Lobe detection: port `lobeShaperCounterD.m` + `boundaryMPCsD.m` as a pair;
   be careful with wrap-around and the HPBW parameter (8° / 10° / 30° by system).
4. Antenna-pattern parsing: `.DAT` files are plain ASCII two-column tables;
   `.mat` cuts are `[angle, gain_dB]` (sometimes gain-normalized).
5. Use `Comprehensive_NYU_USC_Analysis_v7.m` as the regression-test oracle
   (produces per-method ASD/ASA for each `Rxx` location).
6. Use the GT CSVs (`usc_microcellular_{LOS,NLOS}_metrics.csv`) as absolute
   ground truth for ASA/ASD in degrees.
7. Figure output helpers: mimic the CDF+DKW and BA dual-axis logic from
   `AS_CDF_Merged.m` and `BA_AS_Merged.m` — the exact styles are preserved
   verbatim in `docs/code_inventory_B.md §13`.

---
