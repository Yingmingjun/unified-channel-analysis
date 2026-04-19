# Unified NYU/USC Channel-Analysis Pipeline — Reproducibility Package

Reproducible analysis code for the journal paper

> D. Shakya, M. Ying, N. A. Abbasi, J. Gomez-Ponce, X. Liu, X. Wang, D. Abraham,
> T. S. Rappaport, A. F. Molisch,
> **"Pooling of Multi-Institutional Radio Propagation Empirical Data with
> Cross-Processing Validation for 6G AI/ML Channel Modeling,"**
> *submitted to IEEE Transactions on Wireless Communications*, 2026.

This package regenerates every data-driven figure (Fig. 3–8) and every
data-driven table (Table VI, Table VII) in the paper, starting from the
six **point-data xlsx files** under `data/point_data/`. Raw channel
measurements (≈ 11 GB of directional PDPs) are NOT included; the
shareable point-data tables are sufficient to reproduce all published
statistical results.

## Layout

```
share/
├── README.md              ← you are here
├── LICENSE                ← CC-BY-NC-4.0
├── data/point_data/       ← six shareable xlsx inputs (N1/U3/N3 × 142/6.75 GHz)
├── python/                ← primary verified implementation
│   ├── pyproject.toml
│   └── src/channel_analysis/
└── matlab/                ← parallel MATLAB port
    ├── run_all.m          ← entry point
    ├── config/            ← paths + plotting style
    ├── lib/               ← math primitives (bootstrap, CI fits, DKW, BA, …)
    ├── figures/           ← Fig. 3–8 + Table VI/VII drivers
    ├── paper_figures/     ← merged-style CDFs and BA figures
    └── tools/             ← supplement.tex + figure-staging helpers
```

## Quick start — Python (recommended)

```bash
cd python
pip install -e .
channel-run-all                     # regenerates every figure/table
```

Outputs land under `figures/python/` in the repo root. See
`src/channel_analysis/run_all.py` for per-figure drivers if you want to
run them individually.

## Quick start — MATLAB

Requires MATLAB R2022b+ with the Statistics and Signal Processing
toolboxes. From MATLAB:

```matlab
cd matlab
run_all                             % equivalent to run_all('default')
% run_all('figures')                % skip raw-processing, only figs + tables
```

Outputs land under `figures/matlab/`. `paths.m` reads these environment
variables if you want to auto-sync outputs into a paper-source tree:

```
PAPER_TREE_DIR   root of the paper tex project
PAPER_FIG_DIR    overrides PAPER_TREE_DIR/figures
PAPER_TEX_PATH   overrides PAPER_TREE_DIR/main_final.tex
PAPER_SUPP_PATH  overrides PAPER_TREE_DIR/supplement.tex
```

When these are unset, the pipeline writes everything locally and does
NOT touch any paper tree.

## What the pipeline computes

| Output                     | From                          | Figure/Table |
|----------------------------|-------------------------------|--------------|
| Bland-Altman PL/DS         | `load_point_data()` xlsx join | Fig. 3       |
| Bland-Altman ASA/ASD       | same                          | Fig. 4       |
| CI-bounded PL scatter      | same + `ci_pl_fit`            | Fig. 5       |
| Omni DS CDFs (merged)      | same + `dkw_band`             | Fig. 6       |
| Omni ASA/ASD CDFs (merged) | same                          | Fig. 7, 8    |
| RMSE cross-threshold       | N3 vs N1, U3 vs U1 (xlsx)     | Table VI     |
| Pooled LOS/NLOS lognormal  | xlsx + bootstrap              | Table VII    |

See Section III of the main paper for the NYU-SUM and USC-perDelayMax
omni-PDP synthesis methods, the noise-floor/delay-gating conventions,
and the institution-specific thresholds applied during cross-processing.

## Bring your own raw data

Our raw measurement data (directional PDPs, ≈ 11 GB) is not
redistributable, but the raw-processing pipeline under
`matlab/processing/` is fully open. If you want to process **your own**
measurement campaign with the same NYU/USC cross-processing
methodology and produce directly-comparable point-data tables, drop
your files into `data/raw/<band>/` using the format documented in
[`docs/input_formats.md`](docs/input_formats.md) and run:

```matlab
cd matlab
run_all('raw')     % raw PDPs → Results/*.mat → figures + tables
```

The four raw-processing scripts (`nyu_142/`, `nyu_7/`, `usc_145/`,
`usc_7/`) each document their expected H-matrix or PDP shape in the
top docstring. See also `matlab/processing/README.md` for a quick
per-script summary.

If you don't have raw data, the **bundled six xlsx files** under
`data/point_data/` are sufficient to reproduce every *published*
figure and data-driven table — just run `run_all` (no argument).

## Citation

```bibtex
@article{Shakya2026twc,
  title   = {Pooling of Multi-Institutional Radio Propagation Empirical Data
             with Cross-Processing Validation for 6G AI/ML Channel Modeling},
  author  = {Shakya, Dipankar and Ying, Mingjun and Abbasi, Naveed A. and
             Gomez-Ponce, Jorge and Liu, Xingchen and Wang, Xinquan and
             Abraham, Daniel and Rappaport, Theodore S. and Molisch, Andreas F.},
  journal = {IEEE Transactions on Wireless Communications},
  year    = {2026},
  note    = {Submitted}
}
```

## License

CC-BY-NC-4.0 — see `LICENSE`. Non-commercial reuse with attribution.
