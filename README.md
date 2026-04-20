# Unified Channel Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![MATLAB R2021a+](https://img.shields.io/badge/MATLAB-R2021a%2B-blue.svg)](#prerequisites)
[![MILCOM 2025](https://img.shields.io/badge/Paper-MILCOM_2025-orange.svg)](https://doi.org/10.1109/MILCOM64451.2025.11309979)
[![TWC submitted](https://img.shields.io/badge/Journal-TWC_under_review-lightgrey.svg)](#companion-paper-under-review-at-ieee-twc)
[![Paper parity: 108/108 TIGHT](https://img.shields.io/badge/Paper_parity-108%2F108-brightgreen.svg)](#verification)

**Reference implementation** of the standardized machine-readable
**point-data format** for wireless propagation measurements, introduced
at IEEE MILCOM 2025. This package lets any research group — academic or
industry — publish, consume, and cross-process channel measurements
under one common schema, then reproduce the 16 figures and 6 tables of
the companion IEEE TWC submission end-to-end.

## What you get

### 🔗 A standardized data-sharing pipeline for multi-institutional propagation campaigns

If your lab measures outdoor / indoor propagation and you want to
**share per-link summaries in a machine-readable way** (for pooling
with partner institutions, for AI/ML model training, or for publishing
alongside a paper):

- Drop your per-location PDPs in the [`data/raw/`](./DATA_ORGANIZATION.md) layout.
- Run `matlab/run_all.m`.
- Out comes a **point-data xlsx** (`N<x>_<band>_UMi.xlsx`) with one row per TX–RX link, carrying PL, omni DS, omni/per-cluster ASA/ASD, 3GPP Fleury-based angular-spread variants, 10/15/20 dB threshold-sensitivity columns — all in the MILCOM 2025 schema.
- The same format is consumed by the paper's pooled-statistics, CI path-loss-fit, and Bland–Altman cross-processing scripts, so your campaign can be pooled with NYU's and USC's measurements byte-for-byte.

**Who this is for:** 3GPP contributors, IEEE 802 working groups, 6G
industry consortia, academic propagation labs — anyone generating
per-link measurement tables.

### 🔁 A reproduction package for the journal paper (under review at IEEE TWC)

If you are reviewing the companion paper or want to cross-check its
numbers against your own data:

- `matlab/run_all('figures')` regenerates **Fig 3, Fig 4, Fig 5, Fig 6,
  Fig 7, Fig 8** and **Tables VI, VII, N1, N3, U1, U3** from existing
  `Results/*.mat` (under 2 minutes).
- `matlab/figures/paper_parity.m` scores your pipeline output against
  the paper's printed values. Target: **108/108 TIGHT on Table VII
  and 32/32 TIGHT on Table VI** (point estimates ≤ 2 %, bootstrap
  CFI widths ≤ 15 % relative).
- The paper's camera-ready numbers and this repo's outputs agree
  line-for-line when run on the full NYU + USC dataset.

---

## The point-data format in one paragraph

Per-link channel-measurement summaries, tabulated in a **three-row
xlsx header**:

| Row | Content |
|---|---|
| 1 | Free-form title banner (dropped by parsers) |
| 2 | Metric family — one of: `TX`, `RX`, `Loc Type`, `TR Sep`, `Omni PL`, `Omni DS`, `Omni ASA`, `Omni ASD` |
| 3 | Processing variant — one of: `NYU orig. (N1)`, `NYU thres`, `USC thres`, `USC orig. (U1)` |

One data row per TX–RX link. Extensible to additional metric families
(e.g. `Omni ZSA`, `Omni ZSD`, `K-factor`) and additional processing
variants without breaking any parsers already wired to the schema.
Schema documented in [`DATA_ORGANIZATION.md`](./DATA_ORGANIZATION.md)
and in the `load_point_data.m` parser.

---

## Prerequisites

| | Version |
|---|---|
| MATLAB | R2021a or later (for `exportgraphics`, `legend.ItemTokenSize`, `readtable(..., 'VariableNamingRule', 'preserve')`) |
| Toolboxes | Statistics & Machine Learning (for `ecdf`, `prctile`, `bootstrp`) |

No proprietary third-party libraries. Antenna-pattern handling is pure
MATLAB; PDP processing uses standard DSP primitives.

---

## Quickstart (5 minutes)

### 1. Clone

```bash
git clone https://github.com/Yingmingjun/unified-channel-analysis.git
cd unified-channel-analysis
```

### 2. Stage your data

Follow [`DATA_ORGANIZATION.md`](./DATA_ORGANIZATION.md). The layout is:

```
data/raw/<campaign>/            your raw PDPs
matlab/processing/<campaign>/   your antenna patterns, TX-power CSVs
```

If your measurement hardware matches the paper's, drop files with the
default names. Otherwise, edit
[`matlab/config/paths.m`](./matlab/config/paths.m) — the single source
of truth for every path the pipeline touches.

### 3. Run

```matlab
cd matlab
run_all              % raw → Results → figures + tables (30–60 min first time)
% or:
run_all('figures')   % skip raw processing if Results/*.mat already exist (< 2 min)
```

### 4. Outputs

- `figures/matlab/BA_PL.pdf`, `BA_ASA.pdf`, `OmniDS_merged.jpg`, … (16 files, paper-ready filenames)
- `figures/matlab/table06_rmse.csv`, `table07_pooled_stats.csv`, `table{08,09,10,11}_*.csv`
- `docs/paper_parity_matlab.md` — parity score vs paper values

---

## Verification

```matlab
paper_parity
```

Expected on the full dataset:

```
MATLAB vs Paper — Table VI : 32 TIGHT,   0 CLOSE,  0 MISS  (of 32)
MATLAB vs Paper — Table VII: 108 TIGHT,  0 CLOSE,  0 MISS  (of 108)
```

Tolerances: point estimates ≤ 2 % or CFI widths ≤ 15 % = **TIGHT**;
≤ 30 % = **CLOSE**; > 30 % = **MISS**.

---

## What is explicitly **not** shipped

No channel measurement data of any kind. The data contract is documented;
this repository is code + documentation only.

| Excluded | Why |
|---|---|
| Raw / thresholded PDPs | You provide your own measurements. |
| Antenna-pattern files | Characterization of the paper's hardware; document your own. |
| TX-power CSVs | Per-link calibration specific to the paper's campaigns. |
| N1 / N3 / U1 / U3 UMi xlsx | Aggregate measurement data — regenerated by the pipeline. |
| `Results/*.mat` | Pipeline output. |

`.gitignore` keeps these out of downstream commits automatically.

---

## Troubleshooting

<details>
<summary><strong>Unrecognized function or variable 'plot_style'</strong></summary>

`matlab/config/` isn't on the MATLAB path. `run_all.m` adds it for you
automatically; for individual figure scripts, add the paths first:

```matlab
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'lib'));
addpath(genpath(fullfile(pwd, 'lib_tcsl')));
```
</details>

<details>
<summary><strong>Unable to find <code>Results/all_comparison_results.mat</code></strong></summary>

The paper-figure scripts consume `Results/*.mat` from the raw-processing
stage. Either run `run_all` (full pipeline) or stage pre-computed
`Results/*.mat` and run `run_all('figures')`.
</details>

<details>
<summary><strong>Paper parity drops to CLOSE or MISS</strong></summary>

1. Confirm `matlab/lib/` is on path (the loaders live there).
2. Bootstrap CFI widths are RNG-dependent — `paths().RNG_SEED = 0` is
   honored in every figure script.
3. Re-check your `data/paper_reference/table07_paper_values.csv`
   matches the paper version you are comparing against.
</details>

---

## Companion paper (under review at IEEE TWC)

> D. Shakya, M. Ying, N. A. Abbasi, J. Gomez-Ponce, X. Liu, X. Wang,
> D. Abraham, T. S. Rappaport, A. F. Molisch,
> *"Pooling of Multi-Institutional Radio Propagation Empirical Data with
> Cross-Processing Validation for 6G AI/ML Channel Modeling,"*
> submitted to **IEEE Transactions on Wireless Communications**, 2026.

The 16 figures and Tables VI / VII in that submission are regenerated
verbatim by this repository.

---

## Citing this work

Please cite the MILCOM 2025 paper that introduces the point-data format
this repository implements:

```bibtex
@INPROCEEDINGS{Shakya2025milcom,
  author    = {Shakya, Dipankar and Abbasi, Naveed A. and Ying, Mingjun
               and Jariwala, Isha and Qin, Jason J. and Gupte, Ishaan S.
               and Meier, Bridget and Qian, Guanyue and Abraham, Daniel
               and Rappaport, Theodore S. and Molisch, Andreas F.},
  booktitle = {MILCOM 2025 - 2025 IEEE Military Communications Conference (MILCOM)},
  title     = {Standardized Machine-Readable Point-Data Format for
               Consolidating Wireless Propagation Across Environments,
               Frequencies, and Institutions},
  year      = {2025},
  pages     = {232--237},
  doi       = {10.1109/MILCOM64451.2025.11309979},
  keywords  = {Wireless communication; Antenna measurements; Industries;
               Statistical analysis; Organizations; Radio propagation;
               Loss measurement; Frequency measurement; Delays;
               Reliability; Wireless propagation; channel sounding;
               standardized data format; 6G; machine learning}
}
```

`CITATION.cff` carries the machine-readable version used by GitHub's
"Cite this repository" button. A BibTeX entry for the companion TWC
paper will be added once the journal assigns it a DOI.

---

## Layout

```
unified-channel-analysis/
├── LICENSE                     MIT
├── CITATION.cff                how to cite (GitHub-native format)
├── CONTRIBUTING.md             short issue / PR guide
├── README.md                   you are here
├── DATA_ORGANIZATION.md        the data contract (required reading if
│                               you bring your own measurements)
│
├── docs/
│   └── supplement.pdf          companion supplement to the TWC paper
│
├── matlab/
│   ├── run_all.m               main driver
│   ├── config/
│   │   ├── paths.m             single source of truth for every path
│   │   └── plot_style.m        figure-style reset
│   ├── lib/                    shared math + I/O helpers
│   ├── lib_tcsl/               NYU TCSL angular-spread helpers
│   ├── processing/             raw → Results, one folder per campaign
│   │   ├── nyu_142/, nyu_7/, usc_145/, usc_7/
│   │   └── …/README.md         per-campaign raw file contract
│   ├── paper_figures/          paper-authoritative figure scripts
│   ├── figures/                unified drivers: fig03–fig08, tables,
│   │                           paper_parity
│   ├── patterns/README.md      antenna-pattern drop contract
│   └── tools/                  stage_paper_figures, update_paper_tex, …
│
└── data/
    ├── README.md               what must go under data/
    └── paper_reference/        Tables VI + VII paper-asserted scalars
                                (used by paper_parity.m; not measurements)
```

---

## License

[MIT](./LICENSE). Free for commercial use, modification, redistribution —
just preserve the copyright notice.

## Contact

Open an issue on GitHub, or email Mingjun Ying
(`yingmingjun [at] nyu [dot] edu`).
