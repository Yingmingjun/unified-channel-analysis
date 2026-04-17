# Unified processing structure

Both ports follow the same three-tier architecture. Everything is a pure function in `lib/` / a core module in `src/`, composed by a single `run_all` orchestrator, driven by a single `config/` source of truth for paths and style.

## One-shot reproduction

```
Python                                    MATLAB
------                                    ------
cd <repo>                                 cd <repo>/matlab
python -m channel_analysis.run_all        run_all
```

Both produce identical artifacts (figures + CSVs) under `figures/{python,matlab}/` and a self-contained `paper_parity_table06.csv` / `paper_parity_table07.csv` showing Paper vs Python vs MATLAB side-by-side.

## MATLAB directory layout (23 files / ~2100 lines)

```
matlab/
├── run_all.m                       ← orchestrator; calls every driver in order
├── config/
│   ├── paths.m                     ← all input xlsx/csv paths + output dir
│   └── plot_style.m                ← fonts, colors, line widths, dpi
├── lib/                            ← reusable analysis primitives
│   ├── load_point_data.m           ← hybrid loader (4 CSVs + 4 xlsx)
│   ├── ci_pl_fit.m                 ← close-in path-loss fit + bootstrap CFI
│   ├── rms_delay_spread.m          ← RMS delay spread (Eq. 9)
│   ├── angular_spread_3gpp.m       ← 3GPP circular std dev (Eq. 10)
│   ├── angular_spread_fleury.m     ← Fleury AS (Eq. 12)
│   ├── fleury_to_gpp.m             ← Fleury ↔ 3GPP conversion
│   ├── lognormal_stats.m           ← lognormal E[X] + bootstrap CFI
│   ├── bootstrap_ci.m              ← generic bootstrap percentile CI
│   ├── dkw_band.m                  ← DKW 95 % uniform CDF band
│   ├── bland_altman.m              ← paired agreement analysis
│   └── save_figure.m               ← pdf/png/fig exporter at 300 dpi
└── figures/                        ← one driver per paper figure / table
    ├── fig03_bland_altman_pl_ds.m  ← Fig 3 (4 BA figures: BA_PL/DS × 2 bands)
    ├── fig04_bland_altman_as.m     ← Fig 4 (4 BA figures: BA_ASA/ASD × 2 bands)
    ├── fig05_ci_pl_scatter.m       ← Fig 5 (PLcombinedPlot × 2 bands)
    ├── fig06_ds_cdf.m              ← Fig 6 (OmniDS CDF × 2 bands)
    ├── fig07_asa_cdf.m             ← Fig 7 (OmniASA CDF × 2 bands)
    ├── fig08_asd_cdf.m             ← Fig 8 (OmniASD CDF × 2 bands)
    ├── table06_rmse.m              ← Table VI (RMSE of threshold variants)
    ├── table07_pooled_stats.m      ← Table VII (CI PL + lognormal DS/AS)
    ├── table_dumps.m               ← Tables IV, VIII, IX, X, XI (xlsx dumps)
    └── paper_parity.m              ← Paper / Python / MATLAB side-by-side
```

## Python directory layout (mirrors MATLAB 1:1)

