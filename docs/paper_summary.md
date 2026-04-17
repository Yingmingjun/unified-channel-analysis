# Paper Summary — Multi-Institutional Propagation Data Pooling and Cross-Processing (NYU/USC)

Source LaTeX: `D:/Joint-Point-Data-format-USC-NYU-Journal/main_final.tex`
Source PDF:  `D:/Joint-Point-Data-format-USC-NYU-Journal/main_final.pdf`
Figures:     `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/`

---

## 1. Title, Authors, Citation

**Title:** *Pooling of Multi-Institutional Radio Propagation Empirical Data with Cross-Processing Validation for 6G AI/ML Channel Modeling*

**Authors (in order):**
1. Dipankar Shakya (NYU WIRELESS) — equal first-author
2. Mingjun Ying (NYU WIRELESS) — equal first-author
3. Naveed A. Abbasi (USC)
4. Jorge Gomez-Ponce, Senior Member IEEE (USC; also ESPOL Polytechnic University, Guayaquil, Ecuador)
5. Xingchen Liu (NYU WIRELESS)
6. Xinquan Wang (NYU WIRELESS)
7. Daniel Abraham (NYU WIRELESS)
8. Theodore S. Rappaport, Life Fellow IEEE (NYU WIRELESS)
9. Andreas F. Molisch, Fellow IEEE (USC)

**Affiliations:**
- NYU WIRELESS, New York University, Tandon School of Engineering, Brooklyn, NY, USA.
- University of Southern California, Los Angeles, CA, USA.
- ESPOL Polytechnic University, Guayaquil, Ecuador (Gomez-Ponce secondary).

**Conference predecessors:** IEEE ICC 2025 (Rapp2025icc) and IEEE MILCOM 2025 (Shakya2025milcom).

**Funding:** NYU WIRELESS Industrial Affiliates Program (TSR, DS, MY, XL, XW, DA); USC Center for Wireless Propagation Research affiliates and NSF (AFM, NAA, JGP).

**Keywords:** Wireless propagation, channel sounding, standardized data format, 6G, machine learning.

---

## 2. One-Paragraph Abstract (Paraphrased)

Propagation measurements are expensive and underpin 6G standardization, yet they are typically shared as plots or lumped parameter tables without the metadata needed to combine them. This paper argues that multi-institution pooling requires (a) a standardized machine-readable point-data table keyed on TX-RX location pairs, (b) a measurement-summary metadata table listing every processing assumption (delay/spatial thresholds, omni-PDP synthesis method, AS definition), and (c) a two-phase cross-processing protocol in which each group replicates the other's pipeline and re-processes the shared raw data. The authors apply the protocol to NYU Brooklyn and USC Los Angeles urban-microcell (UMi) campaigns at 142 GHz / 145.5 GHz (sub-THz) and at 6.75 GHz (FR1C). Per institution the 95% CI widths for key parameters are wide (e.g. NLOS DS at sub-THz: 41.77 ns NYU and 28.67 ns USC); pooling 53 sub-THz and 37 FR1C locations sharpens these confidence bands (pooled NLOS DS CFI width 27.19 ns) while preserving site-wise behavior. The MATLAB implementation is released as a reference for the community.

---

## 3. Figures

Figures are subfigure-grouped in LaTeX; I enumerate parent figures with their subplots. Base directory: `figures/`.

### Figure 1 — Cross-Processing Flow Diagram
- Label: `fig:Xprocess`
- File: `figures/CrossProcessingDiag_rev.pdf`
- Caption: *"Cross-processing structure between NYU and USC."*
- Content: Flowchart with tables N1, U1 (original), N2, U2 (validation), N3, U3 (cross-processed), N4, U4 (mismatched-threshold) illustrating the two-phase pipeline replication/cross-processing protocol between NYU and USC.
- No metric plotted; schematic only.

### Figure 2 — Calibrated Directional PDPs (USC vs. NYU) at similar NLOS T-R separation
- Parent label: `fig:nyu_usc_pdp_comparison`
- Subplot (a): `fig:usc_dirpdp` — `figures/USC_dirPDP.jpg` — USC 145.5 GHz directional PDP
- Subplot (b): `fig:nyu_dirpdp` — `figures/NYU_dirPDP.jpg` — NYU 142 GHz directional PDP
- Caption: *"Comparison of calibrated PDPs from USC (left) and NYU (right) at similar TX-RX separation in NLOS. Use of another group's threshold can cause invalid evaluation of statistics."*
- What it shows: Directional PDP amplitude (dB) vs. propagation delay (ns), illustrating USC's lower but more variable noise floor (>15 dB fluctuation) vs. NYU's higher but flatter noise floor, motivating institution-specific thresholds.

