# Authoritative Paper-Figure MATLAB Scripts — Port Spec

This document is a faithful, line-level specification of the MATLAB scripts that produced
the paper figures, derived directly from reading the sources. It is the authoritative
reference for any Python port. All absolute paths and constants below are copied verbatim
from the scripts.

Two source codebases were read:

- **Codebase A**: `D:\NaveedDipankarMingjunJorgeShare\NaveedDipankarMingjunJorgeShare\`
  (Dipankar's older cross-processing pipeline; reads the two-row-header `.xlsx`
  point-tables `142_UMi_N3.xlsx` / `142_UMi_U3.xlsx`).
- **Codebase B**: `D:\NYU-USC\Cross-Processing\`
  (Mingjun's newer pipeline; reads consolidated `.mat`/`.xlsx` results produced by
  `ProcessingNYU142GHzData`, `ProcessingUSC145GHzData`, `ProcessingNYU7GHzData`,
  `ProcessingUSC7GHzData`).

The paper-reference figures live in
`D:\Joint-Point-Data-format-USC-NYU-Journal\figures\`, and the Codebase-B scripts
(`AS_CDF_Merged.m`, `BA_AS_Merged.m`) write directly there. Codebase A's
`paperContents/` directory contains already-rendered `.fig/.jpg/.png` reference images
— NOT scripts (see section [Codebase A paperContents](#codebase-a-papercontents)).

Scripts read in full:

| # | Script | Codebase | Role |
|---|---|---|---|
| 1 | `bland_altman_analysis.m` | A | Bland-Altman for PL/DS (Fig 3-ish in paper) |
| 2 | `cdf_ci_pl_analysis.m` | A | CI PL scatter (Fig 5) + CDF (DS/ASA/ASD) |
| 3 | `AS_CDF_Merged.m` | B | ASA/ASD CDFs (Fig 7, Fig 8) |
| 4 | `BA_AS_Merged.m` | B | Bland-Altman ASA/ASD (Fig 4) |
| 5 | `Plot_BlandAltman_PL_DS_AS.m` | B | Alternate BA generator (PL/DS/ASA/ASD) |
| 6 | `cdf_ci_pl_analysis_DS_ref.m` | B | DS CDF reference (Fig 6) |

`CDF_7GHz_Combined.m` was sampled but is NOT the paper-figure generator (it uses a
different palette and is marked "Times New Roman / LaTeX" defaults that the paper
figures do not use). It is listed at the end for completeness.

---

## Codebase A paperContents

Directory listing
(`D:\NaveedDipankarMingjunJorgeShare\NaveedDipankarMingjunJorgeShare\paperContents\`):

```
BA_ASA.fig          BA_ASA.png
BA_ASA7.fig         BA_ASA7.png
BA_ASD.fig          BA_ASD.png
BA_ASD7.fig         BA_ASD7.png
BA_DS.fig           BA_DS.jpg
BA_DS7.fig          BA_DS7.jpg
BA_PL.fig           BA_PL.jpg
BA_PL7.fig          BA_PL7.jpg
NYU_dirPDP.fig      NYU_dirPDP.jpg
OmniASA_merged.fig  OmniASA_merged7.fig
OmniASD_merged.fig  OmniASD_merged7.fig
OmniDS_merged.fig   OmniDS_merged.jpg
OmniDS_merged7.fig  OmniDS_merged7.jpg
PLcombinedPlot.fig  PLcombinedPlot.jpg
PLcombinedPlot7.fig PLcombinedPlot7.jpg
USC_dirPDP.fig      USC_dirPDP.jpg
USCpaperdiags.pptx
```

These are **pre-rendered outputs** copied from Codebase B's
`D:\Joint-Point-Data-format-USC-NYU-Journal\figures\`. No generator scripts live in
`paperContents/`; the `*7` suffix = 6.75 GHz, unsuffixed = 142/145 GHz sub-THz.
`PLcombinedPlot.*` corresponds to the CI PL scatter figure (Fig 5). No generator for
that figure was found in either codebase's top level under the literal name
`PLcombinedPlot.m`; the closest matching generator is Codebase A's
`cdf_ci_pl_analysis.m` helper `plot_ci_models` (three figures — NYU, USC, Pooled —
not a combined layout). Codebase B's `cdf_ci_pl_analysis_DS_ref.m` inherits the same
helper with distance range changed to `[1, 1000]` m and `fGHz = 6.75`. **The
published Fig 5 in the paper was almost certainly produced by an interactive session
on these files, or by a helper not checked in** — this is flagged in the
"Caveats / open questions" section at the end.

`JournalPaper/` contains only PDFs of the paper itself
(`CrossProcessingUSCNYU_draft.pdf`, `_rev.pdf`, `_revised.pdf`, `_trim.pdf`) and a
nested `ppContents/` with duplicate figure images. No scripts.

---

## Script 1 — `bland_altman_analysis.m` (Codebase A)

Full path: `D:\NaveedDipankarMingjunJorgeShare\NaveedDipankarMingjunJorgeShare\bland_altman_analysis.m`

### Inputs
Hard-coded absolute paths on the original author's machine:
- `n3Path = fullfile('C:\Users\Dipankar\Documents\MATLABExperiments\NaveedDipankarMingjunJorgeShare\USC\USCprocessNYUdata\OriginalNYU_pointData', '142_UMi_N3.xlsx')`
- `u3Path = fullfile('C:\Users\Dipankar\Documents\MATLABExperiments\NaveedDipankarMingjunJorgeShare\NYU\NYUprocessUSCdata\OriginalUSC-PointData', '142_UMi_U3.xlsx')`

Loaded via custom helper `load_ba_table` that reads the `FinalTable` sheet, scans
column A for the row starting with the literal string `'Freq.'`, treats the next
row as a sub-header, forward-fills the upper header (so a metric like `Omni PL`
repeats across its method sub-columns), and drops rows where both `TX` and `RX`
are missing.

`N3 = "NYU data processed by both NYU and USC methods"`; `U3 = "USC data processed
by both NYU and USC methods"`.

### Data filters / preprocessing
- Only rows with finite values in both the selected A-column and B-column survive
  (`valid = isfinite(a) & isfinite(b)`).
- No explicit LOS/NLOS separation — Bland-Altman is plotted over all valid
  locations regardless of environment.
- No OLOS relabeling in this script (the xlsx has only LOS/NLOS in sub-THz).
- `standardizeMissing(..., ["", " ", "nan", "NaN"])` before forward-fill.

### Core computation per subfigure
Four per-case single-plot figures (one metric × one dataset each):

| Case | Table | Metric (h1) | Method A (h2) | Method B (h2) |
|---|---|---|---|---|
| 1 | N3 | `Omni PL`  | `NYU thres`  | `NYU orig. (N1)` |
| 2 | N3 | `Omni DS`  | `NYU thres`  | `NYU orig. (N1)` |
| 3 | U3 | `Omni PL`  | `USC thres`  | `USC orig. (U1)` |
| 4 | U3 | `Omni DS`  | `USC thres`  | `USC orig. (U1)` |

Each single plot computes: `meanVals = (a+b)/2`, `diffVals = a - b`,
`bias = mean(diffVals)`, `sd = std(diffVals)`,
`loaUpper = bias + 1.96*sd`, `loaLower = bias - 1.96*sd`.

