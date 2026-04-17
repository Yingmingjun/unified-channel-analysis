# MATLAB Code Inventory (Dataset A)

Codebase root: `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/`

This document inventories the MATLAB code that computes path loss (PL), RMS delay
spread (DS), angular spread (ASA/ASD) and cluster statistics from NYU and USC
propagation measurements at ~7 GHz (FR3 / Midband) and ~142 GHz (THz / D-band).
The goal is to port the pipeline to Python; style details are captured so the
regenerated figures can match.

Total `.m` files found: **~110** (see listing under each subdirectory below).
Significant number of files are copies of the same helpers replicated under
each processing subdirectory to sit beside the script that uses them (MATLAB
relies on the working-directory path). Those duplicates are flagged.

---

## 1. Top-Level Scripts (codebase root)

### 1.1 `bland_altman_analysis.m`
- **Purpose:** Bland–Altman plots comparing two processing methods on the
  *same* dataset. Within NYU data: "NYU thres" (USC-style processing)
  vs. "NYU orig. (N1)" (native NYU processing). Within USC data: "USC thres"
  (NYU-style processing) vs. "USC orig. (U1)" (native USC processing).
- **Inputs (hardcoded Windows paths):**
  - `.../USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi_N3.xlsx`
    sheet `FinalTable`
  - `.../NYU/NYUprocessUSCdata/OriginalUSC-PointData/142_UMi_U3.xlsx`
    sheet `FinalTable`
  - Reads a two-row header table; forward-fills metric names; drops rows
    missing both `TX` and `RX`.
- **Outputs:** Four per-case BA figures (`Omni PL` / `Omni DS` × NYU/USC data)
  plus two combined dual-axis PL and DS figures. No `.mat` written. No
  printed stats (bias / LOA annotated inline on figure).
- **Algorithm sketch:**
  - Pair columns `(metric, methodA, methodB)`, compute difference = A − B.
  - bias = mean(diff), SD = std(diff), LOA = bias ± 1.96·SD.
  - Combined dual-axis plot puts N3 differences on left y-axis, U3
    differences on right y-axis, with shared y-limits.
- **Dependencies:** pure local helpers (`load_ba_table`, `get_metric_pair`,
  `fill_header`, `to_num`, `plot_bland_altman`, `plot_bland_altman_combined_dualaxis`).
  No external functions. Depends on **precomputed xlsx tables** produced by
  upstream per-dataset processing scripts.
- **Plot style:**
  - `figure('Position',[200,200,900,550])` single,
    `[250,250,900,550]` combined.
  - `scatter(..., 50, 'filled')` marker size 50.
  - `yline(bias,'k-','LineWidth',1.5)` and `yline(LOA,'r--','LineWidth',1.2)`.
  - Combined plot uses color pair [`0 0.45 0.74`] blue and
    [`0.85 0.33 0.10`] orange, with faded fill variants
    [`0.60 0.78 0.92`] and [`0.98 0.78 0.68`].
  - Default font size (no explicit set). Legend `Location='best'`.

### 1.2 `cdf_ci_pl_analysis.m`
- **Purpose:** Build empirical CDFs (ECDF) with DKW 95 % confidence bands for
  Omni DS / ASA / ASD, and fit Close-In (CI) free-space reference path-loss
  models separately for LOS and NLOS, for NYU, USC, and pooled datasets.
  Prints bootstrap confidence-interval widths for `n` (PLE) and shadow-fading
  `sigma`. Prints log-normal mean DS / ASA / ASD per dataset per link state.
- **Inputs:** Same two xlsx point-tables as `bland_altman_analysis.m`:
  - `142_UMi_N3.xlsx` (NYU data with NYU processing, method column
    `NYU orig. (N1)`)
  - `142_UMi_U3.xlsx` (USC data with USC processing, method column
    `USC orig. (U1)`)
  - Hardcoded: `fGHz = 142`, `d0 = 1`, nboot = 500 (line fit) / 1000
    (CI summary).
- **Outputs:** One figure per metric in {DS, ASA, ASD}, with LOS and NLOS
  subplots. One CI-PL figure per dataset and a pooled one (3 total).
  Console prints: `n (95% CI low, high)` per link state; bootstrap CI
  widths for `n` and `sigma`; log-domain mean of DS/ASA/ASD in original
  units (ns / deg).
- **Algorithm sketch:**
  - CI model: `PL(d) = FSPL(d0) + 10·n·log10(d/d0)` with
    `FSPL(d0) = 32.44 + 20·log10(fGHz) + 20·log10(d0)`.
  - Fixed-intercept least-squares: `n = (A'·D)/(D'·D)` where
    `A = PL - FSPL(d0)`, `D = 10·log10(d/d0)`.
  - Sigma = RMS residual (population denominator, divides by N).
  - 95 % line band via 500-sample bootstrap of `n`, then
    `prctile(yhat_boot, [2.5 97.5])`.
  - CDF 95 % band = DKW (Dvoretzky–Kiefer–Wolfowitz) uniform band:
    `eps = sqrt(log(2/0.05) / (2n))`.
  - Log-normal mean (report linear) from log10 samples:
    `mean_lin = exp(mu*ln10 + 0.5*(sd*ln10)^2)`.
- **Dependencies:** local helpers only.
- **Plot style:**
  - `figure('Position',[200,200,1000,420])` for CDF,
    `[200,200,900,500]` for PL.
  - Line widths: ECDF `1.6`, fit line `1.6`, reference `1.2`.
  - Scatter marker size 25, `MarkerFaceAlpha 0.6`.
  - CDF band `FaceAlpha 0.12`, CI-fit band `FaceAlpha 0.15`, both
    `EdgeColor 'none'`.
  - Colors: blue `[0 0.45 0.74]`, orange `[0.85 0.33 0.10]`,
    pooled gray `[0.2 0.2 0.2]`.
  - PL x-axis log scale (`set(gca,'XScale','log')`), `xlim([1 200])`.
  - Legends `Location='best'`; explicit 6-entry legend
    `{'NYU','NYU 95% band','USC','USC 95% band','Pooled','Pooled 95% band'}`.