### Figure 3 — Bland-Altman Plots for Path Loss & Omni DS (cross-processing)
- Parent label: `fig:ba_pl_ds`
- Subplot (a) `fig:ba_pl`: `figures/BA_PL.png` — sub-THz PL
- Subplot (b) `fig:ba_ds`: `figures/BA_DS.png` — sub-THz Omni RMS DS
- Subplot (c) `fig:ba_pl7`: `figures/BA_PL7.png` — FR1(C) 6.75 GHz PL
- Subplot (d) `fig:ba_ds7`: `figures/BA_DS7.png` — FR1(C) 6.75 GHz Omni RMS DS
- Caption: *"Bland-Altman plot for path loss (left) and omni RMS DS (right) at sub-THz and FR1(C). PL plot shows a systematic bias between methods. DS plot shows near zero bias but wide deviation for up to three locations (two at sub-THz, one at 6.75 GHz)."*
- Content: x-axis = mean of the two methods, y-axis = difference (USC perDelayMax − NYU SUM), with mean bias and ±1.96 SD limits drawn.

### Figure 4 — Bland-Altman Plots for Angular Spread (ASA, ASD)
- Parent label: `fig:crossproc_ba_as`
- Subplot (a) `fig:ba_asa`: `figures/BA_ASA.png` — sub-THz ASA
- Subplot (b) `fig:ba_asd`: `figures/BA_ASD.png` — sub-THz ASD
- Subplot (c) `fig:ba_asa7`: `figures/BA_ASA7.png` — FR1(C) ASA
- Subplot (d) `fig:ba_asd7`: `figures/BA_ASD7.png` — FR1(C) ASD
- Caption: *"Bland-Altman analysis of RMS AS comparing the NYU method (10 dB PAS threshold with lobe expansion) versus the USC method (no spatial threshold) for sub-THz and FR1(C). Solid line = mean bias; dashed lines = ±1.96 SD limits of agreement."*
- Each subplot reports mean difference and SD (e.g. sub-THz NYU-data ASA: bias 3.5°, SD 8.0°).

### Figure 5 — Close-In Path Loss Scatter with Best Fits (Pooled)
- Parent label: `fig:CIplot`
- Subplot (a) `fig:CI142`: `figures/PLcombinedPlot.jpg` — sub-THz pooled PL
- Subplot (b) `fig:CI7`: `figures/PLcombinedPlot7.jpg` — 6.75 GHz pooled PL
- Caption: *"CI PL scatter plot and best PLE fit combining NYU and USC data across 53 locations at sub-THz and 37 locations at 6.75 GHz."*
- Content: Path loss (dB) vs. log-distance (m) per TX-RX pair (sub-THz: 53 points total; 6.75 GHz: 37 points). Shows LOS and NLOS CI fits for NYU-only, USC-only, and the combined dataset. Plots reference the model $\mathrm{PL}(d)=\mathrm{PL}(1\mathrm{m})+10n\log_{10}(d)+X_\sigma$.

### Figure 6 — Omni RMS Delay-Spread CDF (Pooled)
- Parent label: `fig:DSplot`
- Subplot (a) `fig:DS_subTHz`: `figures/OmniDS_merged.jpg` — sub-THz
- Subplot (b) `fig:DS_7GHz`: `figures/OmniDS_merged7.jpg` — 6.75 GHz
- Caption: *"Omni RMS DS CDF for USC, NYU, and combined datasets at sub-THz and 6.75 GHz. DKW 95% confidence bands are narrower for the combined dataset, indicating increased statistical confidence from pooling."*
- Content: Empirical CDF of omni RMS DS (ns) with Dvoretzky–Kiefer–Wolfowitz (DKW) 95% bands for NYU-only, USC-only, and pooled (NYU+USC) sets; LOS and NLOS likely separated.

### Figure 7 — Omni RMS ASA CDF (Pooled)
- Parent label: `fig:ASAplot`
- Subplot (a) `fig:ASA_subTHz`: `figures/OmniASA_merged.png` — sub-THz
- Subplot (b) `fig:ASA_7GHz`: `figures/OmniASA_merged7.png` — 6.75 GHz
- Caption: *"Omni RMS ASA CDF for USC, NYU, and combined datasets at sub-THz and 6.75 GHz. NYU uses a 10 dB PAS threshold with lobe expansion, USC includes all measured directions without thresholding. Lognormal μ and σ are annotated for the pooled CDF."*
- Content: Empirical CDF of Omni ASA (degrees) per institution and pooled, with lognormal $(\mu,\sigma)$ annotated.

### Figure 8 — Omni RMS ASD CDF (Pooled)
- Parent label: `fig:ASDplot`
- Subplot (a) `fig:ASD_subTHz`: `figures/OmniASD_merged.png` — sub-THz
- Subplot (b) `fig:ASD_7GHz`: `figures/OmniASD_merged7.png` — 6.75 GHz
- Caption: *"Omni RMS ASD CDF for USC, NYU, and combined datasets at sub-THz and 6.75 GHz, following the same methodology as Fig. (ASAplot)."*
- Content: Same structure as Fig. 7 but for angular spread of departure (ASD).

**Total figures: 8 parent figures / 16 subplot graphics.**

---

## 4. Tables

### Table 1 — Literature Survey of Measurement-Processing Parameters
- Label: `tab:summary_results`
- Caption: *"Channel Measurement Data Processing and System Parameters from Literature"*
- Columns: Ref, Center Freq [GHz], PL Model, PDP Threshold for DS, Spatial Threshold for AS, EIRP [dBm], Bandwidth [MHz], Antenna Type (Gain/HPBW), Environment, Measurement System.
- Content: 12 rows citing prior campaigns (abbasi2025icc, zhou2022radio, Miao2023jsac, schmieder2020measurement, Saito2017eucap, Rodriguez2016wcnc, xing2021millimeter, wang2023300, abbasi2022thz, galeote2025spatial, Shakya2025icc, Shakya2024tap). Used to motivate the need for standardized metadata.