Then TWO combined dual-axis figures are made (PL and DS), each via
`plot_bland_altman_combined_dualaxis`. NOTE the asymmetry: for `diff1` (N3) it
computes `diff1 = a1 - b1`; for `diff2` (U3) it computes `diff2 = b2 - a2` (sign
flipped) — this is because the author wants "thres - orig" on both axes to read
in the same direction. Port faithfully: **U3 axis uses B - A, N3 axis uses A - B**.

### Figure layout (dual-axis combined)
- Single axes with `yyaxis left` (N3, blue circles) + `yyaxis right` (U3, salmon
  squares).
- `figure('Position', [250, 250, 900, 550])`.
- Both y-axes are forced to the same y-limits at the end
  (`yMin = min(allDiff)`, `yMax = max(allDiff)`).
- `xlabel('Mean of paired methods')`. Left ylabel `'N3: NYU thres - NYU orig.'`;
  Right ylabel `'U3: USC thres - USC orig.'`.
- Title is the label passed in (e.g. `'Bland-Altman: Omni PL (N3 vs U3)'`).
- Legend `'Location', 'best'` shows both scatter handles.

### Scatter point count per subplot
Reading the CSV parity data:
- **N3 (NYU sub-THz data)**: 16 LOS + 11 NLOS = **27** points (when TX/RX present).
- **U3 (USC sub-THz data)**: 13 LOS + 13 NLOS = **26** points.
- Combined dual-axis figure: **27 blue circles + 26 salmon squares overlaid** = 53
  markers on one axes.

### Style
- `scatter(..., 50, 'filled')` for simple single-case; for combined dual-axis:
  - N3 marker: `'o'`, edge `[0 0.45 0.74]`, face `[0.60 0.78 0.92]`, size 50
  - U3 marker: `'s'`, edge `[0.85 0.33 0.10]`, face `[0.98 0.78 0.68]`, size 50
- Bias line: solid color (`'b-'` N3, `'r-'` U3) `LineWidth 1.2`.
- ±1.96 SD lines: dashed `LineWidth 1.0`.
- All `yline` calls include text labels like `'Bias (N3)'`, `'+1.96 SD (N3)'`
  with `'LabelHorizontalAlignment', 'left'`.
- Grid on. No explicit font-size set (uses MATLAB defaults ≈ 10 pt).

### Saved file paths
None — this script only calls `figure(...)` and does not save/export. (Figures
are captured manually by the author.)

### Notable variable names to preserve
`n3`, `u3` (struct with `headers1`, `headers2`, `data`). Functions:
`load_ba_table`, `get_metric_pair`, `fill_header`, `to_num`, `plot_bland_altman`,
`plot_bland_altman_combined_dualaxis`.

---

## Script 2 — `cdf_ci_pl_analysis.m` (Codebase A)

Full path: `D:\NaveedDipankarMingjunJorgeShare\NaveedDipankarMingjunJorgeShare\cdf_ci_pl_analysis.m`

### Inputs
Same two xlsx files as Script 1:
- `142_UMi_N3.xlsx` (FinalTable sheet, two-row header)
- `142_UMi_U3.xlsx` (FinalTable sheet, two-row header)

Loaded via `load_stats_table` (identical to `load_ba_table` minus the TX/RX drop
step). `get_col(T, metric, method)` does the two-row-header lookup — if
`method == ""`, it uses only the first (forward-filled) header. This is how
`'Loc Type'` and `'TR Sep'` are fetched.

### Columns extracted (per dataset)
From N3 (NYU sub-THz, processed by NYU original = N1):
- `n3_loc = get_col(n3, 'Loc Type', '')`   → string vector of LOS/NLOS/(OLOS)
- `n3_d   = get_col(n3, 'TR Sep', '')`     → distance (m)
- `n3_pl  = get_col(n3, 'Omni PL',  'NYU orig. (N1)')`
- `n3_ds  = get_col(n3, 'Omni DS',  'NYU orig. (N1)')`
- `n3_asa = get_col(n3, 'Omni ASA', 'NYU orig. (N1)')`
- `n3_asd = get_col(n3, 'Omni ASD', 'NYU orig. (N1)')`

From U3 (USC sub-THz, processed by USC original = U1): same schema with
`'USC orig. (U1)'` as the second-header.

### Data filters / preprocessing
- Masks: `n3_isLOS = strcmpi(string(n3_loc),'LOS')`, `n3_isNLOS = strcmpi(..., 'NLOS')`,
  same for U3. **No OLOS handling in this file** — sub-THz data doesn't have
  OLOS entries.
- `ecdf_with_dkw` drops `~isfinite` and non-positive values before ECDF
  (`vals = vals(isfinite(vals) & vals > 0)`).
- `plot_ci_fit` drops non-finite and `d <= 0` before fit.

### Core computation

**CDFs (3 figures — one per metric):**
Metrics = `{'Omni DS', 'Omni ASA', 'Omni ASD'}`. Each calls `plot_cdf_group` →
figure with `subplot(1,2,1)` for LOS and `subplot(1,2,2)` for NLOS. Each subplot
draws THREE curves:
1. NYU only (`n3_vals(n3_isLOS)` etc.) — color `[0 0.45 0.74]` (blue)
2. USC only (`u3_vals(u3_isLOS)`) — color `[0.85 0.33 0.10]` (orange/red)
3. Pooled NYU+USC — color `[0.2 0.2 0.2]` (dark gray)

Each curve has a matching DKW 95% band filled as `fill(..., 'FaceAlpha', 0.12,
'EdgeColor', 'none')`. DKW formula: `eps = sqrt(log(2/0.05) / (2*n))`,
`f_lo = max(0, f-eps)`, `f_hi = min(1, f+eps)` (Dvoretzky-Kiefer-Wolfowitz
uniform band at α = 0.05).

So per CDF subplot: **3 curves + 3 shaded bands**. Legend enumerates all six:
`'NYU','NYU 95% band','USC','USC 95% band','Pooled','Pooled 95% band'`,
`'Location', 'best'`.

**CI Path Loss model (3 figures):**
Constants: `fGHz = 142`, `d0 = 1`.
Three figures, one each for `'NYU Data (N3)'`, `'USC Data (U3)'`,
`'Pooled NYU+USC'`. Each plots LOS (blue circles) AND NLOS (orange squares)
scatter + fit line + bootstrap 95% band on a single axes (not subplots).

CI fit: `fspl0 = 32.44 + 20*log10(fGHz) + 20*log10(d0)`,
`D = 10*log10(d/d0)`, `A = pl - fspl0`, `n = (A'*D) / (D'*D)` (closed-form
slope-through-origin). `sigma = sqrt(sum((pl-yhat).^2)/numel(yhat))`.

Bootstrap: `nboot = 500` (for plot band) or `1000` (for CI-width summary),
`dgrid = linspace(1, 200, 100)'`, resample indices with `randi(numel(d), numel(d), 1)`,
refit `nb`, compute `yhat_boot(b,:) = fspl0 + nb*Dg`, band is
`prctile(yhat_boot, [2.5 97.5], 1)`. n-CI is `prctile(n_boot, [2.5 97.5])`.