These two scripts are the **figure-producing endpoints for the paper**;
they consume the xlsx summary tables emitted by upstream scripts (below).

---

## 2. Subdirectory: `NYU/`

NYU-side code. Contains format-conversion, NYU-processing of USC-format data,
and the legacy "4.TCSL" pipeline used in earlier NYU papers. Three near-duplicate
top-level copies of `natsort.m` / `natsortfiles.m` (Stephen Cobeldick's
FileExchange utility, used everywhere for human-friendly sorting of filenames).

Top-level files (`NYU/`):
- `USC2NYU.m` — format converter, see 2.1.
- `natsort.m` / `natsortfiles.m` — 3rd-party utilities (shared helper,
  see §6).

Subfolders: `NYU_Data/`, `NYUformatUSCdata/`, `NYUformatUSCdata7/`,
`NYUformatUSCdata7backup/`, `NYUprocessUSCdata/`, `4.TCSL/`.

### 2.1 `NYU/USC2NYU.m`
- **Purpose:** Convert USC-style per-TX-RX PDP `.mat` files into NYU's 5-D
  `PDP_dir(Nt, N_aztx, N_eltx, N_azrx, N_elrx)` tensor plus a `spAngles`
  cell of `[AoD, ZoD, AoA, ZoA]` quadruplets, so USC data can be fed through
  NYU-processing scripts.
- **Inputs:**
  - `NYUdataPath` points at `NYU/NYU_Data/7AlignedDataset` (7 GHz branch) or
    the 142 GHz counterpart (commented block). Cell array columns follow NYU
    convention (see README in §7).
  - Hardcoded: `HPBW = 30` (7 GHz) / `8` (142 GHz), `Nt = 81880`, 3 elevation
    cuts, full 360° azimuth in HPBW steps.
- **Outputs:** One `.mat` per input link saved as
  `USCformat_<Env><origName>.mat` with variables `PDP_dir`, `spAngles`.
- **Algorithm sketch:**
  - Read aligned cell array (`Data7Pack_Aligned` / `Outdoor142`).
  - Build uniform azimuth grid `mod(az0 + HPBW*k, 360)` and 3-step
    elevation grid `[HPBW, 0, -HPBW] + el0`.
  - Fill `PDP_dir(:,iTXaz,iTXel,iRXaz,iRXel)` from matching rows.
  - Unmatched bins filled with blank PDP at −200 dB.
- **Dependencies:** `natsortfiles`.

### 2.2 `NYU/NYUprocessUSCdata/` (~25 files)

Self-contained pipeline that applies the NYU spatial-lobe / thresholding
workflow to **USC-format** data (after `USC2NYU` conversion upstream, or
starting directly from USC's per-RX `.mat`). Bundles *copies* of helpers
from `4.TCSL/` (flagged as duplicates).

Top-level processing scripts:
- **`NYUprocessUSC145.m` (509 lines)** — main 145 GHz (THz) pipeline.
  1. Builds synthetic USC Azi and El antenna cuts from
     `USC_antennaPattern/THz_3D_pattern_aver.mat` (field
     `HS21_mea_145G_1`, shape 361×91, averaged over frequency).
  2. Writes to `USC_antennaPattern/aziCut.mat`, `elevCut.mat` on first run;
     subsequently reloaded.
  3. Per-link loop over `NYUformat_PDP_R*` files, applies:
     - `multipath_low_bound = -200` (floor sentinel dB).
     - `thres_below_pk = 25` dB (per-PDP, 25 dB-below-peak mask).
     - `thres_abv_noise = 5` dB (mean of last 250 samples as noise est.).
     - Per-PDP threshold = max of those two; discard PDPs with no MPC above.
     - `MTI = 25` ns (minimum cluster void time).
     - `HPBW = 10` deg (USC antenna).
     - `RXAntGainCorr = TXAntGainCorr = 1.95` dB (USC pattern-correction;
       USC PDPs already calibrate antenna).
  4. Calls `PASgenerator`, `lobeShaperCounterD`, `boundaryMPCsD`,
     `clusterSearch`, `meanSLangles`, `SubPathPwrDirs`, `computeDirDS`,
     then `SecondaryStats_circD` for derived stats. Builds 45-column
     `statTable`.
  5. **Validation section:** loads USC-side reference
     `OriginalUSC-PointData/usc_microcellular_LOS_metrics.csv` and
     `_NLOS_metrics.csv`, matches on RX id + distance (±0.1 m), writes
     `PL_comparison_LOS.csv`, `PL_comparison_NLOS.csv`, plots scatter
     Computed-vs-Reference PL (y=x line), bar of PL errors, PL-vs-distance
     per link state, prints RMSE/MAE/N.
  - **Plot style:** `scatter(...,50,'b','filled')` LOS, `'r','filled'` NLOS,
    reference `'k--','LineWidth',1.5`, `bar(..., 'FaceColor',[0.2 0.4 0.9])`
    LOS and `[0.9 0.3 0.3]` NLOS. Plain MATLAB default fonts.
- **`NYUprocessUSC145_USCthresh.m`** — same pipeline but uses
  **USC's noise-floor definition** (25th percentile + 5.41 dB from
  `noise_floor_calc_v2`, uniform `+12` dB above max noise floor) in place
  of NYU's 25-dB-below-peak + 5-above-noise rule. Produces
  `OmniPDP1` (no spatial thresholding) instead of `OmniPDP1_spTh`.
  Same outputs otherwise.
- **`NYUprocessUSC7.m` (512 lines)** — 7 GHz (FR3 / Midband) variant.
  Reads `NYUformatUSCdata7/NYUformat_PDP_*`. Uses proxy antenna pattern
  files `EPlanePattern7.dat`, `HPlanePattern7.dat` since USC 7 GHz pattern
  not delivered. Gain correction `RXAntGainCorr = 3.7 dB`.
  `multipath_low_bound = -250`.