### Table 2 — Measurement-Summary Metadata Parameter Specification
- Label: `tab:metadata`
- Caption: *"Parameters included in the Measurement Summary Metadata Table"*
- Columns: Parameter, Data Type, Description.
- Lists ~30 metadata fields: Env, Mobility v, fc, BW, PTX,avg, DRmax/NF/Sensitivity, TPDP, TPAS, τmax/frep, Lseq/Navg, Δts, fs, Sync, Sweep Params, AS Def., Ant. Model/fop, Ant. Type, BWant, GTX/GRX, HPBW (TX/RX), SLL, FBR, Pol, XPD, Array Geometry, Number of Elements, Δφ/Δθ resolution, Antenna Switching Interval/Sequence, Gcorr.

### Table 3 — Measurement-Summary Metadata for NYU & USC Campaigns
- Label: `tab:preCompareMeta`
- Caption: *"Comparison of measurement summary metadata for NYU and USC UMi campaigns at sub-terahertz and 6.75 GHz."*
- Columns: Parameter, NYU@142 GHz, NYU@6.75 GHz, USC@145.5 GHz, USC@6.75 GHz.
- Key rows: Env (all UMi, Static); BW = 1000 MHz for all four; PTX,avg = 0 dBm (NYU 142), 15 dBm (NYU 6.75), −1 dBm (both USC); DRmax = 40 dB for all; TPDP = `max(25 dB below peak, 5 dB above noise floor)` for NYU, `τgate=966.67 ns; +12 dB(noise)` for USC; τmax = 4094 ns (NYU), 1 μs (USC); Lseq/Navg = 2047 PN sliding corr 20 avg (NYU), none (USC); Δts = 1 ns both; fs = 2.5 Msps NYU; Sync = Rb clocks (NYU), VNA internal (USC); Sweep = IFBW 10 kHz (USC 145), IFBW 1 kHz (USC 6.75), Npts=1001; AS Def. = 3GPP TR 38.901 (NYU), Fleury (USC); Ant. gains 27/15/21/11 dBi; HPBW 8°/30°/13°/18°; SLL −11 dB (NYU), −13 dB (USC); FBR 30/25/35 dB; Δφ/Δθ = 8°/8° (NYU 142), 30°/30° (NYU 6.75), 10°/10° (USC both); Gcorr = 1.95 dB (USC 145.5), 3.7 dB (USC 6.75).

### Table 4 — Partial N1 @ 142 GHz (NYU Point-Data, original NYU processing)
- Label: `tab:LSPs`
- Caption: *"Partial N1 @ 142 GHz Point-data table generated from the NYU WIRELESS measurements in Brooklyn, NY, showing site-specific large-scale spatio-temporal statistics at 142 GHz. Full table provided as supplementary material."*
- Columns: Freq, TX, RX, LocType (LOS/NLOS), TR Sep [m], PL [dB], Mean Dir DS [ns], Omni DS [ns], Mean Lobe ASA [°], Omni ASA [°], Mean Lobe ASD [°], Omni ASD [°], Mean Lobe ZSA [°], Omni ZSA [°], Mean Lobe ZSD [°], Omni ZSD [°].
- Example rows shown: TX2-RX1 LOS 83.6 m PL=112.0 dB omni DS=7.0 ns; TX3-RX35 LOS 74.8 m PL=116.8, omni DS=26.2 ns, omni ASA=13.5°, etc.

### Table 5 — NYU vs. USC Cross-Processing Methodology Comparison
- Label: `tab:cross_processing_methods`
- Caption: *"Comparison of NYU and USC Cross-Processing Methodologies"*
- Columns: Processing Step, NYU Method, USC Method.
- Rows: Data Sharing (same for both: calibrated directional PDPs + spatial info); Delay-Domain Threshold — NYU `max(25 dB below PDP peak, 5 dB above noise floor)` vs. USC `12 dB above max noise floor`; Omni-PDP Synthesis — NYU APDS + PAS + 10 dB SLT + summation over retained lobes vs. USC APDS + per-delay max across all azimuth pointings; Measurement Resolution — NYU HPBW steps vs. USC slightly-finer-than-HPBW w/ gain envelope correction; RMS DS common formula $\sigma_\tau=\sqrt{E[\tau^2]-E[\tau]^2}$; RMS AS — NYU uses 3GPP $\sigma_\phi=\sqrt{-2\ln R}$ vs. USC uses Fleury $\sigma_\phi=\sqrt{1-R^2}$ with the common $R=|\sum_k p_k e^{j\phi_k}/\sum_k p_k|$.