### Figure layout
**CDF group** (per metric):
- `figure('Position', [200, 200, 1000, 420])`.
- `subplot(1,2,1)` LOS, `subplot(1,2,2)` NLOS.
- `grid on; box on;`.
- Titles `'Omni DS CDF (LOS)'`, `'Omni DS CDF (NLOS)'`, etc.
- `xlabel(metricName)`, `ylabel('CDF')`.

**CI PL**:
- `figure('Position', [200, 200, 900, 500])`.
- `set(gca, 'XScale', 'log')`, `xlim([1, 200])` (sub-THz variant).
- `xlabel('Distance (m)'); ylabel('Path Loss (dB)')`.
- Legend: `'LOS data','LOS fit','LOS 95% band','NLOS data','NLOS fit','NLOS 95% band'`.

### Scatter point count per subplot (CI PL figures)
- **NYU Data (N3) figure**: 16 LOS circles + 11 NLOS squares = **27 dots**.
- **USC Data (U3) figure**: 13 LOS circles + 13 NLOS squares = **26 dots**.
- **Pooled NYU+USC figure**: 29 LOS circles + 24 NLOS squares = **53 dots**.

### Scatter point count per subplot (CDF subplots — pooled curve)
Each LOS subplot pooled curve: 16+13 = 29 data points.
Each NLOS subplot pooled curve: 11+13 = 24 data points.
(Individual NYU/USC curves have their own counts.) No scatter on CDF — only
line + shaded band.

### Style
- Line color tuples (RGB 0-1):
  - NYU: `[0 0.45 0.74]`
  - USC: `[0.85 0.33 0.10]`
  - Pooled: `[0.2 0.2 0.2]`
- `plot(..., 'LineWidth', 1.6)` for CDF curves.
- CI scatter: `scatter(d, pl, 25, marker, 'MarkerEdgeColor', color, 'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.6)`.
- CI fit line: `plot(dgrid, pl_fit, 'Color', color, 'LineWidth', 1.6)`.
- CI band: `fill(..., 'FaceAlpha', 0.15, 'EdgeColor', 'none')`.
- CDF band: `FaceAlpha 0.12`.
- No explicit font size — uses default.

### Saved file paths
None — script does not call `saveas`, `savefig`, `exportgraphics`, or `print`.

### Notable variable names
`n3`, `u3`, `fspl0`, `D`, `A` (regression variables), `yhat_boot`, `n_boot`,
`dgrid`, `Dg`. Helpers: `load_stats_table`, `get_col`, `fill_header`, `to_num`,
`plot_cdf_group`, `plot_cdf_with_band`, `plot_ci_models`, `plot_ci_fit`,
`bootstrap_ci_summary`, `summarize_bootstrap`, `print_mean_log_metric`,
`print_logmean`.

---

## Script 3 — `AS_CDF_Merged.m` (Codebase B) — Fig 7 (ASA) & Fig 8 (ASD)

Full path: `D:\NYU-USC\Cross-Processing\AS_CDF_Merged.m`

### Inputs — loaded as `.mat` files
```
basePath      = 'D:\NYU-USC\Cross-Processing';
figOutputPath = 'D:\Joint-Point-Data-format-USC-NYU-Journal\figures';

nyu142Path = basePath\ProcessingNYU142GHzData\Results\all_comparison_results.mat
usc145Path = basePath\ProcessingUSC145GHzData\Results\USC145GHz_Full_Results.mat
nyu7Path   = basePath\ProcessingNYU7GHzData\Results\all_comparison_results.mat
usc7Path   = basePath\ProcessingUSC7GHzData\Results\USC7GHz_Full_Results.mat
```
Each `.mat` contains a single variable `results` (a MATLAB `table`). Columns used
(by name, not position):

- NYU 142 GHz: `Environment`, `ASA_NYU_10dB`, `ASD_NYU_10dB`, plus `_USC` siblings.
- USC 145 GHz: `Environment`, `ASA_USC`, `ASD_USC`.
- NYU 7 GHz: `Environment`, `ASA_NYUthr_N10`, `ASD_NYUthr_N10` (NYU threshold group,
  10 dB PAS).
- USC 7 GHz: `Environment`, `ASA_USC`, `ASD_USC`.

### Data filters / preprocessing
```matlab
nyu142_isLOS  = strcmpi(string(nyu142_r.Environment), 'LOS');
nyu142_isNLOS = strcmpi(string(nyu142_r.Environment), 'NLOS');
usc145_isLOS  = strcmpi(string(usc145_r.Environment), 'LOS');
usc145_isNLOS = strcmpi(string(usc145_r.Environment), 'NLOS');

% 6.75 GHz — OLOS RELABELED → NLOS
nyu7_isLOS  = strcmpi(string(nyu7_r.Environment), 'LOS');
nyu7_isNLOS = strcmpi(string(nyu7_r.Environment), 'NLOS') | ...
              strcmpi(string(nyu7_r.Environment), 'OLOS');
usc7_isLOS  = strcmpi(string(usc7_r.Environment), 'LOS');
usc7_isNLOS = strcmpi(string(usc7_r.Environment), 'NLOS') | ...
              strcmpi(string(usc7_r.Environment), 'OLOS');
```

`clean_vals(vals)` = `vals(isfinite(vals) & vals > 0)` — strips NaN, Inf, and zero.
The ECDF helper also internally filters with the same condition.

### Core computation
`generate_as_cdf_figure(metricName, freqLabel, nyu_vals, usc_vals, ...)` is called
4 times → 4 output figures:

| Figure filename | metric | freqLabel | NYU column | USC column |
|---|---|---|---|---|
| `OmniASA_merged`   | ASA | sub-THz  | `ASA_NYU_10dB`    | `ASA_USC` |
| `OmniASD_merged`   | ASD | sub-THz  | `ASD_NYU_10dB`    | `ASD_USC` |
| `OmniASA_merged7`  | ASA | 6.75 GHz | `ASA_NYUthr_N10`  | `ASA_USC` |
| `OmniASD_merged7`  | ASD | 6.75 GHz | `ASD_NYUthr_N10`  | `ASD_USC` |

Each figure has `subplot(1,2,1)` LOS + `subplot(1,2,2)` NLOS. Each subplot:
1. Compute NYU-only DKW band (`ecdf_with_dkw` → x, f, flo, fhi).
2. Compute USC-only DKW band.
3. Compute Pooled = [nyu; usc] DKW band.
4. Draw bands first (`plot_band`) with alpha 0.12 for NYU+USC, 0.10 for pooled.
5. **Overwrite pooled band with dashed boundary lines**:
   `plot(xP, fPlo, '--', 'Color', cPooled, 'LineWidth', 1.5)`
   `plot(xP, fPhi, '--', 'Color', cPooled, 'LineWidth', 1.5)` — the pooled band
   uses dashed blue lines, not a filled region, on top of the faint 0.10-alpha
   fill. (This is unique to this script — the DS reference does the same.)
6. Draw NYU and USC ECDF lines, `LineWidth 2.2`.
7. Scatter the pooled ECDF **points** (not connected) on top:
   `scatter(xP, fP, 70, mk, 'MarkerEdgeColor', cPooled, 'LineWidth', 2.0,
   'MarkerFaceColor', 'none')`. Marker is `'o'` (circle) for LOS panel, `'d'`
   (diamond) for NLOS panel.

