# Python reproducibility pipeline

Primary, verified implementation. Reads the six point-data xlsx files
under [`../data/point_data/`](../data/point_data/) and regenerates
every data-driven paper figure (Fig. 3–8) and every data-driven table
(Table VI, Table VII). Numerically equivalent to the MATLAB port
under [`../matlab/`](../matlab/).

## Install and run

```bash
cd python
pip install -e .                   # installs the package + deps

# (a) entry point declared in pyproject.toml
channel-run-all

# (b) equivalent module invocation
python -m channel_analysis.run_all
```

Outputs land under `<repo>/figures/python/`. To regenerate a single
figure or table:

```bash
python -m channel_analysis.figures.fig03_bland_altman_pl_ds
python -m channel_analysis.figures.fig06_ds_cdf
python -m channel_analysis.figures.table06_rmse
python -m channel_analysis.figures.paper_parity
# …etc.
```

## Package layout

```
src/channel_analysis/
├── __init__.py                  package marker; version string
├── config.py                    repo-wide constants (RNG seed, CI level, paths)
├── io.py                        single loader: load_point_data() → tidy DataFrame
├── pl.py                        Close-In + Floating-Intercept PL fits (+ bootstrap)
├── ds.py                        RMS delay-spread lognormal fit + DKW CDF band
├── angular.py                   Fleury and 3GPP angular-spread primitives
├── bland_altman.py              BA bias / SD / limits of agreement
├── stats.py                     general stats: ECDF, DKW, bootstrap
├── run_all.py                   end-to-end driver (orchestrates figures/*)
├── figures/                     one module per paper figure / table
│   ├── _common.py                 shared matplotlib helpers
│   ├── fig03_bland_altman_pl_ds.py
│   ├── fig04_bland_altman_as.py
│   ├── fig05_ci_pl_scatter.py
│   ├── fig06_ds_cdf.py
│   ├── fig07_asa_cdf.py
│   ├── fig08_asd_cdf.py
│   ├── table06_rmse.py
│   ├── table07_pooled_stats.py
│   ├── table_dumps.py             per-link CSV dumps for the supplement
│   └── paper_parity.py            TIGHT/CLOSE/MISS audit report
└── styles/paper.mplstyle        IEEE two-column fonts + NYU-blue/USC-orange palette
```

Every figure module exposes a `render()` function that returns a dict
of numeric statistics and also saves the PDF/PNG/FIG bundle — useful
for unit tests or for quoting numbers in text.

## Dependencies

See [`pyproject.toml`](pyproject.toml). Minimum runtime stack:

```
python >= 3.10
numpy    >= 1.24
scipy    >= 1.10
pandas   >= 2.0
matplotlib >= 3.7
openpyxl >= 3.1
```

`pip install -e .` pulls them in automatically.

## Paper-tree sync (opt-in)

The same four env vars used by the MATLAB port also drive the Python
pipeline:

| Env var            | Default            | Purpose                           |
|--------------------|--------------------|-----------------------------------|
| `PAPER_TREE_DIR`   | (no sync)          | root of the paper tex project     |
| `PAPER_FIG_DIR`    | `$PAPER_TREE_DIR/figures`         | figure sync target |
| `PAPER_TEX_PATH`   | `$PAPER_TREE_DIR/main_final.tex`  | in-place tex updates |
| `PAPER_SUPP_PATH`  | `$PAPER_TREE_DIR/supplement.tex`  | supplement writer |

`config.py` reads these at import. When all four are empty the
pipeline stays under `<repo>/figures/python/`.

## Parity vs MATLAB

Every figure/table module mirrors a MATLAB counterpart of the same
name and produces byte-identical CSV tables (Table VI, VII) and
visually identical plots (Fig. 3–8). Float-precision divergence is
bounded by bootstrap RNG alignment (`config.RNG_SEED = 0` on both
sides).