### Table 6 — Cross-Processing RMSE (PL, DS, AS)
- Label: `tab:RMSE_th`
- Caption: *"RMSE of Path Loss, Delay Spread, and Angular Spread when applying different group's thresholds."*
- Columns: Freq [GHz], Metric (RMSE), USC Data NYU-SUM Method (U3): NYU Thr / USC Thr, NYU Data USC-perDelayMax Method (N3): USC Thr / NYU Thr.
- Reported values:
  - **142 GHz:** PL: 3.39 / 3.01 / 14.24 / 1.50 dB. DS: 61.63 / 4.71 / 46.13 / 18.60 ns. ASA: 6.12 / 0.00 / 8.62 / 0.00 °. ASD: 2.01 / 0.00 / 4.16 / 0.00 °.
  - **6.75 GHz:** PL: 6.20 / 6.19 / 3.30 / 3.68 dB. DS: 39.47 / 7.21 / 28.17 / 14.79 ns. ASA: 7.44 / 0.00 / 17.52 / 0.00 °. ASD: 3.78 / 0.00 / 38.06 / 0.00 °.

### Table 7 — Pooled Statistical Summary (CI PL, DS, AS)
- Label: `tab:Stats_summ`
- Caption: *"CI path loss model parameters using a 1 m free-space ref. distance, along with mean omni RMS DS and AS, for NYU-only at 142 GHz/6.75 GHz (27/20 pts), USC-only at 145.5 GHz/6.75 GHz (26/17 pts), and combined datasets (53/37 pts total)."*
- Columns: Freq, Dataset, Close-in PL {LOS (PLE, σ, 95% CFI width), NLOS (PLE, σ, 95% CFI width)}, Omni RMS DS {LOS E[·] & CFI width, NLOS E[·] & CFI width}, Omni RMS AS {ASA LOS E[·] & CFI, ASA NLOS E[·] & CFI, ASD LOS E[·] & CFI, ASD NLOS E[·] & CFI}.
- **142 GHz NYU-Only:** LOS PLE 1.96, σ 2.63, CFI 0.16; NLOS PLE 2.92, σ 8.28, CFI 0.54; DS LOS 15.77 ns (CFI 34.62 ns), DS NLOS 35.27 ns (CFI 41.77 ns); ASA LOS 6.27° (CFI 9.35°), ASA NLOS 45.97° (CFI 69.40°); ASD LOS 5.13° (CFI 3.06°), ASD NLOS 8.95° (CFI 10.66°).
- **145.5 GHz USC-Only:** LOS PLE 1.90, σ 0.86, CFI 0.05; NLOS PLE 2.84, σ 6.00, CFI 0.37; DS LOS 26.57 ns (CFI 26.77 ns), DS NLOS 31.88 ns (CFI 28.67 ns); ASA LOS 15.74° (CFI 6.54°), ASA NLOS 31.10° (CFI 19.74°); ASD LOS 10.98° (CFI 1.73°), ASD NLOS 21.60° (CFI 11.62°).
- **Sub-THz NYU+USC (pooled):** LOS PLE 1.93, σ 2.09, CFI 0.09; NLOS PLE 2.88, σ 7.18, CFI 0.34; DS LOS 24.29 ns (CFI 27.14 ns), DS NLOS 34.72 ns (CFI 27.19 ns); ASA LOS 11.09° (CFI 6.80°), ASA NLOS 36.56° (CFI 26.42°); ASD LOS 8.03° (CFI 3.84°), ASD NLOS 16.51° (CFI 11.02°).
- **6.75 GHz NYU-Only:** LOS PLE 1.79, σ 2.56, CFI 0.19; NLOS PLE 2.56, σ 6.51, CFI 0.42; DS LOS 67.55 ns (CFI 97.97 ns), DS NLOS 129.79 ns (CFI 184.38 ns); ASA LOS 25.97° (CFI 25.95°), ASA NLOS 32.02° (CFI 20.40°); ASD LOS 37.98° (CFI 40.71°), ASD NLOS 40.76° (CFI 30.88°).
- **6.75 GHz USC-Only:** LOS PLE 1.92, σ 1.42, CFI 0.12; NLOS PLE 2.62, σ 7.33, CFI 0.37; DS LOS 14.63 ns (CFI 21.06 ns), DS NLOS 29.00 ns (CFI 55.32 ns); ASA LOS 10.48° (CFI 6.96°), ASA NLOS 12.60° (CFI 4.89°); ASD LOS 5.87° (CFI 0.91°), ASD NLOS 12.23° (CFI 3.00°).
- **6.75 GHz NYU+USC (pooled):** LOS PLE 1.85, σ 2.44, CFI 0.13; NLOS PLE 2.59, σ 6.96, CFI 0.26; DS LOS 49.90 ns (CFI 87.45 ns), DS NLOS 68.40 ns (CFI 70.19 ns); ASA LOS 18.10° (CFI 9.09°), ASA NLOS 22.53° (CFI 6.91°); ASD LOS 21.57° (CFI 13.79°), ASD NLOS 26.87° (CFI 10.17°).

### Table 8 — Partial U3 @ 145.5 GHz (USC data cross-processed)
- Label: `tab:U3_145`
- Caption: *"Partial U3 @ 145.5 GHz: Point data table for USC data processed using NYU-replicated USC processing methods with both NYU's max(25 dB below local PDP peak, 5 dB above noise floor) delay-domain threshold w/ 10 dB SLT and USC's 12 dB above global max noise floor threshold."*
- Columns: Freq, TX, RX, LocType, TR Sep [m], Omni PL {NYU thres, USC thres, USC orig (U1)}, Omni DS {NYU thres, USC thres, USC orig}, Omni ASA {same three}, Omni ASD {same three}. Shaded columns = original U1 values.
- Note (footer): ASA/ASD "USC orig" values equal the "USC thres" column because AS depends only on delay threshold, not on omni synthesis.