### Figure layout
- `figure('Position', [140, 140, 1400, 520], 'Color', 'w')`.
- `subplot(1, 2, 1)` LOS, `subplot(1, 2, 2)` NLOS.
- `hold on; grid on; box on;`.
- Axes styled by `style_cdf_axes`: `ax.FontSize = 19; ax.GridAlpha = 0.2;
  ax.LineWidth = 0.8;`.
- Title: `sprintf('LOS Omni RMS %s %s', metricName, freqLabel)` or `'NLOS ...'`.
- xlabel: `sprintf('Omni RMS %s (%c)', metricName, char(176))` — a literal
  degree sign.
- ylabel: `'Probability'`.
- `xlim([0, ceil(1.05 * max(pooledVals))])`, `ylim([0, 1])`.
- Legend: southeast, FontSize 15, entries
  `{'USC+NYU','NYU','NYU 95% band','USC','USC 95% band','USC+NYU 95% band'}`.
- In-panel text annotation `add_logstat_text` — log10 pooled stats printed as
  `\\mu(lg(ASA^{USC+NYU}_{sub-THz})) = 1.24`
  `\\sigma(lg(ASA^{USC+NYU}_{sub-THz})) = 0.21`
  at `(0.97, 0.58)` normalized, right/top, `FontSize 17`, bold, `Interpreter 'tex'`.
  For `6.75 GHz`, the freqLabel is munged to `'6.75'` via `strrep`.

### Scatter/curve count per subplot
**Sub-THz panels** (Fig 7 ASA LOS, NLOS; Fig 8 ASD LOS, NLOS):
- NYU curve: 16 LOS (or 11 NLOS) data points (ECDF steps).
- USC curve: 13 LOS (or 13 NLOS).
- Pooled scatter = 29 open-circle markers (LOS) / 24 open-diamond markers (NLOS).
- Band shading: 3 regions (one per curve) + 2 dashed pooled-boundary lines.

**6.75 GHz panels** (after OLOS→NLOS relabel):
- NYU: 6 LOS / 12 NLOS (NYU has 6 LOS + 12 NLOS after OLOS relabel — verified
  from CSV).
- USC: 0 LOS / 8 NLOS (USC 7 GHz has no LOS entries).
  → **LOS subplot shows only the NYU curve + its band**. `plot_cdf_panel` must
  tolerate empty `uscVals` (the `ecdf_with_dkw` returns empty arrays, and
  `plot_band` short-circuits to `patch(NaN, NaN, ...)`).
- Pooled scatter LOS = 6 circles; Pooled scatter NLOS = 20 diamonds.

### Style (colors)
- `colorNYU    = [0.49 0.13 0.55]`   (violet)
- `colorUSC    = [0.85 0.00 0.10]`   (red)
- `colorPooled = [0.10 0.15 0.90]`   (blue)
- CDF line width **2.2**; DKW band alpha 0.12 (individual) / 0.10 (pooled);
  pooled dashed boundary `LineWidth 1.5`; scatter marker size **70**, edge
  `LineWidth 2.0`, **face `'none'`** (open markers).

### Saved file paths
For each of the 4 figures:
- `fullfile(figOutputPath, [baseName '.jpg'])` via
  `exportgraphics(fig, jpgPath, 'Resolution', 300, 'BackgroundColor', 'white')`
- `fullfile(figOutputPath, [baseName '.fig'])` via `saveas(fig, figPath)`

i.e.
```
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\OmniASA_merged.{jpg,fig}
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\OmniASA_merged7.{jpg,fig}
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\OmniASD_merged.{jpg,fig}
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\OmniASD_merged7.{jpg,fig}
```
`close(fig)` after save.

### Notable variable names
`nyu142_r`, `usc145_r`, `nyu7_r`, `usc7_r` (all are `.results` tables).
Helpers: `generate_as_cdf_figure`, `plot_cdf_panel`, `style_cdf_axes`,
`clean_vals`, `plot_band`, `ecdf_with_dkw`, `add_logstat_text`, `build_legend`.

---

## Script 4 — `BA_AS_Merged.m` (Codebase B) — Fig 4

Full path: `D:\NYU-USC\Cross-Processing\BA_AS_Merged.m`

### Inputs
Same four `.mat` files as Script 3. Columns used (per `generate_ba_figure` call):

| Output | metric | freq | N3 col A (NYU method) | N3 col B (USC method) | U3 col A | U3 col B |
|---|---|---|---|---|---|---|
| `BA_ASA`   | ASA | 142 GHz | `nyu142_r.ASA_NYU_10dB`    | `nyu142_r.ASA_USC`        | `usc145_r.ASA_NYU_10dB` | `usc145_r.ASA_USC` |
| `BA_ASD`   | ASD | 142 GHz | `nyu142_r.ASD_NYU_10dB`    | `nyu142_r.ASD_USC`        | `usc145_r.ASD_NYU_10dB` | `usc145_r.ASD_USC` |
| `BA_ASA7`  | ASA | 7 GHz   | `nyu7_r.ASA_NYUthr_N10`    | `nyu7_r.ASA_NYUthr_U`     | `usc7_r.ASA_NYU_10dB`   | `usc7_r.ASA_USC` |
| `BA_ASD7`  | ASD | 7 GHz   | `nyu7_r.ASD_NYUthr_N10`    | `nyu7_r.ASD_NYUthr_U`     | `usc7_r.ASD_NYU_10dB`   | `usc7_r.ASD_USC` |

Note that N3's method B at 7 GHz is `ASA_NYUthr_U` — the USC-style-method value
computed on NYU-threshold-filtered data. At sub-THz it's the straight
`ASA_USC` column.

### Data filters / preprocessing
`v = isfinite(a) & isfinite(b) & a > 0 & b > 0` for both N3 and U3 pairs
independently. **No LOS/NLOS separation** — all environments are mixed in one
Bland-Altman cloud.

### Core computation
```matlab
diff_n3 = n3_b - n3_a;   % USC method - NYU method  (IMPORTANT: B - A)
mean_n3 = (n3_a + n3_b) / 2;
diff_u3 = u3_b - u3_a;
mean_u3 = (u3_a + u3_b) / 2;

bias_n3 = mean(diff_n3); sd_n3 = std(diff_n3);
upper_n3 = bias_n3 + 1.96 * sd_n3;
lower_n3 = bias_n3 - 1.96 * sd_n3;
% same for U3
```

y-range computed as:
```matlab
allUpper = max([upper_n3, upper_u3]);
allLower = min([lower_n3, lower_u3]);
yMargin  = 0.15 * (allUpper - allLower);  (or 5 if zero)
yRange   = [min([diff_n3; diff_u3; lower_n3; lower_u3]) - yMargin,
            max([...; upper_n3; upper_u3]) + yMargin];
```
x-range uses 0.05 * range of combined means (or 5 if zero).

### Figure layout
- `figure('Position', [140, 140, 1200, 600], 'Color', 'w')`.
- Single primary axes (`ax1`) with ALL scatter + yline calls.
- A second transparent axes (`ax2`) is overlaid (same Position, no XTick,
  `YAxisLocation 'right'`, `Color 'none'`) purely to render a colored right-side
  ylabel. `linkaxes([ax1, ax2], 'y')`. `ax2.YTick = ax1.YTick`.