- **`NYUprocessUSC7_USCthresh.m`** — 7 GHz counterpart of the `_USCthresh`
  variant.

Helper `.m` files in `NYUprocessUSCdata/` (duplicates of `4.TCSL/` copies):
`PASgenerator.m`, `PASplotter.m`, `PDPdenoise.m`, `clusterSearch.m`,
`lobeShaperCounter.m`, `lobeShaperCounterD.m`, `boundaryMPCsD.m`,
`meanSLangles.m`, `SubPathPwrDirs.m`, `SubPathPwrDirsD.m`,
`computeDirDS.m`, `computeDSonMPC.m`, `compute_angular_spread.m`,
`getdirRMSDS.m`, `SecondaryStats_circD.m`, `circ_mean.m`, `circ_r.m`,
`circ_std.m`, `mmsefit.m`, `noise_floor_calc_v2.m`,
`rms_delay_spread_calc.m`, `natsort.m`, `natsortfiles.m`.

Input data: `NYUformatUSCdata/`, `NYUformatUSCdata7/` — these are the
NYU-layout converted USC measurements (produced by `USC/NYU2USC.m`,
see §3.1).

### 2.3 `NYU/4.TCSL/` (~35 files)

NYU's **Time-Cluster / Spatial-Lobe (TCSL) pipeline** used in earlier NYU
papers (Samimi–Rappaport TMTT 2016). Primary processing entry point:
- **`TCSL142D.m` (286 lines)** — single-script orchestrator:
  - Loads NYU 142 GHz aligned PDPs from
    `142GHzMeasurementsCode-UMi_rev/2.Alignment/Aligned/142 GHz/142GHz*`.
  - Loads `EPLANE Pattern Data 261D-27.dat`, `HPLANE Pattern Data 261D-27.dat`.
  - Constants: `multipath_low_bound = -100`, `thres_below_pk = 25`,
    `MTI = 25` ns, `HPBW = 8°`, `RXAntGain = TXAntGain = 27` dBi.
  - Builds 45-column `statTable`; column layout identical to the one used
    in `NYUprocessUSCdata/` scripts (documented inline at top of each file).
  - Produces per-link PAS polar plots (`PASplotter` + overlay of measured
    antenna pattern as dashed polar curve).

Utility `.m` files (kept once here, copied into other NYU processing subdirs):
`PASgenerator.m`, `PASplotter.m`, `PDPdenoise.m`, `clusterSearch.m`,
`boundaryMPCs.m`, `boundaryMPCsD.m`, `lobeShaperCounter.m`,
`lobeShaperCounterD.m`, `meanSLangles.m`, `SubPathPwrDirs.m`,
`SubPathPwrDirsD.m`, `computeDirDS.m`, `computeDirDS73.m`,
`computeDSonMPC.m`, `compute_angular_spread.m`, `getdirRMSDS.m`,
`angularSpread.m`, `AS_PAS.m`, `Count_TC_SPDir.m`, `Count_TC_SPOmni.m`,
`Kfactor.m`, `CDFplots.m`, `chi2gof_trial.m`, `circ_mean.m`, `circ_r.m`,
`circ_std.m`, `mmsefit.m`, `SecondaryStats.m`, `SecondaryStatsD.m`,
`SecondaryStats_circ.m`, `SecondaryStats_circD.m`, `natsort.m`,
`natsortfiles.m`, `test.m`.

One-line descriptions of the non-trivial helpers:
- `PASgenerator.m` — collapse 5-D PDP set to a Power–Azimuth (or Power–
  Elevation) Spectrum by summing over all other dimensions that survive
  the threshold; returns `(PAS_angles, PAS_powers, PAS_set)`.
- `PASplotter.m` — polar plot of a PAS, optional threshold overlay.
- `PDPdenoise.m` — zero-out samples below threshold from a linear PDP.
- `clusterSearch.m` — time-cluster detection by scanning for voids
  ≥ MTI ns in the omni PDP; returns `TCs, TCstart, TCstop, TCxsDelay,
  Nsp, intra-cluster delays, SP powers, inter-cluster delays`.
- `lobeShaperCounter.m` / `lobeShaperCounterD.m` — count spatial lobes;
  `D` variant threshold-shapes the lobes and returns the modified PAS.
- `boundaryMPCs.m` / `boundaryMPCsD.m` — place synthetic MPCs at lobe
  boundaries at power = threshold, to make angular-spread calculations
  better reflect beam boundaries.
- `meanSLangles.m` — per-lobe mean angles (AOA/ZOA or AOD/ZOD) and total
  lobe powers.
- `SubPathPwrDirs.m` / `SubPathPwrDirsD.m` — extract sub-path directions
  and powers per spatial lobe.
- `computeDirDS.m` / `computeDirDS73.m` — directional RMS-DS at a given
  pointing, antenna-pattern-weighted; the `73` variant splits TX and RX
  pattern files (used for 7.3 GHz with different-beamwidth horns).
- `computeDSonMPC.m` — RMS-DS from a list of `(delay, power)` MPCs.
- `compute_angular_spread.m` — Fleury angular-spread wrapper that accepts
  input/output units.
- `angularSpread.m` — per-lobe and global AS from a PAS.
- `AS_PAS.m` — alternative AS-from-PAS implementation (direct Fleury).
- `getdirRMSDS.m` — compute dir-RMS-DS over all PDPs in a PAS set.
- `SecondaryStats.m` / `SecondaryStatsD.m` / `SecondaryStats_circ.m` /
  `SecondaryStats_circD.m` — derive Omni DS, AS, etc. from the 45-column
  `statTable`; `_circ` variants use circular statistics (CircStat tools
  `circ_mean/r/std`); `D` variants use the boundary-MPC-injected
  sub-path list.
- `Kfactor.m` — Rician K-factor from TCSL results.
- `Count_TC_SPDir.m` / `Count_TC_SPOmni.m` — histogram and mean of
  time-cluster/sub-path counts, directional vs. omni.
