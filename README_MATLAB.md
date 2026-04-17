# MATLAB — Unified Channel Analysis (standalone raw-to-paper pipeline)

The MATLAB pipeline is now **standalone**: it bundles ~11 GB of raw PDP
data under `data/raw/` and the verbatim authors' processing scripts
under `matlab/processing/`. `matlab/run_all.m` reproduces every paper
figure and data-driven table end-to-end on any MATLAB-licensed machine,
with no references to `D:/NYU-USC/Cross-Processing/` or
`D:/NaveedDipankarMingjunJorgeShare/`.

The Python port (see `README_PYTHON.md`) remains the verified reference
for the aggregated-figure drivers; the MATLAB pipeline additionally
reproduces the raw-PDP reprocessing pathway that Python omits.

## Quick start

```matlab
cd <repo>/matlab
run_all              % full raw-to-figures pipeline (first run: ~30-60 min)
run_all('figures')   % skip raw processing; regenerate figures only
run_all('rebuild')   % force full rerun of every step
```

The **first invocation** takes ~30–60 minutes because STEP 1 processes
the 88 raw `.mat` files (4.9 + 3.1 + 2.0 + 0.7 GB) into per-pipeline
`Results/` directories. Subsequent invocations auto-detect the
`Results/*.mat` marker files and skip that step, completing in under a
minute. `run_all('rebuild')` forces the raw-processing step even when
markers are present; `run_all('figures')` skips STEP 1 entirely and
only regenerates the paper figures.

### Output layout

- `figures/matlab/` — every paper figure (`*.pdf`, `*.png`, `*.fig`),
  every data-driven table (`*.csv`), and `paper_parity.*` for paper vs
  Python vs MATLAB side-by-side comparison.
- `matlab/processing/<band>/Results/` — the canonical raw-processing
  output (`all_comparison_results.mat`, `USC145GHz_Full_Results.mat`,
  `USC7GHz_Full_Results.mat`) that the paper-figure scripts load.
- `matlab/processing/<band>/Figures/` — the per-pipeline diagnostic
  figures that the raw-processing scripts emit (Fig1_OmniPDP_... etc.).
  These are not paper figures; they are sanity plots.

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
    paths.m                   repo-root-relative absolute paths (raw, patterns,
                              Results/, point_data/, figures/matlab/)
    plot_style.m              global Times New Roman / NYU+USC colors
  lib/                        PL / DS / AS / stats helpers (Python-parity)
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
  lib_tcsl/                   flattened NYU 4.TCSL toolbox (TCSL142D, PAS,
                              boundaryMPCs, circ_std, ...)
  patterns/                   142 GHz antenna pattern .DAT files
                              (HPLANE/EPLANE 261D-27.DAT)
  processing/                 verbatim authors' raw-processing scripts
    nyu_142/                  NYU142GHz_Method_Comparison.m + TX-power CSV
    nyu_7/                    NYU7GHz_Method_Comparison.m + TX-power CSV + .mat
                              antenna patterns
    usc_145/                  USC142GHz_Method_Comparison_Full.m +
                              aziCut/elevCut.mat
    usc_7/                    USC7GHz_NewData_Processing.m +
                              USC_Midband_Pattern.mat
  paper_figures/              verbatim authors' paper-figure scripts
                              (pixel-identical to the published figures)
    AS_CDF_Merged.m           Figs 7 & 8 ASA/ASD CDF
    BA_AS_Merged.m            Fig 4 BA ASA/ASD
    Plot_BlandAltman_PL_DS_AS.m Alt BA generator
    cdf_ci_pl_analysis.m      Fig 5 CI PL + Fig 6 DS CDF
    cdf_ci_pl_analysis_DS_ref.m Fig 6 DS CDF 6.75 GHz
    bland_altman_analysis.m   Fig 3 BA PL/DS
    calculate_AS_RMSE.m       Table VI RMSE (ASA/ASD)
  figures/                    unified per-figure drivers (Python parity)
    fig03_bland_altman_pl_ds.m ... fig08_asd_cdf.m
    table06_rmse.m, table07_pooled_stats.m, table_dumps.m
    paper_parity.m
```

## Data-path configuration

All paths resolve automatically from the **repo root** inside
`matlab/config/paths.m`. The repo is fully relocatable: clone or copy
the repo to any directory on any drive and every script finds its
inputs. Absolute paths are never hardcoded.

The fields exposed by `paths()`:

| Field                       | Resolves to                                                             |
|-----------------------------|--------------------------------------------------------------------------|
| `P.raw_nyu_142`             | `<repo>/data/raw/nyu_142/`                                               |
| `P.raw_nyu_7`               | `<repo>/data/raw/nyu_7/`                                                 |
| `P.raw_usc_145_LOS/NLOS`    | `<repo>/data/raw/usc_145/{LoS,NLoS}/`                                    |
| `P.raw_usc_7_LOS/NLOS`      | `<repo>/data/raw/usc_7/{LOS Study,OLOS Study}/`                          |
| `P.nyu_142_tx_power_csv`    | `<repo>/matlab/processing/nyu_142/140GHz_Outdoor_BaseStation.csv`        |
| `P.nyu_142_{h,e}plane_pattern` | `<repo>/matlab/patterns/{HPLANE,EPLANE} Pattern Data 261D-27.DAT`     |
| `P.nyu_7_tx_power_csv`      | `<repo>/matlab/processing/nyu_7/7GHz_Outdoor (1).csv`                    |
| `P.nyu_7_phi{0,90}`         | `<repo>/matlab/processing/nyu_7/7_phi{0,90}_pd.mat`                      |
| `P.usc_145_{azi,elev}cut`   | `<repo>/matlab/processing/usc_145/{azi,elev}Cut.mat`                     |
| `P.usc_7_antenna_pattern`   | `<repo>/matlab/processing/usc_7/USC_Midband_Pattern.mat`                 |
| `P.results_{nyu_142,nyu_7,usc_145,usc_7}` | `<repo>/matlab/processing/<band>/Results/`                   |
| `P.point_data`              | `<repo>/data/point_data/`                                                |
| `P.out_dir` / `P.paper_fig_out` | `<repo>/figures/matlab/`                                             |

If you want to point at a different point-data drop, set the
`CHANNEL_DATA_ROOT` environment variable before launching MATLAB; it
only overrides the xlsx table root, not the raw-data root.

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
