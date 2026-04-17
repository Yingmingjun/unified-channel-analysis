# Unified Architecture

## Repository layout

```
joint-nyu-usc-channel-analysis/
├── README.md                                  # project overview, reproducibility status
├── README_PYTHON.md                           # Python setup and usage
├── README_MATLAB.md                           # MATLAB setup and usage
├── LICENSE                                    # CC BY-NC 4.0 — one-line summary + URL
├── LICENSE_FULL.txt                           # downloaded plain-text of the full legal code
├── CITATION.cff                               # authors, title, submission state
├── pyproject.toml                             # Python package metadata
├── requirements.txt                           # pip deps derived from pyproject.toml
├── environment.yml                            # conda deps
├── .gitignore                                 # excludes data/*, *.mat, __pycache__, etc.
├── FINAL_REPORT.md                            # end-of-session parity summary
│
├── python/                                    # PRIMARY implementation
│   ├── src/channel_analysis/
│   │   ├── __init__.py
│   │   ├── config.py                          # DATA_PATHS, FIGURE_DIR, STYLE_PATH
│   │   ├── io.py                              # load_point_data(), canonical long DataFrame
│   │   ├── pl.py                              # CI and FI path-loss models, bootstrap CFI
│   │   ├── ds.py                              # RMS delay spread stats, lognormal fit
│   │   ├── angular.py                         # 3GPP, Fleury, NYU-360°-search RMS AS
│   │   ├── stats.py                           # bootstrap CI, DKW band, ECDF
│   │   ├── bland_altman.py                    # mean/diff/limits-of-agreement
│   │   ├── styles/paper.mplstyle              # matplotlib style matching MATLAB look
│   │   ├── figures/                           # per-paper-figure drivers
│   │   │   ├── fig03_bland_altman_pl_ds.py
│   │   │   ├── fig04_bland_altman_as.py
│   │   │   ├── fig05_ci_pl_scatter.py
│   │   │   ├── fig06_ds_cdf.py
│   │   │   ├── fig07_asa_cdf.py
│   │   │   ├── fig08_asd_cdf.py
│   │   │   ├── table06_rmse.py
│   │   │   └── table07_pooled_stats.py
│   │   └── run_all.py                         # entry point: regenerates every figure/table
│   └── tests/                                 # pytest unit tests
│       ├── test_pl.py
│       ├── test_ds.py
│       ├── test_angular.py
│       └── test_stats.py
│
├── matlab/                                    # SECONDARY parallel port (user runs themselves)
│   ├── run_all.m
│   ├── config/
│   │   ├── paths.m
│   │   └── plot_style.m
│   ├── lib/
│   │   ├── load_point_data.m
│   │   ├── ci_pl_fit.m
│   │   ├── rms_delay_spread.m
│   │   ├── angular_spread_3gpp.m
│   │   ├── angular_spread_fleury.m
│   │   ├── bland_altman.m
│   │   ├── dkw_band.m
│   │   └── bootstrap_ci.m
│   └── figures/                               # per-figure drivers
│       ├── fig03_bland_altman_pl_ds.m
│       ├── fig04_bland_altman_as.m
│       ├── fig05_ci_pl_scatter.m
│       ├── fig06_ds_cdf.m
│       ├── fig07_asa_cdf.m
│       ├── fig08_asd_cdf.m
│       ├── table06_rmse.m
│       └── table07_pooled_stats.m
│
├── figures/
│   ├── python/                                # Python-produced figures (.png + .pdf)
│   └── matlab/                                # MATLAB-produced figures (user populates)
│
├── data/
│   └── README.md                              # point-data schema + expected folder structure
│                                              #  (no actual data shipped)
│
└── docs/
    ├── paper_summary.md
    ├── code_inventory.md / _A.md / _B.md
    ├── paper_to_code_mapping.md
    ├── architecture.md                        # this file
    ├── code_conflicts.md
    ├── issues_log.md
    ├── numerical_parity.md
    └── figure_parity.md
```

## Python design principles

