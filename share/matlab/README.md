# MATLAB reproducibility pipeline

Regenerates every data-driven paper figure (Fig. 3–8) and every
data-driven table (Table VI, Table VII) from the six point-data xlsx
files under `../data/point_data/`.

## Run

```matlab
cd matlab
run_all
```

Runtime: ~1–2 min on a typical laptop. Outputs land under
`figures/matlab/` in the repo root.

## Layout

```
matlab/
├── run_all.m                   end-to-end driver
├── config/
│   ├── paths.m                 resolves all repo paths; reads env vars
│   └── plot_style.m            IEEE-column fonts / colors / line widths
├── lib/                        math primitives (bootstrap, CI fit, DKW, …)
├── figures/                    fig03..fig08, table06/07 drivers
├── paper_figures/              merged-style CDF + BA figure scripts
└── tools/                      supplement generator, figure-staging helper
```

## Optional: sync into a paper tex tree

If you also have the paper tex source locally and want the pipeline to
overwrite its figures and the supplement, set:

```bash
export PAPER_TREE_DIR=/path/to/paper
```

When set, `run_all.m` also calls `stage_paper_figures()` (copies the 16
paper figures into `$PAPER_TREE_DIR/figures`) and
`generate_supplement_tex()` (writes `$PAPER_TREE_DIR/supplement.tex`).
When unset, the pipeline stays entirely within the repo and never
touches any external paper tree.

Individual overrides: `PAPER_FIG_DIR`, `PAPER_TEX_PATH`,
`PAPER_SUPP_PATH`.

## What each figure uses

| Script                         | Reads                              | Produces                           |
|--------------------------------|------------------------------------|------------------------------------|
| `fig03_bland_altman_pl_ds.m`   | `load_point_data()` merged xlsx    | fig03_BA_PL{,7}, fig03_BA_DS{,7}   |
| `fig04_bland_altman_as.m`      | same                               | fig04_BA_ASA{,7}, fig04_BA_ASD{,7} |
| `fig05_ci_pl_scatter.m`        | same + `ci_pl_fit`                 | fig05_CI_PL{,7}                    |
| `fig06_ds_cdf.m`               | same + `dkw_band`, `lognormal_stats` | fig06_DS_CDF{,7}                 |
| `fig07_asa_cdf.m`              | same                               | fig07_ASA_CDF{,7}                  |
| `fig08_asd_cdf.m`              | same                               | fig08_ASD_CDF{,7}                  |
| `table06_rmse.m`               | N3 vs N1 and U3 vs U1 (xlsx)       | table06_rmse.csv                   |
| `table07_pooled_stats.m`       | all xlsx + bootstrap               | table07_pooled_stats.csv           |

## Dependencies

- MATLAB R2022b+
- Statistics and Machine Learning Toolbox (bootstrap CI)
- Signal Processing Toolbox (windowing helpers)