- `CDFplots.m` — produces CDFs of AS, DS, Nc, Nsp from saved TCSL
  `.mat` results (loads `TCSL7Results_f_aligned.mat` by default).
- `chi2gof_trial.m` — chi-square goodness-of-fit tests for Nsp / Nc
  distributions.
- `circ_mean.m`, `circ_r.m`, `circ_std.m` — Berens CircStat toolbox.
- `mmsefit.m` — three-element MMSE linear fit (slope, intercept, residual
  std) used for PL fits.
- `test.m` — scratch (do not port).

**Flag:** `4.TCSL` is a *legacy* directory; most of its content is
duplicated in the two `*processUSCdata` / `*processNYUdata` pipelines. For
the Python port only `TCSL142D.m` (entry) and the helper set need to be
reviewed — the processUSC-data helpers are content-identical.

---

## 3. Subdirectory: `USC/`

USC-side code. Mirrors the NYU structure: a format converter, a pipeline
that applies USC processing to USC data (the "native" case), and a pipeline
that applies USC processing to NYU-format data. Also contains a `Codes4Reference/`
archive of the original USC code dropped in by authors.

Top-level files: `NYU2USC.m` (see 3.1), `natsort.m`, `natsortfiles.m`.
Subfolders: `Codes4Reference/`, `USC_Data/`, `USCformatNYUdata/`,
`USCformatNYUdata7/`, `USCprocessNYUdata/`, `USCprocessUSCdata/`.

### 3.1 `USC/NYU2USC.m`
- **Purpose:** Convert NYU-aligned `.mat` cell-array PDPs into the USC
  "3-D frequency response" layout `H(Nf, N_aztx, [N_eltx,] N_azrx, N_elrx)`
  — actually this script stops at PDPs of identical shape; the USC
  processing functions then time-dilate and window.
- **Inputs:**
  - 7 GHz: `USC/USC_Data/All Points Full Band/PDP_RX*.mat` with variable `H`.
  - 142 GHz (commented): `USC/USC_Data/THz data PDP/...`.
  - Hardcoded: parsing regex of filename `"PDP_RX%d_%fm"` or
    `"PDP_R%d_%fm"` for distance and RX ID; TX ID = 1 always;
    `n_oversamp = 10`, `window_val = 2` (Hann), BW = 1 GHz.
- **Outputs:** `NYUformat_PDP_R*.mat` written with `Outdoor7USC` or
  `Outdoor142USC` cell array, same 10-column schema as NYU aligned data.

### 3.2 `USC/USCprocessUSCdata/` (~16 files)

Native USC pipeline applied to USC's own `.mat` per-RX captures.

- **`USCprocessUSC145_exp.m` (61 lines)** — 145 GHz experiment runner.
  Reads `All Points Full Band/PDP_*.mat`, parses filename regex
  `PDP_RX(\d+)_(\d+\.?\d*)m_([^_]+)_MIDBAND_...`, per-link calls
  `USCprocessing` and populates 13-column `omniRes` (TXID, RXID,
  distance, omniPDP, PL, DS, ASA, ZSA, ASD, ZSD, undilated PDP, noise
  thresh, Env). Saves `USCprocessingResults_USCdata.mat`.

  — Despite the `145` in the filename the loaded path is "All Points Full
  Band" which is the **Midband/FR3** dataset; the call target is
  `USCprocessing7` in the 7-GHz variant. **Flag:** filename mislabel vs.
  content in `_exp` suffix scripts — verify `fGHz` when porting.
- **`USCprocessUSC7_exp.m` (63 lines)** — 7 GHz runner; reads THz data
  actually? Name/regex mismatch — the THz comment refers to the 142 file
  regex, but the actual enabled path is `All Points Full Band`. Uses
  `USCprocessing7`.
- **`USCprocessing.m` (158 lines)** — USC **145 GHz** processing function
  `[PDP_omni_over,PDP_omni,PL,RMS,AS_RX,ZS_RX,AS_TX,ZS_TX,noise_thresh] =
  USCprocessing(basePath, fileName, TR_distance)`.
  - Load raw `H(Nf, 13, 3, 36, 3)` (Nf freq bins, 13 TX az × 3 TX el × 36
    RX az × 3 RX el).
  - Apply Hann window (`hann(Nf+1,'Periodic')`, trim to `Nf`, energy-
    normalized), IFFT → PDP.
  - Compute per-bin noise floor with `noise_floor_calc_v2` (25th-percentile
    of log-PDP + 5.41 dB), pick **max** across all angle bins,
    `noise_thresh = max_noise + 12` dB.
  - Apply threshold, `circshift` PDPs to start ~5 m before line-of-sight
    (`d_LOS - 5`) when `d_LOS ≥ 5`; delay-gate at
    `t_gate = (d(end) - 10 + d_LOS)/c`.
  - Omni synthesis: sum over RX elevations, max over RX azimuth, sum over
    TX elevations, max over TX azimuth; multiply by `10^(-1.95/10)` gain
    correction for multi-elevation addition.
  - `PL_omni = -10·log10(sum(PDP_omni))` (0-dBm Tx power, antennas
    calibrated in).
  - Dilated PDP (×10 interpolation) → `rms_delay_spread_calc` with
    `noise_thresh - 20·log10(n_oversamp)` floor and the same `t_gate`.
  - AS / ZS via Fleury (`ASfleury`) using TX azimuth `-60:10:60`,
    RX azimuth `0:10:350`, TX/RX elevation `-10:10:10`.
- **`USCprocessing7.m` (159 lines)** — 7 GHz variant of the above, with
  `window H-slice [250:1250]` to carve 6.25–7.25 GHz from a wider capture,
  simpler 4-D `H(Nf, N_aztx, N_azrx, N_elrx)` (single TX elev), and
  `n_oversamp=10` (USC uses 10, NYU uses 20).
- **Helpers (copies):** `ASfleury.m`, `Num_tapsv5.m`, `natsort.m`,
  `natsortfiles.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`,
  `rrc_window.m`, plus an `.asv` autosave (`USCprocessNYU142M.asv`) and
  cached `.mat` result files (`USCprocessingResults_USCdata.mat`,
  `USCprocessingResults7_USCdata.mat`, `_bkp.mat`).
