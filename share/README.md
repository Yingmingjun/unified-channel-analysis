# Unified Channel Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![MATLAB R2021a+](https://img.shields.io/badge/MATLAB-R2021a%2B-blue.svg)](#prerequisites)
[![Paper parity: 108/108 TIGHT](https://img.shields.io/badge/Paper_parity-108%2F108-brightgreen.svg)](#verification)

**Reproduce the 16 figures and 6 tables** of *"Joint Point-Data Format for
Sub-THz and 6.75 GHz Outdoor UMi Propagation: Cross-Processing between
NYU and USC Campaigns"* (IEEE TWC, submitted).

> The paper PDF and the full supplement are included in
> [`docs/supplement.pdf`](./docs/supplement.pdf).

This package is **code only**. No channel measurement data ships
with it. You bring your own PDPs (organized per
[`DATA_ORGANIZATION.md`](./DATA_ORGANIZATION.md)), the pipeline does
the rest.

---

## What this reproduces

| Paper artifact | Script that produces it |
|---|---|
| **Fig 3** — Bland-Altman PL / DS at sub-THz + 6.75 GHz | `matlab/figures/fig03_bland_altman_pl_ds.m` |
| **Fig 4** — Bland-Altman ASA / ASD at sub-THz + 6.75 GHz | `matlab/figures/fig04_bland_altman_as.m` |
| **Fig 5** — CI path-loss scatter, pooled + per-institution fits | `matlab/figures/fig05_ci_pl_scatter.m` |
| **Fig 6** — Omni RMS DS CDF with DKW bands | `matlab/figures/fig06_ds_cdf.m` |
| **Fig 7** — Omni ASA CDF | `matlab/figures/fig07_asa_cdf.m` |
| **Fig 8** — Omni ASD CDF | `matlab/figures/fig08_asd_cdf.m` |
| **Table VI** — Cross-processing RMSE (ASA / ASD) | `matlab/figures/table06_rmse.m` |
| **Table VII** — Pooled statistics (PLE, σ_SF, DS / ASA / ASD means + 95 % CFI) | `matlab/figures/table07_pooled_stats.m` |
| **Tables N1, N3, U1, U3** — per-link point-data tables | `matlab/figures/table_dumps.m` |

Parity check: **108 / 108 TIGHT** for Table VII, **32 / 32 TIGHT** for
Table VI against the paper's printed values when run on the full NYU +
USC dataset.

---

## Prerequisites

| | Version |
|---|---|
| MATLAB | R2021a or later (for `exportgraphics`, `legend.ItemTokenSize`, `readtable(..., 'VariableNamingRule', 'preserve')`) |
| Toolboxes | Statistics & Machine Learning Toolbox (for `ecdf`, `prctile`, `bootstrp`) |

No proprietary third-party libraries. Antenna-pattern handling is pure
MATLAB; PDP processing uses standard signal-processing primitives.

---

## Quickstart (5 minutes)

### 1. Clone

```bash
git clone https://github.com/Yingmingjun/unified-channel-analysis.git
cd unified-channel-analysis
```

### 2. Stage your data

Follow [`DATA_ORGANIZATION.md`](./DATA_ORGANIZATION.md) — the layout
you need is:

```
data/raw/nyu_142/<27 PDP .mat files>
data/raw/nyu_7/<18 PDP .mat files>
data/raw/usc_145/{LoS,NLoS}/<26 PDP files>
data/raw/usc_7/{LOS Study, OLOS Study}/<17 PDP files>

matlab/patterns/HPLANE Pattern Data 261D-27.DAT      (NYU 142 horn)
matlab/patterns/EPLANE Pattern Data 261D-27.DAT
matlab/processing/nyu_142/140GHz_Outdoor_BaseStation.csv   (per-link TX power)
matlab/processing/nyu_7/{7GHz_Outdoor (1).csv, 7_phi0_pd.mat, 7_phi90_pd.mat}
matlab/processing/usc_145/{aziCut.mat, elevCut.mat}
matlab/processing/usc_7/USC_Midband_Pattern.mat
```

If your hardware differs, drop equivalently-formatted files at the same
paths, or edit [`matlab/config/paths.m`](./matlab/config/paths.m) — it
is the **single source of truth** for every path the pipeline touches.

### 3. Run

```matlab
cd matlab
run_all              % raw → Results → figures    (30–60 min first time)
% or:
run_all('figures')   % skip raw processing if Results/*.mat already exist
                     % (under 2 min)
```

Outputs land in `figures/matlab/` with the exact filenames that the
paper's `\includegraphics` calls expect: `BA_PL.pdf`, `BA_ASA.pdf`,
`PLcombinedPlot.jpg`, `OmniDS_merged.jpg`, `OmniASA_merged.png`, etc.

### 4. Stage into your own paper tree (optional)

```matlab
setenv('PAPER_FIG_DIR', '/path/to/your/paper/figures/');
sync_paper_figs;     % copies + renames the 16 figures into the paper tree
```

---

## Verification

```matlab
paper_parity
```

writes [`docs/paper_parity_matlab.md`](./docs/paper_parity_matlab.md).
A clean run on the full dataset reports:

```
MATLAB vs Paper — Table VI : 32 TIGHT,   0 CLOSE,  0 MISS  (of 32)
MATLAB vs Paper — Table VII: 108 TIGHT,  0 CLOSE,  0 MISS  (of 108)
```

Tolerances: point estimate ≤ 2 % or CFI-width ≤ 15 % = **TIGHT**;
≤ 30 % = **CLOSE**; > 30 % = **MISS**.

---

## Troubleshooting

<details>
<summary><strong>Unrecognized function or variable 'plot_style'</strong></summary>

`matlab/config/` isn't on the MATLAB path. `run_all.m` adds it for
you; if you are running an individual figure script, add the path
first:

```matlab
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'lib'));
```
</details>

<details>
<summary><strong>Unable to find file <code>Results/all_comparison_results.mat</code></strong></summary>

The paper-figure scripts consume `Results/*.mat` produced by the
per-campaign raw-processing scripts. Either:

1. Run `run_all` (default mode) — STEP 1 will generate the `.mat`
   files from your raw PDPs; or
2. Place pre-computed `Results/*.mat` at
   `matlab/processing/<campaign>/Results/` and use
   `run_all('figures')` to skip raw processing.

If `share/` is nested inside a live UCA repo with populated
`Results/`, `paths.m` auto-redirects to the parent — no action needed.
</details>

<details>
<summary><strong>MATLAB parity drops to CLOSE or MISS</strong></summary>

Re-check:
1. `matlab/lib/` is on path (the loaders live there).
2. `rng(paths().RNG_SEED)` — bootstrap CFI widths are RNG-dependent.
3. Your `data/paper_reference/table07_paper_values.csv` matches the
   paper version you're comparing against (see `paper_parity.m`).
</details>

<details>
<summary><strong>Figure position warning on Linux</strong></summary>

MATLAB Display server; figures still export correctly. Export uses
`exportgraphics` which is headless-safe.
</details>

---

## Layout

```
unified-channel-analysis/
├── LICENSE                     MIT
├── CITATION.cff                how to cite the paper
├── CONTRIBUTING.md             issue / PR guide
├── README.md                   you are here
├── DATA_ORGANIZATION.md        the data contract (required reading if
│                               you bring your own measurements)
│
├── docs/
│   └── supplement.pdf          companion supplement to the TWC paper
│
├── matlab/
│   ├── run_all.m               main driver (figures mode skips raw)
│   ├── config/
│   │   ├── paths.m             single source of truth for every path
│   │   └── plot_style.m        matplotlib-ish style reset for figures
│   ├── lib/                    shared math + I/O (load_paper_ba_source,
│   │                           bland_altman, ci_pl_fit, bootstrap_ci,
│   │                           dkw_band, lognormal_stats, save_figure,
│   │                           sync_paper_figs, …)
│   ├── lib_tcsl/               NYU TCSL angular-spread helpers
│   ├── processing/             raw → Results, one folder per campaign
│   │   ├── nyu_142/{script, README.md}
│   │   ├── nyu_7/{script, README.md}
│   │   ├── usc_145/{script, README.md}
│   │   └── usc_7/{scripts, README.md}
│   ├── paper_figures/          paper-authoritative figure scripts
│   │                           (BA_AS_Merged, DS_CDF_Merged,
│   │                           AS_CDF_Merged, PL_CI_Merged, …)
│   ├── figures/                unified drivers: fig03–fig08, tables,
│   │                           paper_parity
│   ├── patterns/README.md      antenna-pattern drop contract
│   │                           (no pattern files shipped)
│   └── tools/                  stage_paper_figures, update_paper_tex, …
│
└── data/
    ├── README.md               what must go under data/
    └── paper_reference/        paper-asserted scalar values used by
                                paper_parity.m (Tables VI + VII)
```

---

## What is explicitly **not** shipped

| | Why |
|---|---|
| Raw PDPs (`data/raw/**`) | Channel measurement data — bring your own. |
| Thresholded PDPs | Derived channel measurement data. |
| Antenna-pattern files (`*.DAT`, `aziCut.mat`, etc.) | Characterizations of the paper's hardware; document your own. |
| TX-power CSVs (`140GHz_Outdoor_BaseStation.csv`, …) | Per-link calibration specific to the paper's campaigns. |
| Per-link point tables (`N1/N3/U1/U3 UMi xlsx`) | Aggregate measurement data. |
| Method-comparison results (`*_results.xlsx`, `Results/*.mat`) | Pipeline output, regenerated from raw. |

`.gitignore` keeps these out of your local commits automatically.

---

## Citation

See [`CITATION.cff`](./CITATION.cff) for the machine-readable citation.
BibTeX will be provided once the paper's DOI is assigned.

## License

[MIT](./LICENSE). You are free to use this code in commercial products,
modify it, and redistribute it — just preserve the copyright notice.

## Contact

Open an issue on GitHub, or email the corresponding authors listed in
`CITATION.cff`.