```
python/
├── pyproject.toml
├── src/channel_analysis/
│   ├── __init__.py
│   ├── config.py                   ← ports MATLAB paths.m + plot constants
│   ├── io.py                       ← ports MATLAB load_point_data.m
│   ├── pl.py                       ← ports ci_pl_fit.m
│   ├── ds.py                       ← ports lognormal_stats.m + rms_delay_spread.m
│   ├── angular.py                  ← ports angular_spread_*.m + fleury_to_gpp.m
│   ├── stats.py                    ← ports dkw_band.m + bootstrap_ci.m
│   ├── bland_altman.py             ← ports bland_altman.m
│   ├── styles/paper.mplstyle       ← matches plot_style.m
│   ├── figures/                    ← one driver per paper figure / table
│   │   ├── fig03_bland_altman_pl_ds.py    ← 1:1 with MATLAB fig03
│   │   ├── fig04_bland_altman_as.py       ← 1:1
│   │   ├── fig05_ci_pl_scatter.py         ← 1:1
│   │   ├── fig06_ds_cdf.py                ← 1:1
│   │   ├── fig07_asa_cdf.py               ← 1:1
│   │   ├── fig08_asd_cdf.py               ← 1:1
│   │   ├── table06_rmse.py                ← 1:1
│   │   ├── table07_pooled_stats.py        ← 1:1
│   │   ├── table_dumps.py                 ← 1:1
│   │   └── paper_parity.py                ← 1:1
│   └── run_all.py                  ← ports run_all.m
└── tests/                          ← pytest unit tests for each core module
    ├── test_angular.py
    ├── test_pl.py
    ├── test_ds.py
    ├── test_stats.py
    └── test_io.py
```

Every `matlab/figures/*.m` has a header comment of the form
`Mirrors python/src/channel_analysis/figures/....py` (and vice versa).
Every `matlab/lib/*.m` has a matching header pointing at its Python peer.

## Data flow (both ports)

```
data/point_data/                  data/paper_reference/
├── 4 AS CSVs                     └── table06_paper_values.csv
└── 4 point-data xlsx                 table07_paper_values.csv
              │
              ▼
     load_point_data()           ← lib/io module
     ┌───────────────────────────────────────┐
     │  institution | band | freq | tx_rx_id │
     │  d_m | loc_type | pl_db | omni_ds_ns  │
     │  asa_nyu_10 | asa_usc | asd_* | ...   │
     └───────────────────────────────────────┘
              │
    ┌─────────┴──────────┬──────────┬──────────┐
    ▼                    ▼          ▼          ▼
 ci_pl_fit        lognormal_stats  DKW band  bland_altman
  (PLE, σ, CFI)     (mean, CFI)    (ECDF)    (bias, LoA)
              │                    │
              ▼                    ▼
    ┌──────────────────────────────────────┐
    │   figXX_*.m / .py  per-figure driver │  → PDF + PNG + FIG
    │   tableXX_*.m / .py  per-table driver│  → CSV
    │   paper_parity.m / .py               │  → parity CSV + md
    └──────────────────────────────────────┘
              │
              ▼
     figures/{matlab,python}/
```

## Why one driver per figure

- Each paper figure has a single output path and a self-contained spec.
- Makes it trivial to regenerate one figure (`fig05_ci_pl_scatter`) without re-running the whole suite.
- A reader can map paper § → file → output file in one hop.
- Keeps per-figure styling local (legend position, axis limits) without a global plot router.

## Reproduction check built-in

The final driver in both `run_all.m` and `run_all.py` is `paper_parity`. It reads:
- `data/paper_reference/table{06,07}_paper_values.csv` — the exact numbers from the paper's Tables VI and VII
- `figures/python/table{06,07}_*.csv` — the Python port's output
- `figures/matlab/table{06,07}_*.csv` — the MATLAB port's output

and writes `docs/paper_parity.md` + `figures/{python,matlab}/paper_parity_table{06,07}.csv` showing **every Table-VI and Table-VII cell side-by-side** with TIGHT / CLOSE / MISS tags. Summary printed to the console.

## Tolerances (built into `paper_parity`)

| Column type | TIGHT | CLOSE | MISS |
|-------------|-------|-------|------|
| Point estimates (PLE, σ_SF, DS/ASA/ASD means) | ≤ 2 % | ≤ 30 % | > 30 % |
| Bootstrap 95 % CFI widths                     | ≤ 15 % | ≤ 30 % | > 30 % |

CFI widths get a looser "tight" bound because they depend on the bootstrap RNG; MATLAB's `bootstrp` and NumPy's `default_rng` draw different resample indices even at identical seeds, producing 10–20 % natural divergence in CFI widths even when point estimates agree to machine precision.