- **Live MATLAB notebooks** (Live Script `.mlx`, not part of the port):
  - `Parameter_comp_THz_fullelev.mlx` — parameter comparison across
    elevation cuts at 145 GHz.
  - `Parameter_eval_multielev_6_14GHz.mlx` — 6–14 GHz multi-elevation
    parameter evaluation.

### 3.3 `USC/USCprocessNYUdata/` (~19 files)

USC-style processing applied to NYU data (after `USC/NYU2USC.m` converts
it into USC layout).

- **`USCprocessNYU142M_exp.m` (477 lines)** — the **primary 142 GHz
  validation runner**. See §3.3.1 below.
- **`USCprocessNYU7M_exp.m` (458 lines)** — 7 GHz counterpart. Uses the
  same structure but different `Ptx_map` values (~15.5–15.9 dBm per link
  for 7 GHz vs −1 to −3.5 dBm for 142 GHz) and `thr = 12` dB
  (vs. `thr = 5` at 142 GHz). Also has `_USCthresh` twin — only shape
  difference is `Ptx_map` content (identical script structure).
- **`USCprocessNYU142M.m` (50 lines, short)** — legacy wrapper;
  deprecated by `_exp` variant. **Flag: likely stale.**
- **USC processing functions (4 near-identical variants):**
  - `USCprocessing.m` (194 lines): baseline.
  - `USCprocessing7.m` (194 lines): 7 GHz variant.
  - `USCprocessing_NYUth.m` (184 lines): "NYU threshold" variant —
    noise threshold sourced from an already-thresholded NYU metadata
    file (`NYU_Data_thresholded/142 GHz/142GHz_Outdoor_T%d-R%d.mat`)
    loaded from column 6–9 angle signatures; only evaluates noise floor
    at the angle bins for which NYU published a thresholded PDP.
  - `USCprocessing_NYUth_Sp.m` (200 lines): same, plus **spatial**
    thresholding (zeroes out non-matched bins as part of omni sum).
    This is what `_exp.m` actually calls.
  - `USCprocessing_NYUth_Sp7.m` (200 lines): 7 GHz version.
- **Cross-dataset scripts living here:**
  - `bland_altman_analysis.m` — a 7 GHz-aware twin of the root
    `bland_altman_analysis.m`, pointing at `7_UMi_N3.xlsx` / `7_UMi_U3.xlsx`
    instead of `142_UMi_*.xlsx`. **Flag: second copy of top-level
    script.**
  - `cdf_ci_pl_analysis.m` — same deal (7 GHz twin of top-level).
- **Helpers (copies):** `ASfleury.m`, `Num_tapsv5.m`, `natsort.m`,
  `natsortfiles.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`,
  `rrc_window.m`.

#### 3.3.1 `USC/USCprocessNYUdata/USCprocessNYU142M_exp.m` (detailed)

This is the most fully-formed "entry point" script with inline paper figures.

- **Inputs:**
  - `basePath = .../USC/USCformatNYUdata/` — converted NYU→USC `.mat` files
    matching `USCformat_142GHz_<Env>_T<TX>-R<RX>_<d>m.mat`.
  - Regex: `USCformat_142GHz_(?<Env>[^_]+)_T(?<TXID>\d+)-R(?<RXID>\d+)_(?<TR_distance>...)m.mat`.
  - Hardcoded `Ptx_map` (per-TX-RX dBm, 27 entries, TX1 varies by RX,
    TX2–6 uniform per TX).
  - Threshold `thr = 5` dB above noise floor.
  - Reference PL table `PL_ref` (27×4 with TXID, RXID, distance,
    reference omni PL) hardcoded inline from `142_UMi.xlsx`.
  - LOS link list `LOS_links` (16 pairs) hardcoded.
  - Reference DS table read from
    `OriginalNYU_pointData/142_UMi.xlsx` sheet `FinalData` (or
    `FinalTable` fallback), column `OmniDS`, `TRSep`, optional `LocType`.
- **Outputs:**
  - `USCprocessingResults_NYUth_Sp2.mat` — cell `omniRes{iTR, 1..12}`.
  - Five figures: PL computed vs reference, per-link PL error bar,
    PL vs distance with FSPL reference, DS computed vs reference,
    per-link DS error bar.
  - Console: PL validation summary (max abs err, mean abs err, RMSE,
    links-within-±1 dB count) and DS validation summary.
- **Algorithm sketch:**
  - Per link: `USCprocessing_NYUth_Sp(basePath, fileName, TR_distance,
    Ptx, thr, key)` — returns (omni dilated PDP, omni sparse PDP, PL,
    DS in dB(s), ASA, ZSA, ASD, ZSD, noise thresh).
  - PL formula: `PL = Ptx + G_tx(27 dBi) + G_rx(27 dBi) - Pr_omni`.
  - DS returned in dB(seconds); converted for plots via
    `ds_s = 10^(ds_db/10)` then ×1 e9 to ns.
  - PL error = computed − reference.
- **Plot style (this script):**
  - `figure('Name',...,'Position',[100,100,900,650])` for PL scatter,
    `[100,800,1200,500]` for PL error bar, `[100,1500,950,600]` for
    PL vs distance; analogous for DS figures on x offset 1100.
  - `ax.FontSize = 12` (PL scatter, PL vs distance) or `11` (bar).
  - `scatter(...,90, color, marker,'LineWidth',1.5, 'MarkerEdgeColor','k',
    'MarkerFaceColor', light_color)`.
    - LOS: blue `[0 0.45 0.74]`, face `[0.60 0.78 0.92]`, marker `'o'`.
    - NLOS: orange `[0.85 0.33 0.10]`, face `[0.98 0.78 0.68]`,
      marker `'s'`.
  - 1:1 reference `plot([pmin pmax],[pmin pmax], 'k--', 'LineWidth',1.2)`.
  - ±1 dB tolerance band `fill([...], 0.85*[1 1 1], 'FaceAlpha',0.35,
    'EdgeColor','none')`.
  - `grid on; box on; axis square`; `GridAlpha = 0.3`.
  - Bar chart `bar(x, PL_error, 0.7, 'EdgeColor','k', 'LineWidth',0.8)`
    with `FaceColor='flat'` and per-row `CData`.
  - `XTickLabelRotation = 45`.
  - FSPL reference dotted: `plot(d_fspl, FSPL, 'k:', 'LineWidth',1.2)`,
    FSPL formula `20·log10(d) + 20·log10(142) + 32.44`.
  - Legend `'Location','northwest'` (PL scatter) or `'best'`.
  - Hollow computed markers vs filled reference markers for the "same
    axis" PL-vs-distance plot.