### Table 9 — Partial U3 @ 6.75 GHz
- Label: `tab:U3_7`
- Caption: *"Partial U3 @ 6.75 GHz: Point data table for USC data processed using NYU-replicated USC processing methods… Column definitions identical to Table U3_145."*
- Same column structure as Table 8.

### Table 10 — Partial N3 @ 142 GHz (NYU data cross-processed)
- Label: `tab:N3_142`
- Caption: *"Partial N3 @ 142 GHz: Point data table for NYU data processed using NYU-replicated USC processing methods with both USC's 12 dB above global max noise floor threshold and NYU's max(25 dB below local PDP peak, 5 dB above noise floor) delay-domain threshold w/ 10 dB SLT."*
- Columns mirror U3 but reversed labeling: {USC thres, NYU thres, NYU orig. (N1)} for each of {Omni PL, DS, ASA, ASD}.

### Table 11 — Partial N3 @ 6.75 GHz
- Label: `tab:N3_7`
- Caption: *"Partial N3 @ 6.75 GHz: Point data table for NYU data processed using NYU-replicated USC processing methods… Column definitions identical to Table N3_142."*
- Same column structure as Table 10.

**Total tables: 11 tables.** (A commented-out table for N1 @ 6.75 GHz exists but is not rendered.)

---

## 5. Numerical Claims (Body Text)

All values below must be reproduced from processing. Section references use LaTeX labels where possible.

### Abstract / Intro
- Abstract — *"95% confidence-interval widths for NLOS delay-spread are 41.77 ns and 28.67 ns at 142/145 GHz"* (NYU-only and USC-only respectively).
- Abstract — *"pooling 53 sub-THz and 37 6.75 GHz locations reduces NLOS delay-spread confidence-interval width at 142/145 GHz to 27.19 ns."*

### Section III (Cross-Processing), dataset counts
- NYU 142 GHz UMi: 27 locations (16 LOS / 11 NLOS), MetroTech commons, Brooklyn, NY.
- USC 145.5 GHz UMi: 26 locations (13 LOS / 13 NLOS), USC University Park Campus, LA, CA.
- NYU 6.75 GHz UMi: 20 locations (7 LOS / 13 NLOS), same Brooklyn sites.
- USC 6.75 GHz UMi: 17 locations (6 LOS / 11 OLOS), same LA sites.

### Section III.A — Processing Thresholds
- NYU delay threshold: `max(PDP_peak − 25 dB, Noise_floor + 5 dB)`.
- NYU noise floor = mean power (linear-domain average → dB) of last 250 ns of the PDP tail.
- NYU spatial threshold: 10 dB below PAS peak.
- *"25 dB below the peak corresponds to MPCs that are over 300 times weaker than the strongest MPC."*
- USC noise floor estimate: 25th-percentile of PDP samples + 5.41 dB correction (exponential-noise model).
- USC global threshold: `max_i{N_{f,i}} + 12 dB` across all directional PDPs at a TX-RX location.
- USC directional step: 10° at 145.5 GHz (HPBW 13°), gain-envelope correction 1.95 dB at 145.5 GHz.

### Section IV — Cross-Processing RMSE (numbers duplicate Table 6)
- Sub-THz mismatched-threshold RMSE: PL 3.4 dB (USC data) and 14.2 dB (NYU data); DS 61.6 ns (USC data) and 46.1 ns (NYU data); ASA 6.1° USC and 8.6° NYU; ASD 2.0° USC and 4.1° NYU.
- Sub-THz matched-threshold RMSE: PL 3.0 dB USC / 1.5 dB NYU; DS 4.7 ns USC / 18.6 ns NYU; ASA & ASD 0° for both.
- 6.75 GHz mismatched: PL 6.2 dB USC / 3.3 dB NYU; DS 39.5 ns USC / 28.2 ns NYU; ASA 7.4° USC / 17.5° NYU; ASD 3.8° USC / 38.1° NYU.
- 6.75 GHz matched DS RMSE: 7.2 ns USC / 14.8 ns NYU; AS RMSE 0° both.

### Section IV.A — PL Bland-Altman (`fig:ba_pl`, `fig:ba_pl7`)
- NYU sub-THz bias: +1.5 dB (SD ±1.6 dB).
- USC sub-THz bias: +2.8 dB (SD ±1.3 dB).
- NYU 6.75 GHz bias: +2.9 dB (SD ±3.0 dB).
- USC 6.75 GHz bias: +2.1 dB (SD ±1.4 dB).

### Section IV.B — DS Bland-Altman
- >95% of DS observations lie within ±10 ns limits of agreement.
- Outliers: 2 NYU sub-THz locations and 1 NYU 6.75 GHz location show >20 ns deviation.