- `hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');`.

Scatter:
- N3: `scatter(ax1, mean_n3, diff_n3, 120, 'o', 'MarkerFaceColor', colorN3fill,
  'MarkerEdgeColor', colorN3, 'LineWidth', 1.8)`.
- U3: `scatter(ax1, mean_u3, diff_u3, 120, 's', 'MarkerFaceColor', colorU3fill,
  'MarkerEdgeColor', colorU3, 'LineWidth', 1.8)`.

Lines:
- Bias N3: `yline(ax1, bias_n3, '-', 'Color', colorN3, 'LineWidth', 2.0)`.
- ±1.96 SD N3: `yline(..., '--', 'Color', colorN3, 'LineWidth', 1.8)`.
- Same for U3 in its color.

Text labels (manually placed — NOT using `yline` `Label` parameter):
- Left side, blue, `'Bias (N3)'` at `(xRange(1)+0.02*range, bias_n3)`,
  `FontSize 24`, bold, vertical bottom.
- `'+1.96 SD (N3)'` at `(xRange(1)+0.02*range, upper_n3)`, `FontSize 22`.
- `'-1.96 SD (N3)'` at `(xRange(1)+0.02*range, lower_n3)`, `FontSize 22`, top.
- Right side, red, same pattern using `xRange(2) - 0.02*range`, right-aligned.

Axis labels:
- Left ylabel: `sprintf('N3: NYU Data | %s - %s', methodBname, methodAname)`,
  e.g. `'N3: NYU Data | USC - NYU 10 dB PAS'`, `FontSize 26`, `Color colorN3`.
- Right ylabel (on ax2): `sprintf('U3: USC Data | %s - %s', ...)`, same format,
  `FontSize 26`, `Color colorU3`.
- xlabel (on ax1): `sprintf('Mean of %s [%s] ((%s + %s)/2)', metricName, char(176),
  methodAname, methodBname)`, `FontSize 26`.
- Title: `sprintf('Bland-Altman: Omni %s (N3 vs U3) @ %s', metricName, freqLabel)`,
  `FontSize 28`, bold.
- Axes `FontSize 24`.
- Legend: southeast(ish) "best", `FontSize 22`, two entries (N3 scatter, U3 scatter).

### Scatter point count per subplot
Each figure has ONE combined axes with N3 (blue circles) + U3 (orange squares).
- **Sub-THz (BA_ASA, BA_ASD)**: 27 circles (NYU 142) + 26 squares (USC 145) = **53 markers**.
- **6.75 GHz (BA_ASA7, BA_ASD7)**: 18 circles (NYU 7: 6 LOS + 12 NLOS) + 8 squares (USC 7: 0 LOS + 8 NLOS) = **26 markers**.

(Assuming no additional NaN drops; `isfinite & > 0` filter applied — in practice
a handful may drop for some metrics, so 53/26 are upper bounds.)

### Style (colors)
- `colorN3     = [0 0.45 0.74]`       blue (N3 scatter edge, bias line, +1.96/-1.96 SD line)
- `colorN3fill = [0.60 0.78 0.92]`    light blue (N3 scatter face)
- `colorU3     = [0.85 0.33 0.10]`    orange-red
- `colorU3fill = [0.98 0.78 0.68]`    salmon

### Saved file paths
Per figure (4 total):
```
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\<baseName>.jpg   (exportgraphics 300 dpi)
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\<baseName>.png   (exportgraphics 300 dpi)
D:\Joint-Point-Data-format-USC-NYU-Journal\figures\<baseName>.fig   (saveas)
```
Followed by `close(fig)`. Figure n printed to console: `'N3: Bias=..., SD=..., n=...'`.

### Notable variable names
`n3_methodA`, `n3_methodB`, `u3_methodA`, `u3_methodB`, `bias_n3`, `upper_n3`,
`lower_n3` (ditto U3), `ax1`, `ax2`, `yRange`, `xRange`.

---

## Script 5 — `Plot_BlandAltman_PL_DS_AS.m` (Codebase B)

Full path: `D:\NYU-USC\Cross-Processing\Plot_BlandAltman_PL_DS_AS.m`

This is an **alternate** BA generator that reads the `.xlsx` tables (not `.mat`)
and writes to a local `BlandAltman_Figures/` subfolder (not the paper figures
folder). It covers PL, DS, ASA, ASD at sub-THz ONLY. It was superseded by
`BA_AS_Merged.m` for AS and (presumably) by a PL/DS analog that isn't
checked in.

