# Issues Log

Tracks ambiguities, unmapped scripts, and best-judgment decisions made during the port. Each entry: date · severity · short description · resolution.

## 2026-04-17 · paper summary / numerical claims

- *S:info* — Abstract DS CFI widths (41.77 / 28.67 ns) are the **NLOS** values from Table 7, not LOS. Phrasing in the abstract is ambiguous but consistent. No action.
- *S:info* — Fleury AS definition has two forms in the paper: `σ=√(1−R²)` (Table 5) and the squared-distance form `σ=√(Σ|e^{jφ}−μ|² APS / Σ APS)` (body text). These are algebraically equivalent for unit-modulus phasors. The port implements both and unit-tests their equality.
- *S:low* — Table 3 lists USC `T_PAS` as `τ_gate=966.67 ns; +12 dB (noise)` — this duplicates the delay-domain spec into the PAS row because USC applies no spatial thresholding. Interpreted as: USC `T_PAS = none`.
- *S:info* — Paper's "sub-THz" combines 142 GHz and 145.5 GHz into one band for pooled analysis; the port follows suit (no frequency-dependent correction between the two).
- *S:info* — Fig. 1 references tables N4/U4 for mismatched thresholds, but the body uses `N3`/`U3` with sub-column "NYU/USC thres" to represent the same concept. The port uses the body convention.
- *S:info* — Files `CrossProc_AS_BarChart.pdf`, `CrossProc_PAS_Threshold.pdf`, `CrossProc_Scatter.pdf`, `CrossProc_USC_BlandAltman_AS.pdf` exist in the paper's `figures/` directory but are not referenced in `main_final.tex`. Treated as unused drafts; not reproduced.

## 2026-04-17 · codebase A inventory

- *S:low* — Multiple `USCprocessing*.m` variants (5-way branch). Active paper variant is `USCprocessing_NYUth_Sp.m` (and 7 GHz twin). Others retained for history.
- *S:low* — `D`-suffixed helpers (`boundaryMPCsD`, `lobeShaperCounterD`, `SubPathPwrDirsD`, `SecondaryStats_circD`) are the active versions; unsuffixed originals are predecessors.
- *S:low* — The `NYU_Data_thresholded/` tree is an external data drop required by the USC-on-NYU pipeline but not regenerable from this repo. Treated as opaque input.

## 2026-04-17 · codebase B inventory

- *S:med* — `Comprehensive_NYU_USC_Analysis_v2..v7.m` — 6 versions of the same analysis. Authoritative: `v7` (Feb 2 2026, 708 lines, 5-method taxonomy). Deltas summarized in `docs/code_conflicts.md`.
- *S:low* — Two PDP-threshold spellings co-exist: plain NYU `max(peak−25, NF+5)` vs. USC `12 dB above max noise floor`. Both implemented as separate functions with named parameters.
- *S:info* — `USC_Method_Visualization*.m` and `Verify_USC_Method_v*.m` are diagnostic scripts for developing the cross-processing protocol; not published as figures. Skipped.
- *S:info* — `USC_ver/` subdirectory holds an alternate USC-processing snapshot. Not reproduced; retained as reference only.

## 2026-04-17 · scope of Python port

- *S:high* — Raw directional-PDP re-processing (sliding-correlator demod, PAS synthesis, 10 dB spatial-lobe expansion, APDS construction) is the subject of ongoing research and is tightly coupled to proprietary sounder formats. The Python port **reads the already-published point-data xlsx/csv tables** (N1 / U1 / N3 / U3) as its input and computes every figure from there. This matches what the paper text itself asks of downstream users — the point-data table is the declared multi-institution interchange format. The MATLAB port ships the raw-processing scripts for users who need them; the Python package does not duplicate them.
- Documented in `README.md` and `README_PYTHON.md` under "Scope".

## 2026-04-17 · raw-data reprocessing (deferred)

- `USC/USC_Data/` and `NYU/NYU_Data/` contain raw directional PDP files (not loaded by the Python pipeline). The existing point-data xlsx tables are derived from these. If a future user wants to regenerate point-data tables, the MATLAB scripts in Codebase A and B under `USCprocess*/` and `NYUprocess*/` are the authoritative path.

## Source-data anomalies found during port

- *S:med* — `142_UMi_N3.xlsx` row `TX4-RX37` has `Omni ASA — NYU thres` = `714.0` where the other columns (`NYU orig`, `USC thres`) agree on `7.14` / `7.14`. Almost certainly a lost decimal point. This single cell inflates the computed RMSE (Table 6 ASA NYU-data/NYU-thr) from the paper's reported `0°` to `~136°`. We do not mutate the input file; instead, `figures/table06_rmse.py` drops this location from the ASA RMSE computation (flagged with a Python-side filter) and the discrepancy is recorded here.
- *S:low* — N1-xlsx (`142_UMi.xlsx` / `7_UMi.xlsx`) values differ numerically from the `NYU orig. (N1)` column of the N3 xlsx (e.g. TX1-RX1 LOS Omni DS: 15.72 vs 13.99 ns). The joint-paper's Table 7 numbers are consistent with the N3-xlsx `NYU orig` column; the stand-alone N1 xlsx appears to be an earlier processing snapshot. The Python loader uses the N3-xlsx orig column as the authoritative N1 source. Same rationale for U1 (U3 xlsx `USC orig` column).
- *S:low* — USC 6.75 GHz dedicated csvs (`usc_microcellular_*_metrics7.csv`) contain only 8 of the 17 known locations (4 LOS + 4 NLOS vs. 6 LOS + 11 OLOS). The Python loader uses the U3 xlsx `USC orig (U1)` column for this band.
- *S:info* — The paper reports the "mean" of lognormal DS/AS values as the lognormal-expectation `E[X]=exp(μ·ln10+0.5·(σ·ln10)²)`, not the arithmetic sample mean. The Python loader matches this convention in `channel_analysis.ds.lognormal_stats` (field `mean_lognormal`).

## Known reproduction gaps

- *Fig. 2 (directional PDP comparison)* — cannot be regenerated from point-data alone; needs raw PDPs. The Python package documents this gap and passes through the existing paper figure as a PNG for completeness; Fig. 2 is flagged "could not reproduce (needs raw PDP; out of scope for point-data port)" in `docs/figure_parity.md`.
- *Table 1, Table 2, Table 3, Table 5* — static literature / methodology tables; not data-generated. No Python driver.
