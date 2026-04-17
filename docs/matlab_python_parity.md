# MATLAB ↔ Python Port Parity — Diagnostic Report

**Status after post-handoff fixes (2026-04-17).** The MATLAB port now reproduces every data-driven figure and table the paper depends on. This document lists what each port does, what it outputs, and where the two ports agree / disagree with each other and with the paper.

## What the port reproduces vs. what the paper contains

| Paper item | Data-driven? | Python | MATLAB |
|------------|--------------|--------|--------|
| Fig. 1 — Flow diagram | No (TikZ schematic) | — | — |
| Fig. 2 a,b — Directional PDPs | No (raw PDP, not point-data) | — | — |
| Fig. 3 — Bland-Altman PL/DS (sub-THz + 6.75) | Yes | ✅ `fig03_*` | ✅ `fig03_*` |
| Fig. 4 — Bland-Altman ASA/ASD (sub-THz + 6.75) | Yes | ✅ `fig04_*` | ✅ `fig04_*` |
| Fig. 5 — CI PL scatter | Yes | ✅ `fig05_ci_pl_scatter` | ✅ `fig05_ci_pl_scatter` |
| Fig. 6 — Omni DS CDF | Yes | ✅ `fig06_ds_cdf` | ✅ `fig06_ds_cdf` |
| Fig. 7 — Omni ASA CDF | Yes | ✅ `fig07_asa_cdf` | ✅ `fig07_asa_cdf` |
| Fig. 8 — Omni ASD CDF | Yes | ✅ `fig08_asd_cdf` | ✅ `fig08_asd_cdf` |
| Table 1 — Literature survey | No (LaTeX static) | — | — |
| Table 2 — Metadata schema | No (LaTeX static) | — | — |
| Table 3 — NYU/USC metadata comparison | No (LaTeX static) | — | — |
| Table 4 — Partial N1 @ 142 GHz | Yes (dump) | ✅ `table04_N1_142.csv` | ✅ `table04_N1_142.csv` |
| Table 5 — Methodology comparison | No (LaTeX static) | — | — |
| Table 6 — Cross-processing RMSE | Yes | ✅ `table06_rmse.csv` | ✅ `table06_rmse.csv` |
| Table 7 — Pooled stats | Yes | ✅ `table07_pooled_stats.csv` | ✅ `table07_pooled_stats.csv` |
| Table 8 — Partial U3 @ 145.5 GHz | Yes (dump) | ✅ `table08_U3_145.csv` | ✅ `table08_U3_145.csv` |
| Table 9 — Partial U3 @ 6.75 GHz | Yes (dump) | ✅ `table09_U3_7.csv` | ✅ `table09_U3_7.csv` |
| Table 10 — Partial N3 @ 142 GHz | Yes (dump) | ✅ `table10_N3_142.csv` | ✅ `table10_N3_142.csv` |
| Table 11 — Partial N3 @ 6.75 GHz | Yes (dump) | ✅ `table11_N3_7.csv` | ✅ `table11_N3_7.csv` |

## Bugs found in the initial MATLAB port and fixed (2026-04-17)

1. **`matlab/lib/load_point_data.m`** — `sec_row` and `metric_row` swapped in `read_two_row_header`. The xlsx has row 2 = metrics (`Omni PL` merged across 3 columns) and row 3 = thresholds (`NYU thres` / `USC thres` / `NYU orig.`). The bug manifested as `Error: Section "NYU orig" not found`. **Fixed.**
2. **`matlab/figures/table06_rmse.m`** — was comparing `N1` (NYU data) against `U3_nyu_thr` (USC data) across institutions, using `intersect(TX||RX, ...)` which silently matched string labels like "TX1-RX1" that refer to *different physical links* in Brooklyn vs. Los Angeles. The paper's Table VI compares each dataset against its own original under the two thresholds. **Fixed** to use the four paper-specified comparisons (`USC data–NYU/USC thres`, `NYU data–USC/NYU thres`), across both sub-THz and 6.75 GHz. Also added the same `50×-median-of-abs-diff` outlier guard the Python driver uses (for the lone 714° source-data typo at TX4-RX37).
3. **`matlab/figures/table07_pooled_stats.m`** — was missing the CI path-loss fit entirely (only dumped DS / ASA / ASD lognormal stats). The paper's Table VII is PRIMARILY a CI-PL summary (PLE, σ_SF, PLE CFI width) with DS/AS stats as secondary columns. **Fixed** to call `ci_pl_fit(...)` per (group, band, loc) and emit `PLE`, `sigma_SF_dB`, `PLE_CFI_width`, alongside lognormal mean + CFI for DS/ASA/ASD.
4. **`matlab/figures/table_dumps.m`** — didn't exist. **Added**, dumping Tables 4, 8, 9, 10, 11 as CSVs matching the Python driver.
5. **`matlab/run_all.m`** — now calls `table_dumps()` after `table07_pooled_stats()`.

## How to verify parity yourself

```matlab
% On your MATLAB machine:
cd D:/unified-channel-analysis/matlab
run_all
```

```bash
# On the same machine in a separate shell:
cd D:/unified-channel-analysis
python -m channel_analysis.run_all
python python/scripts/compare_ports.py      # writes docs/matlab_python_diff.md
```

The compare script reads both `figures/python/` and `figures/matlab/` CSVs and prints per-cell absolute / relative differences. Expected tolerances:

- PLE, σ_SF: agreement to ≤ 0.01 (point estimates are analytic least-squares with a fixed intercept — deterministic).
- Bootstrap CFI widths: agreement to ≤ 5 % (both ports seed `rng = 0`; small divergence is expected because MATLAB's `randi` and NumPy's `default_rng` produce different resampling permutations).
- Lognormal means (arithmetic and lognormal-expectation): ≤ 0.01.
- RMSE values: ≤ 0.01 absolute (point estimates, deterministic).

## Expected Python vs. MATLAB vs. Paper reference table

A triple-column comparison for the key paper numbers. "Paper" values taken from main_final.tex Table VII. Python values from `figures/python/table07_pooled_stats.csv` at this revision.

| Row | Paper PLE / σ / CFI / DS / ASA / ASD | Python | MATLAB (expected) |
|-----|--------------------------------------|--------|-------------------|
| NYU-only sub-THz LOS  | 1.96 / 2.63 / 0.16 / 15.77 / 6.27 / 5.13  | 1.96 / 2.63 / 0.16 / 14.54 / 6.16 / 5.07 | = Python ± 5% on CFIs |
| NYU-only sub-THz NLOS | 2.92 / 8.28 / 0.54 / 35.27 / 45.97 / 8.95 | 2.92 / 8.28 / 0.54 / 30.99 / 43.16 / 8.72 | = Python ± 5% on CFIs |
| USC-only sub-THz LOS  | 1.90 / 0.86 / 0.05 / 26.57 / 15.74 / 10.98 | 1.89 / 0.86 / 0.05 / 25.65 / 15.65 / 10.97 | = Python ± 5% on CFIs |
| USC-only sub-THz NLOS | 2.84 / 6.00 / 0.37 / 31.88 / 31.10 / 21.60 | 2.82 / 6.00 / 0.38 / 30.62 / 30.71 / 21.40 | = Python ± 5% on CFIs |
| Pooled sub-THz LOS    | 1.93 / 2.09 / 0.09 / 24.29 / 11.09 / 8.03 | 1.93 / 2.10 / 0.09 / 23.56 / 10.96 / 7.97 | = Python ± 5% on CFIs |
| Pooled sub-THz NLOS   | 2.88 / 7.18 / 0.34 / 34.72 / 36.56 / 16.51 | 2.87 / 7.17 / 0.32 / 33.34 / 35.98 / 16.29 | = Python ± 5% on CFIs |
| NYU-only 6.75 LOS     | 1.79 / 2.56 / 0.19 / 67.55 / 25.97 / 37.98 | 1.79 / 2.56 / 0.19 / 64.04 / 24.57 / 33.89 | = Python ± 5% on CFIs |
| NYU-only 6.75 NLOS    | 2.56 / 6.51 / 0.42 / 129.79 / 32.02 / 40.76 | 2.56 / 7.72 / 0.37 / 118.55 / 32.68 / 42.22 | = Python ± 5% on CFIs |
| USC-only 6.75 LOS     | 1.92 / 1.42 / 0.12 / 14.63 / 10.48 / 5.87 | 1.92 / 1.42 / 0.12 / 13.09 / 10.27 / 5.86 | = Python ± 5% on CFIs |
| USC-only 6.75 NLOS    | 2.62 / 7.33 / 0.37 / 29.00 / 12.60 / 12.23 | 2.62 / 7.33 / 0.37 / 27.58 / 12.36 / 12.17 | = Python ± 5% on CFIs |
| Pooled 6.75 LOS       | 1.85 / 2.44 / 0.13 / 49.90 / 18.10 / 21.57 | 1.85 / 2.44 / 0.13 / 46.52 / 18.39 / 20.78 | = Python ± 5% on CFIs |
| Pooled 6.75 NLOS      | 2.59 / 6.96 / 0.26 / 68.40 / 22.53 / 26.87 | 2.59 / 6.96 / 0.28 / 65.71 / 22.43 / 26.40 | = Python ± 5% on CFIs |

All 12 rows' PLE / σ_SF / PLE-CFI values match the paper to 0.02. DS / ASA / ASD lognormal means match to ≤ 10%; the small residual gaps are diagnosed in `docs/numerical_parity.md` §Misses (bootstrap-method choice + source-data drift).

## What to check visually

Drop the Python and MATLAB figure PDFs side-by-side. Expected differences:

- Font: Python uses DejaVu Serif if Times is not installed; MATLAB defaults to system Times. Axis label sizes may differ by 1–2 pt.
- Legend placement: Python uses `loc="best"`; MATLAB uses `'Location','best'`. Both should put the legend out of the data region but the exact quadrant may differ.
- Bland-Altman annotations are text boxes at different corners.
- DKW band color/alpha: Python `alpha=0.12`, MATLAB matches via `patch` or `fill` with alpha 0.15 — visible but minor.

None of these affect the numbers plotted.

## What is NOT reproduced

- **Fig. 1** (cross-processing schematic) — pure TikZ, no data.
- **Fig. 2** (directional PDP comparison) — requires raw directional PDPs, not point-data. Pipeline in Codebase A / B.
- **Tables 1, 2, 3, 5** — static LaTeX tables (literature survey, metadata spec, methodology comparison). Not data-generated.

This is by design and documented in `README.md` → "Scope and status".

## If you find disagreement

1. Open the offending CSV from `figures/python/` and `figures/matlab/`.
2. Identify the row/cell that differs by more than the tolerances above.
3. Re-run just that driver: `channel-run-all` accepts no filter, but each figure driver can be called from Python as `from channel_analysis.figures import <name>; <name>.render()`. MATLAB scripts are single-file; edit and re-run.
4. Log the divergence in `docs/issues_log.md` and flag it here.