### Section IV.C — AS Bland-Altman
- **NYU data at sub-THz:** ASA mean diff = 3.5°, SD 8.0°; ASD mean diff = 0.4°, SD 4.2°.
- **NYU data at 6.75 GHz:** small biases; ASA SD = 4.1°, ASD SD = 8.3°.
- **USC data at sub-THz:** ASA mean diff = 4.4°, SD 5.4°; ASD mean diff = 0.4°, SD 2.0°.
- **USC data at 6.75 GHz:** ASA mean diff = −0.6°, SD 5.2°; ASD mean diff = −2.5°, SD 1.2°.

### Section V.A — Path Loss (Close-In) from pooled data
- Sub-THz LOS PLE: 1.96 NYU, 1.90 USC; NLOS PLE: 2.92 NYU, 2.84 USC.
- Pooled sub-THz PLE: 1.93; NLOS CFI width shrinks from 0.54 (NYU) / 0.37 (USC) to 0.34 (pooled).
- 6.75 GHz pooled NLOS CFI width: 0.26 (vs. 0.42 NYU / 0.37 USC).

### Section V.B — Delay Spread
- Sub-THz pooled DS means: LOS 24.29 ns, NLOS 34.72 ns.
- NYU sub-THz DS means: LOS 15.77 ns, NLOS 35.27 ns.
- USC sub-THz DS means: LOS 26.57 ns, NLOS 31.88 ns.
- Pooled NLOS DS CFI width = 27.19 ns vs. 41.77 ns (NYU) and 28.67 ns (USC).
- 6.75 GHz pooled DS means: LOS 49.9 ns, NLOS 68.4 ns. CFI widths 87.45 ns LOS, 70.19 ns NLOS.
- NLOS DS mean shifts from 129.79 ns (NYU only) and 29 ns (USC only) to 68.40 ns pooled.

### Section V (Angular Spread pooled)
- Sub-THz ASA CFI width NLOS: 69.4° NYU-only → 26.42° pooled.
- 6.75 GHz pooled NLOS ASA CFI width: 6.91° vs. 20.40° NYU-only.
- Sub-THz pooled ASA: LOS 11.09°, NLOS 36.56° (NYU-only 6.27/45.97°, USC-only 15.74/31.10°).
- Sub-THz pooled ASD: LOS 8.03°, NLOS 16.51° (NYU-only 5.13/8.95°, USC-only 10.98/21.60°).

### General
- *"pooling just two institutions' data cut the NLOS PLE confidence interval nearly in half"* — consistent with 0.54 → 0.34 at sub-THz and 0.42 → 0.26 at 6.75 GHz.

---

## 6. Key Equations

### Eq. 1 — NYU PDP Threshold (`eq:nyu_threshold`)
$$T_{\text{PDP},i}^{(\text{NYU})} = \max\!\bigl(P_{\text{peak},i} - 25~\text{dB},\; N_{f,i} + 5~\text{dB}\bigr)$$
where $N_{f,i}=10\log_{10}\bigl(\overline{P_{\text{lin}}(\tau_{\text{tail}})}\bigr)$ estimated from the last 250 ns tail of the $i$-th directional PDP.

### Eq. 2 — USC Noise Floor Estimate (`eq:usc_noise`)
$$N_f = \text{percentile}_{25}(P(\tau)) + 5.41~\text{dB}$$
(5.41 dB maps the 25-percentile to the mean of an exponential noise-power distribution.)

### Eq. 3 — USC Global PDP Threshold (`eq:usc_threshold`)
$$T_{\text{PDP}}^{(\text{USC})} = \max_{i}\{N_{f,i}\} + 12~\text{dB}$$

### Eq. 4 — APDS for NYU SUM Synthesis (`eq:apds_nyu`)
$$\mathrm{APDS}(\tau,\phi_T,\phi_R) = \sum_{\theta_T}\sum_{\theta_R} P(\tau,\phi_T,\theta_T,\phi_R,\theta_R)$$

### Eq. 5 — PAS Integration (`eq:pas_nyu`)
$$\mathrm{PAS}(\phi_R) = \sum_{\phi_T}\sum_{\tau} \mathrm{APDS}(\tau,\phi_T,\phi_R)$$

### Eq. 6 — Spatial Lobe Threshold (`eq:slt`)
$$\bar\phi \in \{\phi : \mathrm{PAS}(\phi) \ge \max_\phi[\mathrm{PAS}(\phi)] - 10~\text{dB}\}$$
(NYU applies this; USC does not.)

### Eq. 7 — NYU Omni PDP (SUM) (`eq:omnipdf_nyu`)
$$\mathrm{omniPDP}^{(\text{SUM})}(\tau) = \sum_{\bar\phi_R}\sum_{\bar\phi_T} \mathrm{APDS}(\tau,\bar\phi_T,\bar\phi_R)$$
Sum restricted to SLT-retained azimuth pointings.

### Eq. 8 — USC Omni PDP (perDelayMax) (`eq:omnipdf_usc`)
$$\mathrm{omniPDP}^{(\text{perDelayMax})}(\tau) = \max_{\phi_T,\phi_R} \mathrm{APDS}(\tau,\phi_T,\phi_R)$$

### Eq. 9 — RMS Delay Spread (`eq:rmsds`)
$$\sigma_\tau = \sqrt{\frac{\sum_k P(\tau_k)\tau_k^2}{\sum_k P(\tau_k)} - \left(\frac{\sum_k P(\tau_k)\tau_k}{\sum_k P(\tau_k)}\right)^2}$$

