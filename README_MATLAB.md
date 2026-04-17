# MATLAB port — Unified Channel Analysis

Python is the **verified reference implementation** for this project. The MATLAB code in `matlab/` is a **parallel port** intended to be run by the end user on their own MATLAB-licensed machine. It mirrors the Python architecture one-to-one but has not been executed in the authoring environment.

If numbers diverge, trust Python first and investigate the MATLAB port.

## Quick start

```matlab
cd D:/unified-channel-analysis/matlab
run_all
```

All outputs land in `D:/unified-channel-analysis/figures/matlab/`:

- `figXX_*.png` (300 DPI raster) and `figXX_*.pdf` (vector)
- `tableXX_*.csv` for the numerical tables
- `figXX_*.fig` re-openable MATLAB figures

## Tested MATLAB version

Developed against **MATLAB R2022b or later**. Earlier releases may work but the
drivers rely on `exportgraphics`, `string` arrays, and `rng`/`randi`, which are
all stable in R2022b+.

## Required toolboxes

- **MATLAB** (base)
- **Statistics and Machine Learning Toolbox** — for `quantile`, `bootstrp`-style resampling via `randi`, `std(ddof=0)` semantics
- **Signal Processing Toolbox** — only required if extending to per-PDP spectral work; the default drivers do not import from it

All of `readcell`, `readtable`, `writetable` are in base MATLAB since R2019a.

## File layout

```
matlab/
  run_all.m                   orchestrator (call this first)
  config/
    paths.m                   absolute paths to xlsx tables + output dir
    plot_style.m              global Times New Roman / NYU+USC colors
  lib/
    load_point_data.m         xlsx -> canonical long-format table
    ci_pl_fit.m               Close-In PL fit, Paper Eq. 13
    rms_delay_spread.m        Paper Eq. 9
    angular_spread_3gpp.m     Paper Eq. 10, 3GPP TR 38.901
    angular_spread_fleury.m   Paper Eq. 12
    fleury_to_gpp.m           AS unit conversion
    lognormal_stats.m         Paper Eq. 11 + bootstrap CFI
    bootstrap_ci.m            generic percentile bootstrap CI
    dkw_band.m                Dvoretzky-Kiefer-Wolfowitz CDF band
    bland_altman.m            paired-sample agreement stats
    save_figure.m             PNG/PDF/FIG export at 300 DPI
  figures/
    fig03_bland_altman_pl_ds.m
    fig04_bland_altman_as.m
    fig05_ci_pl_scatter.m
    fig06_ds_cdf.m
    fig07_asa_cdf.m
    fig08_asd_cdf.m
    table06_rmse.m
    table07_pooled_stats.m
```

## Data-path configuration

All input data paths live in `matlab/config/paths.m`. If your machine stores the
data at a different root, edit the `DATA_ROOT` constant at the top of that file.
The paths currently point at:

```
DATA_ROOT = 'D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare'
```

Per-variant inputs (see `docs/issues_log.md` for why N1/U1 come from the N3/U3
xlsx instead of the legacy stand-alone snapshots):

| Key            | File                                                                                  |
|----------------|---------------------------------------------------------------------------------------|
| `n1_142_xlsx`  | `USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi_N3.xlsx` (column `NYU orig.`)    |
| `n1_7_xlsx`    | `USC/USCprocessNYUdata/OriginalNYU_pointData/7_UMi_N3.xlsx`   (column `NYU orig.`)    |
| `u1_142_xlsx`  | `NYU/NYUprocessUSCdata/OriginalUSC-PointData/142_UMi_U3.xlsx` (column `USC orig.`)    |
| `u1_7_xlsx`    | `NYU/NYUprocessUSCdata/OriginalUSC-PointData/7_UMi_U3.xlsx`   (column `USC orig.`)    |
| `n3_142_xlsx`  | same file as `n1_142_xlsx` (different columns)                                        |
| `n3_7_xlsx`    | same file as `n1_7_xlsx`                                                              |
| `u3_142_xlsx`  | same file as `u1_142_xlsx`                                                            |
| `u3_7_xlsx`    | same file as `u1_7_xlsx`                                                              |

## Verifying numerical parity against Python

1. Run `python -m channel_analysis.run_all` — outputs land in `figures/python/`.
2. Run `run_all` in MATLAB — outputs land in `figures/matlab/`.
3. Compare the CSVs (`table06_rmse.csv`, `table07_pooled_stats.csv`) numerically.
   Differences below ~1e-6 are expected due to float-precision ordering in
   `std` / `quantile` implementations; anything larger is a bug.

Both implementations use the same deterministic RNG seed (`0`) and the same
bootstrap iteration count (`2000`) by default, so bootstrap CFIs should match
bit-for-bit once the underlying sample arrays agree.

## Further reading

- `docs/architecture.md` — module responsibilities, data flow, sign conventions
- `docs/numerical_parity.md` — tolerances, seed handling, expected deltas
- `docs/issues_log.md` — notes on known data-file quirks (in particular the
  N1/U1 xlsx ambiguity resolved by reading from the cross-processed files)

## Notes on MATLAB-specific gotchas

- `std(x, 0)` is the **sample** standard deviation (ddof = 1). `std(x, 1)` is
  the population standard deviation (ddof = 0). The Python reference uses
  `ddof=0` for `lognormal_stats` and `ddof=1` for Bland-Altman — see the
  individual files for comments noting which convention is applied.
- `quantile(x, [0.025 0.975])` uses linear interpolation between order
  statistics. NumPy's default `np.quantile` also uses linear interpolation, so
  percentiles match to within float precision for identical samples.
- `randi(n, n_boot, n)` produces the same shape as NumPy's
  `rng.integers(0, n, size=(n_boot, n))` but the underlying PRNGs differ; do
  NOT expect identical bootstrap replicates across languages, only identical
  CFIs in distribution over many runs. Point estimates (non-bootstrap) match
  exactly.