This script is the closest to a ready-for-IEEE-paper figure source in the
codebase.

### 3.4 `USC/Codes4Reference/` (read-only archive)
- `ASfleury.m`, `noise_floor_calc_v2.m`, `Num_tapsv5.m`,
  `rms_delay_spread_calc.m`, `rrc_window.m`, plus
  `NYU_Code_Milcom/NYU_Directional_5.m` — kept for reference; not
  referenced by the active pipeline.

---

## 4. Subdirectory: `JournalPaper/`
- Contains PDF drafts (`CrossProcessingUSCNYU_draft.pdf`,
  `_rev.pdf`, `_revised.pdf`, `_trim.pdf`) and a `ppContents/` folder
  with `.fig` (MATLAB figure files) + `.png` exports of the paper
  figures (BA_*, OmniASA_merged*, OmniASD_merged*, OmniDS_merged*,
  PLcombinedPlot*). **No `.m` files here.** This is the output sink,
  not a source location.

## 5. Subdirectory: `paperContents/`
- `.fig`, `.png`, `.jpg` of paper figures and `USCpaperdiags.pptx`.
  No `.m` files. Use filenames (e.g. `BA_ASA7`, `PLcombinedPlot7`) to
  cross-reference which script produced which figure — the `7` suffix
  indicates the 7 GHz variant.

---

## 6. Entry points (regenerate the paper)

Run in order:

1. **`USC/NYU2USC.m`** — convert NYU's cell-array PDPs into USC 5-D
   tensor; writes `USC/USCformatNYUdata/` and `USCformatNYUdata7/`.
2. **`NYU/USC2NYU.m`** — reverse conversion; writes
   `NYU/NYUformatUSCdata/` and `NYUformatUSCdata7/`.
3. **`USC/USCprocessUSCdata/USCprocessUSC145_exp.m`** (and
   `USCprocessUSC7_exp.m`) — USC native pipeline on USC data; writes
   `USCprocessingResults_USCdata.mat` and
   `USCprocessingResults7_USCdata.mat`.
4. **`USC/USCprocessNYUdata/USCprocessNYU142M_exp.m`** (and
   `USCprocessNYU7M_exp.m`) — USC pipeline on NYU data with NYU-
   thresholding + spatial gating; writes
   `USCprocessingResults_NYUth_Sp2.mat` and produces the
   computed-vs-reference validation figures.
5. **`NYU/NYUprocessUSCdata/NYUprocessUSC145.m`** (and
   `NYUprocessUSC7.m`) — NYU pipeline on USC data; writes
   `PL_comparison_{LOS,NLOS}.csv`. `_USCthresh` variants use the USC
   noise-floor definition instead.
6. **`NYU/4.TCSL/TCSL142D.m`** — legacy native NYU pipeline
   (still used to generate comparison tables referenced in the
   `N1` / `U1` columns of the xlsx summary files).
7. **(out of band)** Author manually collates the N1/N3 and U1/U3
   summary tables into `142_UMi_N3.xlsx`, `142_UMi_U3.xlsx`
   (and 7 GHz twins).
8. **`bland_altman_analysis.m`** (root) — Bland-Altman figures.
9. **`cdf_ci_pl_analysis.m`** (root) — CDF + CI-PL figures +
   bootstrap CI widths + log-normal means (console).

**Top 5 entry points by importance for the paper:**

1. `cdf_ci_pl_analysis.m` (paper CDFs and CI-PL fits).
2. `bland_altman_analysis.m` (paper BA figures).
3. `USC/USCprocessNYUdata/USCprocessNYU142M_exp.m` (validation: USC
   processing on NYU data, 142 GHz).
4. `NYU/NYUprocessUSCdata/NYUprocessUSC145.m` (validation: NYU
   processing on USC data, 145 GHz THz).
5. `USC/USCprocessUSCdata/USCprocessUSC145_exp.m` (USC on USC, 145 GHz).

---

## 7. Shared utility functions

Used across processing scripts (often copy-pasted into each subdirectory).

| Function | Signature | Role |
|---|---|---|
| `natsort`, `natsortfiles` | 3rd party FileExchange | Human-friendly filename sort (e.g. `R1, R2, R10` instead of `R1, R10, R2`). |
| `noise_floor_calc_v2(pdp)` | returns scalar dB | Sort `10·log10(pdp)`; 25th-percentile sample + 5.41 dB offset (compensates from Q1 to median of an exponential). |
| `rms_delay_spread_calc(pdp, t, noise_floor [, tgate])` | returns `(ds_dB, mean_delay)` | Linear PDP, time vector; optional delay gating; returns DS in dB(s). USC variant has `tgate`, the USC/Codes4Reference version drops it. |
| `ASfleury(ang_rad, aps)` | scalar 0..1 | Fleury angular spread over a PAS; input angles in radians, discrete sum (not trapz). |
| `compute_angular_spread(angle_vec, power_vec, in_fmt, out_fmt)` | `(mean, var)` | Fleury AS with unit handling. |
| `rrc_window(alpha, Nf, BW)` | Nf-point vector | Root-raised-cosine frequency window for USC IFFT. |
| `Num_tapsv5(...)` | — | RRC-window helper (tap-count computation). |
| `mmsefit(x, y)` | 3-vector | Slope/intercept/sigma linear fit used for CI/FI PL. |
| `circ_mean`, `circ_r`, `circ_std` | CircStat toolbox | Circular statistics for angle-wrapped means and spreads (Berens). |
| `PASgenerator`, `PASplotter`, `lobeShaperCounter[D]`, `boundaryMPCs[D]`, `meanSLangles`, `SubPathPwrDirs[D]`, `clusterSearch`, `PDPdenoise` | see §2.3 | NYU TCSL building blocks. |
| `SecondaryStats[D/_circ/_circD]` | `(statTable, patterns) → secondary table` | Derive Omni DS/AS from raw cluster lists. |
| `computeDirDS`, `computeDirDS73`, `computeDSonMPC`, `getdirRMSDS` | delay-spread from MPC lists with pattern weighting | — |
| `USC2NYU.m`, `NYU2USC.m` | format converters | Data layout bridge between the two groups. |