### Eq. 10 — 3GPP Angular Spread (Circular Std Dev) (`eq:AS2`)
$$\sigma_{AS} = \sqrt{-2\ln\left|\frac{\sum_n\sum_m e^{j\theta_{n,m}}P_{n,m}}{\sum_n\sum_m P_{n,m}}\right|}$$
Used by NYU.

### Eq. 11 — Lognormal Mean AS Formula (`eq_meanAS`)
$$\mu_{\lg Lobe AS} = \frac{\sum_l \log_{10}(\text{Lobe AS}_l)}{L},\qquad \mu_{\lg Omni AS} = \frac{\sum_n \log_{10}(\text{Omni AS}_n)}{N}$$
Lognormal expectation for physical-scale reporting: $\mathbb{E}[X] = e^{\mu\ln 10 + (\sigma\ln 10)^2/2}$.

### Eq. 12 — Fleury Angular Spread (Squared-Distance form)
$$\sigma^\circ = \sqrt{\frac{\sum_\phi |e^{j\phi} - \mu_\phi|^2 \, \mathrm{APS}_k(\phi)}{\sum_\phi \mathrm{APS}_k(\phi)}}$$
with $\mu_\phi = \frac{\sum_\phi e^{j\phi}\mathrm{APS}_k(\phi)}{\sum_\phi \mathrm{APS}_k(\phi)}$. Equivalent form (per Table 5): $\sigma_\phi = \sqrt{1 - R^2}$ where $R = |\sum_k p_k e^{j\phi_k}/\sum_k p_k|$.

### Eq. 13 — Close-In Path Loss Model (`eq:PL_CI`)
$$\mathrm{PL}(d) = \mathrm{PL}(1~\mathrm{m}) + 10\,n\,\log_{10}(d) + X_\sigma$$
with $d_0 = 1~\mathrm{m}$ free-space reference and $X_\sigma$ zero-mean lognormal shadowing, std dev $\sigma_{SF}$.

### Eq. 14 — Lognormal Large-Scale Parameter Model
$$\log_{10}(X) \sim \mathcal{N}(\mu_X, \sigma_X^2),\quad X \in \{\sigma_\tau, \text{ASA}, \text{ASD}, \text{ZSA}, \text{ZSD}\}$$

---

## 7. Methodology Notes

### Delay-domain thresholding
- **NYU:** per-PDP threshold = `max(PDP_peak − 25 dB, NoiseFloor + 5 dB)`. Noise floor = mean of linear powers over last 250 ns of each directional PDP (then converted to dB). Applied independently to every directional PDP.
- **USC:** global threshold per TX-RX location = `max_i{NoiseFloor_i} + 12 dB`. Noise floor estimated as 25th-percentile of PDP samples + 5.41 dB (exponential-noise correction). Additional delay gating $\tau_{\text{gate}} = 966.67$ ns.

### Spatial / angular thresholding
- **NYU SLT:** 10 dB below PAS peak. Contiguous above-threshold azimuth pointings form a spatial lobe. Expanded lobe definition adds boundary MPCs at each lobe edge using the measured horn pattern angular offset where gain has dropped to the SLT value (avoids AS=0° artifacts when only one direction passes).
- **USC:** no spatial threshold; all azimuth pointings contribute to AS.

### Omnidirectional PDP synthesis
- **NYU SUM (power-sum):** Build APDS by summing directional PDPs over TX and RX elevations. Then sum APDS over PAS-thresholded azimuth pairs $(\bar\phi_T, \bar\phi_R)$ per delay bin. Antenna-boresight gain subtracted after summation (HPBW stepping preserves energy).
- **USC per-delay-max:** Same APDS construction; then per delay bin take $\max$ across all azimuth pointings. Finer-than-HPBW angular steps (10° at 145.5 GHz for 13° HPBW) require empirical gain-envelope correction (1.95 dB @ 145.5 GHz, 3.7 dB @ 6.75 GHz USC) to compensate antenna-pattern overlap.

### AS definitions
- **NYU uses 3GPP TR 38.901:** $\sigma_{AS} = \sqrt{-2\ln|R|}$ with power-weighted phasor mean $R$.
- **USC uses Fleury:** $\sigma = \sqrt{1 - R^2}$ (same $R$).
- For direct joint comparison the paper adopts 3GPP AS definition in its joint tables/figures (Tables N3, U3, and Fig. 5-8 use 3GPP). Fleury values can only be directly mapped to degrees for small AS; otherwise $R$ must be back-solved.
- Back-conversion: Fleury-AS → R → 3GPP-AS.
- Expanded spatial lobe with boundary MPCs (Shakya2025wcnc) is used for AS whenever SLT is applied.

### Statistical inference
- CI PL fit via least-squares on $(\log_{10}d_{TR}, \mathrm{PL})$ tuples with 1 m reference.
- 95% CI for PLE and for lognormal $(\mu,\sigma)$ computed via bootstrap resampling over TX-RX pairs (nonparametric) — cites Figuera 2009, Efron 1993.
- Empirical CDF bands via DKW inequality (95% confidence).
- For pooling, OLOS locations in the USC 6.75 GHz dataset are re-labeled as NLOS (aligned with 3GPP TR 38.901 modeling) — USC OLOS aligns with NYU NLOS fit per Fig. 5(b).