- **src layout** (`python/src/channel_analysis/`) so the package imports only once installed (`pip install -e python`) — prevents accidental shadowing from the working directory.
- **Single config module** (`channel_analysis.config`): `DATA_PATHS` dict with keys `"nyu_142_xlsx"`, `"nyu_7_xlsx"`, `"usc_142_csv_los"`, `"usc_142_csv_nlos"`, `"usc_7_csv_los"`, `"usc_7_csv_nlos"`, `"u3_142_xlsx"`, `"u3_7_xlsx"`, `"n3_142_xlsx"`, `"n3_7_xlsx"` pointing at the absolute paths under `D:/NaveedDipankarMingjunJorgeShare/...`. Override by env var `CHANNEL_DATA_ROOT` or by monkey-patch in tests.
- **Canonical long-format DataFrame** (`io.load_point_data` returns columns `institution, band, freq_ghz, tx, rx, loc_type, d_m, pl_db, mean_dir_ds_ns, omni_ds_ns, mean_lobe_asa_d, omni_asa_d, mean_lobe_asd_d, omni_asd_d, zsa_d, zsd_d, method_variant`). Every downstream module operates on this frame — no per-figure data shaping.
- **Vectorized NumPy/SciPy.** No Python loops over TX–RX pairs. All stats (bootstrap, DKW, Fleury, 3GPP AS) are one-shot array operations.
- **Pure functions** in `pl.py / ds.py / angular.py / stats.py / bland_altman.py`: given an array, return an array. All plotting happens in `figures/*.py`.
- **Style in one file** (`styles/paper.mplstyle`): colors, fonts, line widths loaded via `plt.style.use`.
- **Tests** under `python/tests/` (pytest). The AS module is the most algorithmically dense; tests pin-check Fleury ↔ 3GPP equivalence on synthetic PAS, the NYU 360°-search RMS formula, and known edge cases (delta function → σ=0, uniform → σ=∞-equivalent).

## MATLAB design principles (Phase 6)

- Mirrors the Python package tree 1:1.
- Each `matlab/figures/figXX_*.m` is a standalone script that loads the point-data tables, calls `matlab/lib/` helpers, and saves `.pdf`/`.png` under `figures/matlab/`.
- Every non-obvious block has a comment referencing the paper section or equation (e.g. `% Eq. 10, 3GPP TR 38.901 circular-std-dev`).
- No nested anonymous functions; every helper is a named file-scoped function.
- `run_all.m` invokes each driver in sequence, writes to `figures/matlab/`, and prints a summary.
- Not executed in the sandbox. Documented in `README_MATLAB.md`.

## Data flow

```
[institution xlsx / csv]
        │
        ├─> io.load_point_data()  →  canonical long DataFrame
        │                             (both N1/U1 original and N3/U3 cross-processed)
        │
        ├─> pl.ci_fit()             → (PLE, σ, 95% CFI width)
        ├─> ds.lognormal_stats()    → (mean, std, 95% CFI)
        ├─> angular.{gpp, fleury, nyu360}() → AS values per point
        ├─> stats.dkw_band()        → 95% CDF band
        ├─> stats.bootstrap_ci()    → resampled CIs
        └─> bland_altman.compute()  → (mean, SD diff, ±1.96SD limits)
                        │
                        └─> figures/*.py  →  figures/python/{.png, .pdf}
```

## Reproducibility

- `run_all` is idempotent: re-running produces byte-identical figures given the same input.
- Random seeds are fixed at the start of each driver (`np.random.seed(0)` for bootstraps).
- Numerical results are written to `figures/python/stats_dump.json` alongside the figures for downstream diffing.

## What this architecture deliberately does NOT do

- Does not re-process raw directional PDPs. Those pipelines are proprietary-format-heavy and already published as MATLAB code. The Python port accepts the shared point-data tables as input, consistent with the paper's own position: the point-data format *is* the multi-institution interchange format.
- Does not ship measurement data. `.gitignore` excludes any path matching `*_Data/`, `*.mat`. Users point `DATA_PATHS` at the institutional drops they have access to.
