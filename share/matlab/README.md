# MATLAB reproducibility pipeline

Regenerates every data-driven paper figure (Fig. 3–8) and every
data-driven table (Table VI, Table VII) from the six point-data xlsx
files under [`../data/point_data/`](../data/point_data/). Numerically
equivalent to the Python implementation under [`../python/`](../python/).

## Run

```matlab
cd matlab
run_all                  % default: xlsx → figures + tables (≈ 1–2 min)
run_all('raw')           % also regenerate xlsx from raw PDPs
```

Outputs land under `<repo>/figures/matlab/`. To reproduce a single
figure or table after the first full run, invoke the driver directly:

```matlab
fig06_ds_cdf              % just Fig. 6
table06_rmse              % just Table VI
paper_parity              % TIGHT / CLOSE / MISS audit vs paper values
```

Requires MATLAB **R2022b+** with the Statistics and Machine Learning
Toolbox (bootstrap CI) and the Signal Processing Toolbox (windowing
helpers used by raw mode).

## Layout

```
matlab/
├── run_all.m              end-to-end driver (see header for modes)
├── config/
│   ├── paths.m              all canonical paths; reads env-var overrides
│   └── plot_style.m         IEEE two-column fonts / NYU-blue + USC-orange palette
├── lib/                   math primitives used by every figure driver
│   ├── load_point_data.m    ← single public loader (returns tidy table)
│   ├── bootstrap_ci.m       nonparametric percentile bootstrap
│   ├── ci_pl_fit.m          Close-In PL fit + CFI on PLE
│   ├── dkw_band.m           Dvoretzky-Kiefer-Wolfowitz uniform CDF band
│   ├── bland_altman.m       bias + limits-of-agreement statistics
│   ├── lognormal_stats.m    log-domain mean + CFI (lognormal mean report)
│   ├── rms_delay_spread.m   2nd central moment of a power-delay profile
│   ├── angular_spread_fleury.m / angular_spread_3gpp.m / fleury_to_gpp.m
│   ├── save_figure.m        300-DPI PNG + vector-PDF export helper
│   └── sync_paper_figs.m    copy fig03..fig08 outputs to paper-expected names
├── lib_tcsl/              vendored NYU angular-spread helpers — see its own README
├── figures/               one driver per paper figure / table
│   ├── fig03_bland_altman_pl_ds.m      BA of PL and DS (2 bands)
│   ├── fig04_bland_altman_as.m         BA of ASA and ASD
│   ├── fig05_ci_pl_scatter.m           CI PL scatter + fits
│   ├── fig06_ds_cdf.m                  Omni DS CDF + DKW band
│   ├── fig07_asa_cdf.m                 Omni ASA CDF
│   ├── fig08_asd_cdf.m                 Omni ASD CDF
│   ├── table06_rmse.m                  cross-threshold RMSE (paper Table VI)
│   ├── table07_pooled_stats.m          pooled lognormal stats (Table VII)
│   ├── table_dumps.m                   per-link CSV dumps for the supplement
│   └── paper_parity.m                  TIGHT/CLOSE/MISS audit report
├── paper_figures/         alternative merged-style producers (canonical names)
│   ├── PL_CI_Merged.m                  → PLcombinedPlot{,7}.{jpg,png,fig}
│   ├── DS_CDF_Merged.m                 → OmniDS_merged{,7}
│   ├── AS_CDF_Merged.m                 → OmniASA/D_merged{,7}
│   ├── BA_AS_Merged.m                  → BA_ASA{,7}, BA_ASD{,7}
│   └── cdf_ci_pl_analysis{,_DS_ref}.m  legacy sub-THz + 6.75 GHz CDF combined
├── processing/            raw-PDP → xlsx (only used by `run_all('raw')`)
│   ├── nyu_142/  nyu_7/  usc_145/  usc_7/    one folder per campaign
│   └── README.md                              per-script I/O summary
├── patterns/              antenna-pattern DAT files shipped with NYU 142 GHz
└── tools/
    ├── generate_supplement_tex.m         build supplement.tex from CSVs
    └── stage_paper_figures.m             rename fig03_ → BA_, etc. → paper tree
```

## Paper-tree sync (opt-in)

Set any of these **before** launching MATLAB if you want
`run_all` to also overwrite figures and the supplement inside an
external paper-source tex tree:

| Env var            | Default (unset)                       | Purpose                        |
|--------------------|----------------------------------------|--------------------------------|
| `PAPER_TREE_DIR`   | (no sync)                              | root of the paper tex project  |
| `PAPER_FIG_DIR`    | `$PAPER_TREE_DIR/figures`              | figure sync target             |
| `PAPER_TEX_PATH`   | `$PAPER_TREE_DIR/main_final.tex`       | in-place tex updates           |
| `PAPER_SUPP_PATH`  | `$PAPER_TREE_DIR/supplement.tex`       | supplement writer              |

`paths.m` reads these at startup. When all four are empty the
pipeline never touches an external directory.

## What each figure / table driver uses

| Driver                       | Reads                                   | Produces                                      |
|------------------------------|-----------------------------------------|-----------------------------------------------|
| `fig03_bland_altman_pl_ds.m` | `load_point_data()`                     | `fig03_BA_PL{,7}` + `fig03_BA_DS{,7}` (.png/.pdf/.fig) |
| `fig04_bland_altman_as.m`    | same                                    | `fig04_BA_ASA{,7}` + `fig04_BA_ASD{,7}`       |
| `fig05_ci_pl_scatter.m`      | same + `ci_pl_fit`                      | `fig05_CI_PL{,7}`                             |
| `fig06_ds_cdf.m`             | same + `dkw_band`, `lognormal_stats`    | `fig06_DS_CDF{,7}`                            |
| `fig07_asa_cdf.m`            | same                                    | `fig07_ASA_CDF{,7}`                           |
| `fig08_asd_cdf.m`            | same                                    | `fig08_ASD_CDF{,7}`                           |
| `table06_rmse.m`             | N3 vs N1 + U3 vs U1 (xlsx)              | `table06_rmse.csv`                            |
| `table07_pooled_stats.m`     | all xlsx + bootstrap                    | `table07_pooled_stats.csv`                    |
| `paper_parity.m`             | all of the above                        | `paper_parity.csv` + on-console TIGHT/CLOSE/MISS |

After `stage_paper_figures()` the outputs are copied to the paper's
plain filenames (`BA_PL.png`, `OmniDS_merged.jpg`, etc.) — mapping
table is at the top of `tools/stage_paper_figures.m`.

## Parity vs Python

Both implementations consume the same xlsx files via equivalent
loaders (`lib/load_point_data.m` ↔ `channel_analysis.io.load_point_data`)
and the same RNG seed (`paths().RNG_SEED = 0`). Table VI / VII CSV
outputs are byte-identical between the two; Fig. 3–8 renders are
visually identical (font, color, marker set all mirrored by
`plot_style.m` ↔ `styles/paper.mplstyle`).