### Parameters reported per location in point-data tables
- TR separation distance, Omni PL, Mean Directional DS, Omni DS, Mean Lobe ASA, Omni ASA, Mean Lobe ASD, Omni ASD, Mean Lobe ZSA, Omni ZSA, Mean Lobe ZSD, Omni ZSD.

---

## 8. Dataset Description

### Sub-THz (142 GHz / 145.5 GHz)
- **NYU 142 GHz:** sliding-correlation channel sounder; MetroTech commons, Brooklyn, NY; 27 TX-RX locations (16 LOS / 11 NLOS). EIRP ≈ $P_{TX}+G_{TX}$ with $P_{TX,avg}=0$ dBm, $G_{TX}=G_{RX}=27$ dBi, HPBW 8°, 1 GHz BW, 2047 PN chip sliding correlator, 20-PDP averaging, Rubidium clock TX/RX sync, $\Delta t_s=1$ ns, $\tau_{\max}=4094$ ns, $\Delta\phi=\Delta\theta=8°$, XPD 29.2 dB, SLL −11 dB, FBR 30 dB, pyramidal horn (Mi-Wave 261D-27, D-band).
- **USC 145.5 GHz:** VNA-based RF-over-fiber sounder; USC University Park Campus, LA, CA; 26 TX-RX locations (13 LOS / 13 NLOS). $P_{TX,avg}=-1$ dBm, $G_{TX}=G_{RX}=21$ dBi, HPBW 13°, 1 GHz BW, IFBW 10 kHz, Npts=1001, VNA internal sync, $\Delta t_s=1$ ns, $\tau_{\max}=1$ μs, $\Delta\phi=\Delta\theta=10°$, SLL −13 dB, FBR 35 dB, conical horn (VDI WR-5.1, G-band), Gcorr 1.95 dB.
- **Total pooled sub-THz: 53 TX-RX locations.**

### FR1(C) / Upper Mid-Band (6.75 GHz)
- **NYU 6.75 GHz:** sliding-correlation sounder at same Brooklyn sites; 20 TX-RX locations (7 LOS / 13 NLOS). $P_{TX,avg}=15$ dBm, $G_{TX}=G_{RX}=15$ dBi, HPBW 30°, 1 GHz BW, Rb sync, pyramidal horn (Pasternack PEWAN137-15), XPD 35 dB, $\Delta\phi=\Delta\theta=30°$, FBR 25 dB.
- **USC 6.75 GHz:** VNA-based sounder at LA sites; 17 TX-RX locations (6 LOS / 11 OLOS — OLOS reclassified as NLOS for joint analysis). $P_{TX,avg}=-1$ dBm, $G_{TX}=G_{RX}=11$ dBi, HPBW 18°, 1 GHz BW, IFBW 1 kHz, Npts=1001, $\Delta\phi=\Delta\theta=10°$, pyramidal horn (Fairview HGHA618), Gcorr 3.7 dB.
- **Total pooled 6.75 GHz: 37 TX-RX locations.**

### Environment: UMi (urban microcell), static mobility, linear polarization across all four campaigns. DRmax = 40 dB for all four.

### Measurement maps referenced in other papers
- NYU 142 GHz map: Fig. 1 in Shakya2025milcom.
- USC 145.5 GHz map: Fig. 2 in Shakya2025milcom.
- NYU 6.75 GHz map: Fig. 1 in Shakya2025icc.
- USC 6.75 GHz map: Fig. 1 in abbasi2025icc.

---

## Reproduction Checklist (Derived)

To reproduce the paper's figures and Table 7 numbers, an implementation must support:
1. Per-PDP delay threshold `max(peak−25, NF+5)` dB with NF = mean(last-250-ns linear) dB (NYU mode).
2. Global delay threshold `max_i NF_i + 12` dB with NF = 25th percentile + 5.41 dB, plus delay gate 966.67 ns (USC mode).
3. APDS construction summing elevations (common).
4. Omni synthesis: SUM with 10 dB SLT & expanded lobes (NYU) and per-delay-max (USC).
5. CI PL fit with $d_0=1$ m on all TX-RX pairs; bootstrap 95% CI on PLE.
6. RMS DS via second central moment of omni PDP (Eq. 9).
7. AS per 3GPP ($\sqrt{-2\ln|R|}$) and per Fleury ($\sqrt{1-R^2}$), on PAS (pre-synthesis). Lobe expansion for NYU.
8. Lognormal fit for $\{\sigma_\tau,\text{ASA},\text{ASD},\text{ZSA},\text{ZSD}\}$ with bootstrap 95% CI on $\mu$ and $\sigma$; express mean in degrees via lognormal expectation formula.
9. DKW CDF bands at 95%.
10. Bland-Altman analysis: mean vs. difference, ±1.96 SD limits of agreement.
11. OLOS re-labeled to NLOS for pooled fits (USC 6.75 GHz only).
12. RMSE computation of cross-processed vs. original values (Table 6 reproduction).