### Inputs
- `nyuPath = D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Results\NYU142GHz_Method_Comparison_Results.xlsx`
- `uscPath = D:\NYU-USC\Cross-Processing\ProcessingUSC145GHzData\Results\USC145GHz_Full_Results.xlsx`
- Output folder: `D:\NYU-USC\Cross-Processing\BlandAltman_Figures\` (auto-created).

Loaded via `readtable` (no header munging — these xlsx are already flat).

### Column pairs (per metric)
```matlab
metrics = {
  'Omni PL', 'PL_NYU_SUM_dB', 'PL_USC_perDelayMax_dB',
             'PL_NYU_dB',      'PL_USC_dB',             'dB',  'PL';
  'Omni DS', 'DS_NYU_SUM_ns', 'DS_USC_perDelayMax_ns',
             'DS_NYU_ns',      'DS_USC_ns',             'ns',  'DS';
  'ASA',     'ASA_NYU_10dB',  'ASA_USC',
             'ASA_NYU_10dB',   'ASA_USC',               'deg', 'ASA';
  'ASD',     'ASD_NYU_10dB',  'ASD_USC',
             'ASD_NYU_10dB',   'ASD_USC',               'deg', 'ASD';
};
```
Key difference from `BA_AS_Merged.m`: **PL and DS use different NYU-method
columns for N3 vs U3**. On N3 (NYU 142 data): NYU method = SUM omni power,
USC method = perDelayMax omni power. On U3 (USC 145 data): `PL_NYU_dB` vs
`PL_USC_dB` directly — USC data does not carry the per-method breakdown.

### Data filters / preprocessing
Per pair: `valid = isfinite(a) & isfinite(b)`. No LOS/NLOS split. No OLOS (sub-THz
only).

### Core computation
Two loops:
1. **Individual plots** (not saved) — for each metric × each dataset, draw a
   single-axes Bland-Altman (`plot_bland_altman`). 4 metrics × 2 datasets = 8
   figures.
2. **Combined plots (saved)** — for each metric, `plot_bland_altman_combined`
   draws NYU data (blue circles, `diff1 = a1 - b1`) and USC data (orange
   squares, `diff2 = a2 - b2`) on ONE axes with shared y. 4 figures.

### Figure layout (individual)
- `figure('Position', [200, 200, 900, 550])`.
- `scatter(..., 60, 'filled', 'MarkerFaceAlpha', 0.7)`.
- `yline(bias, 'k-', LineWidth 1.5, Label 'Bias = ...')`.
- `yline(±1.96 SD, 'r--', LineWidth 1.2, Label '+1.96 SD = ...')`.
- `annotation('textbox', [0.70 0.75 0.22 0.15], ...)` with bias/SD/n.
- xlabel/ylabel use `to_tex_unit` — `[$^\circ$]`, `[dB]`, `[ns]`; `Interpreter 'tex'`.

### Figure layout (combined)
- `figure('Position', [250, 250, 1000, 550])`.
- NYU: `scatter(mean1, diff1, 60, 'o', edge [0 0.45 0.74], face [0.60 0.78 0.92],
  LineWidth 1)`.
- USC: `scatter(mean2, diff2, 60, 's', edge [0.85 0.33 0.10], face [0.98 0.78 0.68],
  LineWidth 1)`.
- NYU yline colors match NYU, USC yline colors match USC.
- NYU `yline` labels horizontally left; USC labels right.
- Legend best, entries include `n=` counts.
- xlabel: `'Mean of NYU and USC methods [...]'`.
- ylabel: `'Difference (NYU - USC) [...]'`.
- Title: `'Bland-Altman: <metric> [<unit>] (NYU vs USC Data)'`.

### Scatter counts
Combined figures: **27 NYU circles + 26 USC squares = 53 markers per panel**
(PL, DS, ASA, ASD — same population as Script 4 sub-THz).

### Saved file paths (combined only)
```
D:\NYU-USC\Cross-Processing\BlandAltman_Figures\BlandAltman_PL.fig
D:\NYU-USC\Cross-Processing\BlandAltman_Figures\BlandAltman_PL.png       (300 dpi)
D:\NYU-USC\Cross-Processing\BlandAltman_Figures\BlandAltman_PL.pdf       (vector)
D:\NYU-USC\Cross-Processing\BlandAltman_Figures\BlandAltman_DS.{fig,png,pdf}
D:\NYU-USC\Cross-Processing\BlandAltman_Figures\BlandAltman_ASA.{fig,png,pdf}
D:\NYU-USC\Cross-Processing\BlandAltman_Figures\BlandAltman_ASD.{fig,png,pdf}
```
Individual plots are NOT saved.

### Notable variable names
`metrics` cell array, `to_tex_unit`, `to_plain_unit`, `plot_bland_altman`,
`plot_bland_altman_combined`, `fileTag`.

---

## Script 6 — `cdf_ci_pl_analysis_DS_ref.m` (Codebase B) — Fig 6

Full path: `D:\NYU-USC\Cross-Processing\cdf_ci_pl_analysis_DS_ref.m`

This is the **DS CDF reference script at 6.75 GHz** (the code has sub-THz
`.xlsx` paths commented out at the top; the live version uses `7_UMi_N3.xlsx`
and `7_UMi_U3.xlsx`, and `fGHz = 6.75`). Its figure style is the one
`AS_CDF_Merged.m` explicitly mimics.

### Inputs
**Active (uncommented) paths**:
- `n3Path = 'C:\Users\Dipankar\...\USC\USCprocessNYUdata\OriginalNYU_pointData\7_UMi_N3.xlsx'`
- `u3Path = 'C:\Users\Dipankar\...\NYU\NYUprocessUSCdata\OriginalUSC-PointData\7_UMi_U3.xlsx'`

Commented-out (sub-THz) variants:
- `142_UMi_N3.xlsx` and `142_UMi_U3.xlsx` — the authors toggle between the two
  by editing the source. The DS-ref figure in the paper is the 6.75 GHz flavor.

Loaded by `load_stats_table` (two-row header reader, same as Script 2).

### Columns extracted
Same as Script 2: `Loc Type`, `TR Sep`, `Omni PL`, `Omni DS`, `Omni ASA`,
`Omni ASD`, with method `NYU orig. (N1)` on N3 and `USC orig. (U1)` on U3.

### Data filters / preprocessing
**OLOS HANDLING — this is the key difference from Script 2**:
```matlab
n3_isLOS  = strcmpi(string(n3_loc), 'LOS');
n3_isNLOS = strcmpi(string(n3_loc), 'NLOS');
u3_isLOS  = strcmpi(string(u3_loc), 'LOS');
u3_isNLOS = strcmpi(string(u3_loc), 'NLOS');
u3_isOLOS = strcmpi(string(u3_loc), 'OLOS');       % <--- tracked separately
```
Then for every plot / bootstrap / stats call, U3's "NLOS" slot receives
`u3_isOLOS`, NOT `u3_isNLOS`:
```matlab
plot_cdf_group(metricName, n3_vals, u3_vals, n3_isLOS, n3_isNLOS, u3_isLOS, u3_isOLOS);
plot_ci_models('USC Data (U3)', ..., u3_isLOS, u3_isOLOS, fGHz, d0);
plot_ci_models('Pooled NYU+USC', [n3_d; u3_d], [n3_pl; u3_pl], ...
    [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isOLOS], fGHz, d0);
```
i.e. in the 6.75 GHz source xlsx, USC's "NLOS" entries are labeled **OLOS** in
the `Loc Type` column. The script chooses to call `u3_isOLOS` the NLOS group
for the USC-side AND uses `[n3_isNLOS; u3_isOLOS]` for the pooled NLOS set.
USC's rows tagged `'NLOS'` (if any) are **excluded** from the NLOS curve — this
is the inverse of `AS_CDF_Merged.m`'s behavior (which OR's NLOS|OLOS). Port
must respect whichever is the authoritative data model for the target figure.

**`ecdf_with_dkw` filter**: `vals(isfinite(vals) & vals > 0)` — strips NaN, Inf,
and non-positive.

**`sanitize_numeric_vec`**: same filter applied up-front.

### Core computation
Same CDF helpers as `AS_CDF_Merged.m`, but:
- Title uses `'sub-THz'` suffix hard-coded (even when the file is 6.75 GHz!)
  — `title(['LOS ' strrep(metricName, 'Omni ', 'Omni RMS ') ' sub-THz'])`. This
  is a known bug in the source; for the paper's 6.75 GHz figure, titles say
  "sub-THz" incorrectly. Port should parametrize.
- `add_logstat_text` annotation is placed at `(0.97, 0.08)` normalized
  (bottom-right) with `FontSize 11`, NOT `(0.97, 0.58)` / `FontSize 17` like
  `AS_CDF_Merged`. Interpreter is `'tex'` via `\\mu`, `\\sigma` escapes.
  Also: the format string contains a literal `\\n` (double-backslash) inside
  `sprintf` which renders as `\n` in MATLAB's text (NOT a real newline).
  This is a rendering artifact in the source.

**CI PL**: `fGHz = 6.75`, `d0 = 1`, `xlim([1, 1000])` (note 1000 m, not 200 m
like Script 2). `dgrid = linspace(1, 1000, 100)'`. `nboot = 1000` for both plot
bands and summary.

**Additional stats**: `bootstrap_logstat_summary` computes 95% CIs for log10
mean and sd of DS/ASA/ASD, plus a log-normal linear-domain mean. These go to
stdout only (not plotted).

### Figure layout (DS CDF — Fig 6)
- `figure('Position', [140, 140, 1400, 520], 'Color', [0.94 0.94 0.94])` —
  **background is 0.94 gray**, not white. This is the ONLY paper figure with
  gray background. Port must preserve.