---

## 8. Plotting style cheat-sheet (aggregated)

| Attribute | Typical value |
|---|---|
| **Figure size** | `[900, 550]` for 1×1 plots; `[1000, 420]` for 1×2 CDFs; `[1200, 500]` for wide bar charts; `[900, 650]` for scatter + 1:1. |
| **Axes font size** | `12` (primary), `11` (wide bar) — set via `ax.FontSize`. Default when unspecified. |
| **Grid** | `grid on; box on`; `GridAlpha = 0.3`. |
| **Marker size** | `scatter`: 25 (PL-fit), 50 (BA), 80–90 (validation scatter). `plot` markers 8. |
| **Line width** | Fit lines `1.6`; reference lines `1.2`; bias lines `1.5`; bar edges `0.8`. |
| **Color palette** (recurring) | LOS blue `[0 0.45 0.74]` edge with face `[0.60 0.78 0.92]`. NLOS orange `[0.85 0.33 0.10]` edge with face `[0.98 0.78 0.68]`. Pooled gray `[0.2 0.2 0.2]`. Reference line black `'k--'` or `'k:'`. LOS alternate (NYUprocessUSC145) blue `[0.2 0.4 0.9]`, NLOS red `[0.9 0.3 0.3]`. |
| **Markers** | `'o'` for LOS, `'s'` for NLOS. Hollow marker (no FaceColor) = computed; filled = reference. |
| **Confidence bands** | `fill(..., color, 'FaceAlpha', 0.12–0.35, 'EdgeColor', 'none')`. CDF bands 0.12; PL bands 0.15; ±1 dB bar band 0.35–0.5 on gray. |
| **Legend** | `'Location','best'` default, `'northwest'` for PL 1:1 scatter. |
| **Axis scale** | Path-loss plots: `set(gca,'XScale','log')`, `xlim([1, 200])` or `axis square`. DS CDFs linear. |
| **Text on lines** | `yline(val, ..., 'Label', ..., 'LabelHorizontalAlignment', 'left')` used in BA plots. |
| **Bar style** | `bar(x, y, 0.7, 'EdgeColor','k', 'LineWidth',0.8)` with `FaceColor='flat'` + per-row `CData`; `XTickLabelRotation=45`; per-link labels `Ti-Rj`. |
| **Colormap** | Default `parula`; no explicit `colormap` call anywhere. |

Emojis / non-ASCII: the `_exp` scripts contain em-dashes and non-ASCII
dashes; remove / transliterate when porting to Python strings.

---

## 9. Measurement data structure

### 9.1 NYU data (`NYU/NYU_Data/`)

Two aligned datasets sitting directly under `NYU_Data/`:

- **`142AlignedDataset/142GHz_Outdoor_T<tx>-R<rx>.mat`** (27 files).
  Variable: `Outdoor142` — `Nrows × 10` cell array, one row per
  (elevation cut × azimuth rotation). Columns (from `Mat data README.txt`):
  | Col | Content |
  |---|---|
  | 1 | Calibrated unthresholded PDP (linear, 81880 samples, 20 samples/ns — time-dilated) |
  | 2 | TX ID |
  | 3 | RX ID |
  | 4 | Measurement # (elevation cut) |
  | 5 | Rotation # (azimuth RX sweep step) |
  | 6 | AoD azimuth (deg, true N) |
  | 7 | ZoD (deg, horizon = 0°) |
  | 8 | AoA azimuth (deg, true N) |
  | 9 | ZoA (deg) |
  | 10 | Environment (`"LOS"` / `"NLOS"`) |

- **`7AlignedDataset/Data7Pack_TX<i>_RX<j>_Aligned.mat`** (18 files).
  Same 10-column schema, variable name `Data7Pack_Aligned`. PDPs are
  81880 samples at 7 GHz (undilated).

- Also: `7GHz_Outdoor (1).csv` — unused CSV export.

### 9.2 USC data (`USC/USC_Data/`)

- **`All Points Full Band/PDP_RX<rx>_<distance>m_<Env>_MIDBAND_<date>.mat`**
  — raw Midband (FR3, ~7 GHz) captures. Variable: `H` (complex frequency
  response, `[Nfreq × N_aztx × N_azrx × N_elrx]`; TX elevation is a single
  level at 7 GHz).
- **`Midband (FR3) data PDP/All Points Full Band/{LOS Study,OLOS Study}/RX<i>_<date>.mat`**
  and `RX<i>_<d>m_calib.mat` — per-RX calibrated frequency-domain captures.
- **`Midband (FR3) data PDP/Antenna Pattern/USC_Midband_Pattern.mat`**
  — measured antenna pattern for 7 GHz horn (used in
  `NYUprocessUSCdata/NYUprocessUSC7.m` via proxy files until delivered).
- **`Midband (FR3) data PDP/Midband (FR3) data PDP/*.mat`** — second
  copy of 7 GHz PDPs (likely duplicate / older snapshot — **flag**).
- **`THz data PDP/`** — 145 GHz THz microcell captures (per README
  subfolder structure: `LoS`, `NLoS`).
