# Python reproducibility pipeline

Primary, verified implementation. Reads the six point-data xlsx files
under `../data/point_data/` and regenerates every data-driven paper
figure (Fig. 3–8) and every data-driven table (Table VI, Table VII).

## Install + run

```bash
pip install -e .
channel-run-all            # end-to-end
```

Outputs land under `figures/python/` in the repo root. Each figure can
also be regenerated individually via its driver:

```bash
python -m channel_analysis.figures.fig03_bland_altman_pl_ds
python -m channel_analysis.figures.fig06_ds_cdf
python -m channel_analysis.figures.table06_rmse
# …etc.
```

## Package layout

```
src/channel_analysis/
├── run_all.py                driver for all figures + tables
├── config.py                 repo-wide constants (RNG seed, CI level, ...)
├── io.py                     point-data xlsx reader; returns tidy DataFrame
├── pl.py                     path-loss fit (close-in + floating-intercept)
├── ds.py                     delay-spread lognormal fit + DKW bands
├── angular.py                angular-spread lognormal fit
├── bland_altman.py           BA bias/SD + limits of agreement
├── stats.py                  bootstrap CI, lognormal statistics
├── figures/                  fig03..fig08, table06/07 drivers
└── styles/                   matplotlib style (IEEE two-column)
```

## Dependencies

See `pyproject.toml`. Minimum:

```
numpy>=1.24   scipy>=1.10   pandas>=2.0
matplotlib>=3.7   openpyxl>=3.1
```

Install with `pip install -e .` to pull them automatically.