- `subplot(1,2,1)` LOS, `subplot(1,2,2)` NLOS (really NLOS|OLOS for U3).
- `style_cdf_axes`: `FontSize 14, GridAlpha 0.2, LineWidth 0.8`.
- xlabel via `cdf_xlabel`: `'Omni RMS DS [ns]'`, `'Omni RMS ASA [deg]'`,
  `'Omni RMS ASD [deg]'`.
- ylabel `'Probability'`.
- `xlim([0, ceil(1.05*xmax)])` where `xmax = max(pooledVals)`.
- `ylim([0, 1])`.

### Colors
- `cPooled = [0.10 0.15 0.90]`   blue
- `cNYU    = [0.49 0.13 0.55]`   violet
- `cUSC    = [0.85 0.00 0.10]`   red

Same violet/red/blue convention as `AS_CDF_Merged.m`.

### Curves per subplot (DS CDF, Fig 6)
Per subplot (LOS or NLOS):
- NYU CDF line (violet, LineWidth 2.2)
- NYU DKW band (violet fill, alpha 0.12)
- USC CDF line (red, LineWidth 2.2)
- USC DKW band (red fill, alpha 0.12)
- Pooled DKW band (blue fill, alpha 0.10)  — drawn as a fill AND then
  **overdrawn** with the pooled band variable reassigned to a dashed line:
  ```matlab
  hPooledBand = plot(xP, fPlo, '--', 'Color', cPooled, 'LineWidth', 1.5);
  plot(xP, fPhi, '--', 'Color', cPooled, 'LineWidth', 1.5);
  ```
  **Wait** — checking Script 6 source: `cdf_ci_pl_analysis_DS_ref.m` (lines
  199-244) does NOT have the dashed pooled boundary override that
  `AS_CDF_Merged.m` has. It only has `plot_band(xP, fPlo, fPhi, cPooled, 0.10)`
  (a single filled region, alpha 0.10, no dashed lines). So the DS CDF Fig 6
  has filled-only pooled band; `AS_CDF_Merged.m` added dashed boundary lines
  as a deliberate restyling. Port must distinguish.
- Pooled scatter points: circle `'o'` for LOS, diamond `'d'` for NLOS;
  `size 70`, edge blue, face `'none'`, edge `LineWidth 2.0`.

Count per subplot (6.75 GHz DS):
- NYU LOS curve: 6 ECDF steps (6 LOS locations).
- USC LOS curve: 0 (no LOS in 7_UMi_U3.xlsx → USC line absent; NYU-only).
  Pooled LOS = 6 blue circles.
- NYU NLOS curve: 11 ECDF steps.
- USC OLOS curve: 8 ECDF steps (if all 8 are OLOS-labeled, which matches the
  CSV — all 8 USC 7 GHz locations are OLOS in the original xlsx, relabeled
  NLOS in the mat).
- Pooled NLOS = 19 blue diamonds.

(Counts for the commented-out sub-THz variant would be 16/13 LOS and 11/13 NLOS
as in Script 2.)

### Legend
`{'USC+NYU','NYU','NYU 95% band','USC','USC 95% band','USC+NYU 95% band'}`,
`'Location', 'southeast'`.

### Saved file paths
None — no save calls. Figures are captured manually from the MATLAB window.
This explains why a separate Codebase B script `AS_CDF_Merged.m` was later
written to save the AS variants programmatically.

### Notable variable names
`n3_isLOS`, `n3_isNLOS`, `u3_isLOS`, `u3_isNLOS`, `u3_isOLOS`, `fGHz`, `d0`.
Helpers: `plot_cdf_group`, `plot_cdf_panel`, `plot_band`, `ecdf_with_dkw`,
`sanitize_numeric_vec`, `cdf_xlabel`, `add_logstat_text`, `style_cdf_axes`,
`plot_ci_models`, `plot_ci_fit`, `bootstrap_ci_summary`, `summarize_bootstrap`,
`print_mean_log_metric`, `print_logmean`, `bootstrap_logstat_summary`,
`summarize_logstat_ci`, `report_log_ci_for_subset`.

---

## Figure-specific clarifications

### Fig 5 — CI PL scatter
**Confirmed layout**: three separate figures (one per dataset: NYU, USC, Pooled),
each **one axes** with BOTH LOS circles and NLOS squares mixed, TWO fit lines
(LOS + NLOS) and TWO bootstrap bands. So:

- **NOT 2 subplots (sub-THz | 6.75 GHz) with 6 fit lines each** — each frequency
  is a separate run of the script (either sub-THz via Script 2 `fGHz=142`,
  `xlim [1,200]`, or 6.75 GHz via Script 6 `fGHz=6.75`, `xlim [1,1000]`).
- **NOT 4 subplots (band × LOS/NLOS)**.
- Instead: **2 bands × 3 panels each = 6 total figures** produced across the
  two codebases, each panel containing LOS-and-NLOS-mixed scatter + 2 fit lines + 2 bands.
- The paper's `PLcombinedPlot.jpg` / `PLcombinedPlot7.jpg` images (reference in
  `paperContents/`) must therefore be composites arranged in post-processing,
  OR produced by a helper script that is not checked in. The scripts we have
  produce the per-dataset panels that feed those composites.
- Per-panel marker counts (sub-THz):
  - NYU Data (N3): 16 LOS circles + 11 NLOS squares = **27 dots**
  - USC Data (U3): 13 LOS circles + 13 NLOS squares = **26 dots**
  - Pooled: 29 LOS circles + 24 NLOS squares = **53 dots**
- 6.75 GHz panel counts (USC NLOS = U3 OLOS):
  - NYU: 6 LOS + 11 NLOS = 17
  - USC: 0 LOS + 8 OLOS = 8
  - Pooled: 6 LOS + 19 NLOS|OLOS = 25
- If the user's target port shows fewer dots than 53 on the pooled sub-THz
  panel, likely causes: (a) using Codebase-B's `.mat` 27+26 instead of Codebase
  A's xlsx 16+11+13+13, (b) extra NaN-drop filter (e.g., also filtering where
  DS is NaN), (c) dropping OLOS at 6.75 GHz when the ref includes it.

### Fig 6 — DS CDF (6.75 GHz)
- **Per subplot** (LOS and NLOS panels): **3 curves — NYU (violet), USC (red),
  Pooled (blue scatter points only, circles for LOS / diamonds for NLOS)**.
  Plus NYU's violet DKW band, USC's red DKW band, Pooled's blue DKW band (all
  filled, no dashed boundary overlay in the DS-ref version).
- Scatter point count: LOS subplot = 6 (NYU only has LOS; USC has 0 LOS at
  6.75 GHz); NLOS subplot = 19 (11 NYU NLOS + 8 USC OLOS, relabeled).
- **DKW bands ARE shaded regions**: NYU/USC use alpha 0.12, Pooled uses alpha
  0.10. Colors match the curves.
- Gray figure background `[0.94 0.94 0.94]`.
- Also: lognormal pooled stats annotated in bottom-right corner.

### Fig 7 (ASA CDF) and Fig 8 (ASD CDF) — sub-THz
Produced by `AS_CDF_Merged.m` (which generates all 4 files `OmniASA_merged.*`,
`OmniASA_merged7.*`, `OmniASD_merged.*`, `OmniASD_merged7.*`; paper's Fig 7 is
`OmniASA_merged.jpg` sub-THz; Fig 8 is `OmniASD_merged.jpg` sub-THz; the `*7`
variants are supplementary 6.75 GHz versions).

