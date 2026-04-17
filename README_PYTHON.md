# Python — verified reference implementation

`channel_analysis` is a pure-Python package that consumes the NYU/USC point-data xlsx tables and reproduces every Fig. 3–8 and Tables 6, 7 of the paper.

## Requirements

- Python ≥ 3.10
- numpy, scipy, pandas, matplotlib, openpyxl (pinned in `pyproject.toml`)

## Installation

```bash
cd python
python -m pip install -e .           # library + CLI entry point
python -m pip install -e .[dev]      # add pytest
```

The `-e` (editable) install is recommended during authoring so edits to `src/` take effect immediately.

## Configure data paths

The loader reads point-data tables from four xlsx files (the N3 and U3 cross-processing tables; the "NYU orig"/"USC orig" columns of each provide the N1/U1 baseline values — see `docs/issues_log.md` for why).

Default paths point at
```
D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/
  USC/USCprocessNYUdata/OriginalNYU_pointData/
    142_UMi_N3.xlsx, 7_UMi_N3.xlsx
  NYU/NYUprocessUSCdata/OriginalUSC-PointData/
    142_UMi_U3.xlsx, 7_UMi_U3.xlsx
```

Override the root with the `CHANNEL_DATA_ROOT` environment variable:
```bash
# bash / zsh
export CHANNEL_DATA_ROOT=/path/to/NaveedDipankarMingjunJorgeShare

# PowerShell
$env:CHANNEL_DATA_ROOT = 'D:/NaveedDipankarMingjunJorgeShare'
```

Or override individual paths by mutating `channel_analysis.config.DATA_PATHS` in a wrapper script.

## Running the full pipeline

```bash
python -m channel_analysis.run_all
# or, after installing:
channel-run-all
```

This:
1. loads every variant (N1, U1, N3_{nyu,usc}_thr, U3_{nyu,usc}_thr) into a canonical long-format DataFrame,
2. runs each figure/table driver, writes `figures/python/figXX_*.pdf` + `.png`,
3. writes numerical statistics to `figures/python/stats_dump.json` for downstream parity checks,
4. reports any driver that failed and continues.

## Running a single driver

Each driver exposes a `render()` function returning a dict of numerical statistics.

```python
from channel_analysis.figures import fig05_ci_pl_scatter
stats = fig05_ci_pl_scatter.render()
```

## Data-flow summary

```
N1/U1/N3/U3 xlsx   →  io.load_point_data()      →  long-format DataFrame
                      (one row per TX-RX-variant; OLOS → NLOS relabeled)

long-format DF     →  pl.ci_fit()               →  (PLE, σ_SF, bootstrap CFI)
                      ds.lognormal_stats()      →  (lognormal E[X], CFI width)
                      angular.angular_spread_*  →  (3GPP/Fleury/NYU-360 °)
                      stats.dkw_band()          →  95 % CDF band
                      bland_altman.bland_altman →  agreement analysis

results            →  figures/fig0X_*.py        →  PDF + PNG under figures/python/
                      figures/tableXX_*.py      →  CSV under figures/python/
```

## Testing

```bash
cd python
pytest
```

Coverage:
- `test_angular.py` — 3GPP / Fleury / NYU-360 ° equivalences, dB↔linear, edge cases.
- `test_pl.py` — CI and FI fit recovers slope on synthetic data; CFI covers truth at nominal rate.
- `test_ds.py` — RMS delay-spread formula; lognormal stat behavior.
- `test_stats.py` — ECDF, DKW band constant, bootstrap coverage.
- `test_io.py` — loader row-count smoke test (skipped when institutional data is not mounted).

## Module reference

| Module                       | Role                                                |
|------------------------------|-----------------------------------------------------|
| `channel_analysis.config`    | data paths, output directory, figure style, seeds   |
| `channel_analysis.io`        | xlsx/csv → canonical long DataFrame                 |
| `channel_analysis.pl`        | CI and FI path-loss fits, bootstrap CFI on PLE      |
| `channel_analysis.ds`        | RMS delay spread; lognormal summary with bootstrap  |
| `channel_analysis.angular`   | 3GPP, Fleury, NYU 360 °-search angular spreads      |
| `channel_analysis.stats`     | ECDF, DKW band, generic bootstrap CI                |
| `channel_analysis.bland_altman` | mean-diff plot stats, ±1.96 SD limits            |
| `channel_analysis.figures.*` | per-paper-figure drivers                            |
| `channel_analysis.run_all`   | top-level orchestrator / CLI entry                  |

## Troubleshooting

- **`FileNotFoundError: ...142_UMi_N3.xlsx`** — `CHANNEL_DATA_ROOT` points somewhere without the institutional drop. Edit `config.DATA_PATHS` or the env var.
- **Fonts look wrong** — `paper.mplstyle` prefers Times New Roman; it falls back to `DejaVu Serif` if not installed. Install the Liberation Serif or STIX fonts for closer visual parity.
- **Figure sizes differ from paper** — `savefig.dpi = 300` produces a high-res PNG; PDF is vector and resolution-independent.

## Reproducibility notes

- `RNG_SEED = 0` is the default; every bootstrap resampler threads the seed.
- The pipeline is idempotent — re-running produces byte-identical figures.
- See `docs/numerical_parity.md` for the side-by-side comparison vs. the paper.