- **`Parameters THz Microcell Campaign/LoS|NLoS/parameters_R<i>_<d>m *.mat`**
  — pre-computed per-link metric `.mat` files (13 LOS files, 4+ NLOS
  files) used as the `OriginalUSC-PointData/usc_microcellular_*_metrics.csv`
  reference.

### 9.3 Ingestion pattern

All processing scripts use the same pattern:
```matlab
rootDir = dir(basePath + "<glob>");
rootDir = rootDir(~ismember({rootDir.name}, {'.','..'}));
[~, idx, ~] = natsortfiles({rootDir.name});
rootDir = rootDir(idx);
```
then regex-parse the filename to recover `TXID`, `RXID`, distance,
environment. The Python port should centralize this in a single
`load_measurement_index(dataset, freq_band)` helper.

---

## 10. Flags / open items

- **Duplicate helpers.** `natsort.m`, `natsortfiles.m`, `PASgenerator.m`,
  `lobeShaperCounter[D].m`, `SecondaryStats*.m`, `boundaryMPCsD.m`,
  `ASfleury.m`, `noise_floor_calc_v2.m`, `rms_delay_spread_calc.m`,
  `compute_angular_spread.m`, `circ_*.m`, `mmsefit.m`, `PDPdenoise.m`
  etc. are **physically copied** into:
  - `NYU/`, `NYU/4.TCSL/`, `NYU/NYUprocessUSCdata/`,
  - `USC/`, `USC/Codes4Reference/`, `USC/USCprocessNYUdata/`,
    `USC/USCprocessUSCdata/`.

  Port once in Python, import everywhere.

- **Duplicate top-level scripts.** `bland_altman_analysis.m` and
  `cdf_ci_pl_analysis.m` each exist both at the root and inside
  `USC/USCprocessNYUdata/`. The USC-subdir copies point at the **7 GHz**
  xlsx files (`7_UMi_N3.xlsx`, `7_UMi_U3.xlsx`), while the root copies
  point at **142 GHz**. Consolidate into a single parameterized Python
  script.

- **Version conflicts:**
  - `boundaryMPCs.m` vs `boundaryMPCsD.m` (D = distributed/dense, used by
    the newer pipeline — ports should follow the `D` variant).
  - `lobeShaperCounter.m` vs `lobeShaperCounterD.m` (same — use `D` for
    142 GHz, plain for 73/7 GHz per comment in `lobeShaperCounterD.m`:
    "Do NOT use LobeShaperCounterD for 142 GHz outdoor" — contradicts
    the fact that `NYUprocessUSC145.m` uses `D`. **Verify intended
    usage against paper before porting.**)
  - `SubPathPwrDirs.m` vs `SubPathPwrDirsD.m` (boundary-MPC-aware D).
  - `SecondaryStats.m` / `SecondaryStatsD.m` / `SecondaryStats_circ.m` /
    `SecondaryStats_circD.m` — four nearly-identical implementations.
    Active pipeline uses `SecondaryStats_circD`.
  - `USCprocessing.m`, `USCprocessing7.m`, `USCprocessing_NYUth.m`,
    `USCprocessing_NYUth_Sp.m`, `USCprocessing_NYUth_Sp7.m` — five-way
    branch; `_NYUth_Sp` is the one used by the current paper figures.
  - `USCprocessNYU142M.m` vs `USCprocessNYU142M_exp.m` — the short
    `.m` is superseded by `_exp.m` (50 vs 477 lines).
  - `computeDirDS.m` vs `computeDirDS73.m` — the `73` variant takes
    separate TX/RX pattern files.

- **Autosave / stale files** (ignore when porting):
  `TCSL142D.asv`, `boundaryMPCsD.asv`, `test.asv`,
  `USCprocessNYU142M.asv`, `test.m` (scratch),
  `USCprocessingResults7_USCdata_bkp.mat`,
  `NYUformatUSCdata7backup/`.

- **Unclear-purpose scripts:**
  - `NYU/4.TCSL/test.m` — scratch.
  - `NYU/4.TCSL/chi2gof_trial.m` — one-off trial block, not parameterized.
  - `USC/USCprocessUSCdata/Parameter_comp_THz_fullelev.mlx` and
    `Parameter_eval_multielev_6_14GHz.mlx` — Live Scripts; open in MATLAB
    to decide whether they produce any paper content.

- **Mislabeled filenames:** `USCprocessUSC145_exp.m` actually reads
  "All Points Full Band" which in the USC data tree is the **Midband**
  (7 GHz) dataset. The `_exp` suffix scripts need their frequency label
  confirmed against the xlsx reference tables before the Python port
  assumes `fGHz = 145`.

- **Hardcoded absolute paths** everywhere
  (`C:\Users\Dipankar\Documents\...`). The Python port should accept a
  root directory via config.

- **Xlsx intermediate format.** The two `.xlsx` summary tables
  (`142_UMi_N*.xlsx`, `142_UMi_U*.xlsx`, and 7 GHz twins) sit between
  the per-dataset processing pipelines and the final BA/CDF scripts.
  They have a *two-row header* with method names in the second row
  (e.g. `NYU orig. (N1)`, `NYU thres`, `USC orig. (U1)`, `USC thres`)
  and metric names in the first row (`Omni PL`, `Omni DS`, `Omni ASA`,
  `Omni ASD`, `TR Sep`, `Loc Type`, `Freq.`, `TX`, `RX`). The first-row
  header is sparse — forward-fill so a single metric name covers all its
  method sub-columns. Rows where both TX and RX are missing are summary
  rows and must be dropped.

- **NYU thresholded metadata dependency.** USC-processing-of-NYU-data
  expects `NYU_Data_thresholded/142 GHz/142GHz_Outdoor_T<tx>-R<rx>.mat`
  to exist in `pwd`; this is a **separately produced** thresholded
  version of the NYU aligned data (produced by NYU's own pipeline and
  shared as a `.mat` drop — not regenerable from code in this repo).