- **Per subplot**: 3 curves — NYU (violet line, LineWidth 2.2), USC (red line,
  LineWidth 2.2), Pooled (blue open markers — circles for LOS, diamonds for
  NLOS). Bands: NYU red-violet fill α=0.12, USC red fill α=0.12, Pooled blue
  fill α=0.10 PLUS Pooled dashed blue boundary lines (LineWidth 1.5).
- Scatter point count (sub-THz):
  - LOS subplot: 29 pooled blue circles (16 NYU LOS + 13 USC LOS).
  - NLOS subplot: 24 pooled blue diamonds (11 NYU NLOS + 13 USC NLOS).
- Scatter point count (6.75 GHz):
  - LOS subplot: 6 circles (NYU only; USC has no LOS).
  - NLOS subplot: 20 diamonds (12 NYU NLOS+OLOS after relabel + 8 USC NLOS+OLOS).
- White figure background (`'Color', 'w'`).
- FontSize 19 axes, 17 annotation, 15 legend.

### Fig 4 — Bland-Altman ASA/ASD
Produced by `BA_AS_Merged.m`. **One axes per figure**, N3 blue circles + U3
orange squares overlaid. Two horizontal bias lines + four dashed ±1.96 SD lines
(2 colors × 2 bounds each). Left ylabel blue, right ylabel red via a twin
transparent axes trick.

- Sub-THz marker count: **27 N3 circles + 26 U3 squares = 53 markers**.
- 6.75 GHz marker count: **18 N3 circles + 8 U3 squares = 26 markers**.
- No LOS/NLOS separation — all environments pooled.

### Fig 3 — Bland-Altman PL / DS
No dedicated saved script for PL/DS at the paper-figure folder was found;
`bland_altman_analysis.m` (Codebase A) prints to the screen without saving, and
`Plot_BlandAltman_PL_DS_AS.m` (Codebase B) saves to a local `BlandAltman_Figures/`
folder. The paper's `BA_PL.jpg`, `BA_DS.jpg`, `BA_PL7.jpg`, `BA_DS7.jpg` in
`paperContents/` match the visual style of `BA_AS_Merged.m` exactly
(dual-axis text layout, 120-pt scatter, font sizes 24-28). So the paper's
PL/DS figures were likely produced by a **clone of `BA_AS_Merged.m`** swapping
in PL/DS columns, which is not committed. Port should reuse the same layout
template and column pairs from `Plot_BlandAltman_PL_DS_AS.m` (PL, DS rows of
its `metrics` cell array), but styled like `BA_AS_Merged.m`.

Expected marker counts for the ported PL/DS BA:
- Sub-THz: 27 NYU circles + 26 USC squares = 53 markers.
- 6.75 GHz: NYU 7 GHz table has columns `NYUthr_PL_SUM_dB` / `NYUthr_PL_pDM_dB`
  (for N3) and `USCthr_PL_SUM_dB` / `USCthr_PL_pDM_dB` (for U3) — **but these
  are all from the NYU 7 GHz data**. USC 7 GHz data has `PL_NYU_dB` / `PL_USC_dB`
  for its own data. So N3 = 18 markers, U3 = 8 markers, total 26.

---

## Codebase B — other scripts skimmed

- `CDF_7GHz_Combined.m` — produces a 3-curve CDF with colors
  `NYU=[0 0.45 0.74]`, `USC=[0.85 0.33 0.10]`, `Pooled=[0.2 0.2 0.2]`, using
  Times New Roman LaTeX defaults. **Does not match paper-figure style** (which
  uses violet/red/blue and Helvetica/default). Not used for paper figures;
  skip.
- `Plot_Threshold_Sensitivity.m` — threshold sweep analysis, not a published
  figure.
- `Comprehensive_NYU_USC_Analysis*.m` (v1-v7), `Comprehensive_AS_Analysis.m`,
  `MJ_Viz_AS_NYU_vs_USC_Detailed.m`, `Generate_AS_CrossProcessing_Table.m`,
  `Diagnose_*.m`, `Compare_NYU_USC_Methods_Full.m` — all internal diagnostic /
  exploratory scripts that produced the full data tables fed into the paper
  figure scripts. Not paper-figure generators.

---

## Caveats / open questions

1. **PLcombinedPlot generator not found**: the paper's combined CI-PL figure
   (referenced as `PLcombinedPlot.fig`) does not have an obvious checked-in
   script. The two candidates (`cdf_ci_pl_analysis.m` and
   `cdf_ci_pl_analysis_DS_ref.m`) only produce 3 SEPARATE panels (NYU / USC /
   Pooled) per frequency. The paper figure may have been assembled manually in
   MATLAB's figure editor or by a lost helper.

2. **Fig 3 PL/DS BA generator not found**: `BA_PL.jpg`, `BA_DS.jpg` etc. in
   `paperContents/` visually match `BA_AS_Merged.m` output but no
   `BA_PL_DS_Merged.m` exists. The port must synthesize this by adapting
   `BA_AS_Merged.m` with the PL/DS column mapping from
   `Plot_BlandAltman_PL_DS_AS.m`.

3. **OLOS handling is inconsistent**:
   - `AS_CDF_Merged.m` (Codebase B, `.mat` inputs): `OLOS` OR'd into the NLOS
     mask (`nyu7_isNLOS | OLOS`, `usc7_isNLOS | OLOS`).
   - `cdf_ci_pl_analysis_DS_ref.m` (Codebase B, `.xlsx` inputs): U3's NLOS slot
     is REPLACED by `u3_isOLOS`, not OR'd. Any literal `'NLOS'` rows in U3's
     xlsx are excluded.
   - The port's authoritative behavior: at 6.75 GHz the USC data is actually
     all OLOS (per the raw CSV), and `'NLOS'` is never present in the USC
     xlsx; so the OR vs replace distinction is moot for USC 7. It matters for
     NYU 7, which has both `'NLOS'` and `'OLOS'` — Codebase B OR's them,
     Codebase A's DS-ref script uses strict `'NLOS'`. Treat
     `AS_CDF_Merged.m` as authoritative for figure parity, since it's the one
     that saves to the paper figures folder.

4. **`cdf_ci_pl_analysis_DS_ref.m` title bug**: hardcodes `'sub-THz'` even
   when `fGHz = 6.75`. Port should parametrize.

5. **`BA_AS_Merged.m` degree symbol**: uses `char(176)` in axis labels —
   directly emits the Unicode degree sign as a char, NOT a TeX escape. The
   `Interpreter` is `'none'` for axis labels. Port must use a real Unicode
   `\u00B0` and not `$^\circ$`.

6. **Dashed pooled-boundary lines** in `AS_CDF_Merged.m` only — `DS_ref`
   script does NOT have them. If Fig 6 and Fig 7/8 look subtly different, this
   is why.

7. **Absolute paths everywhere**: the Codebase A scripts have Dipankar's user
   path baked in (`C:\Users\Dipankar\...`); Codebase B has Mingjun's
   (`D:\NYU-USC\Cross-Processing\...`, `D:\Joint-Point-Data-format-USC-NYU-Journal\...`).
   Port must accept a `data_root` / `figures_root` argument.
