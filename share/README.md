# Unified Channel Analysis — reproduction package

This folder contains **only code** to reproduce the 16 figures and 6 tables
of the companion paper *"Joint Point-Data Format for Sub-THz / 6.75 GHz
Outdoor UMi Propagation"* (USC–NYU cross-processing study) from your own
channel measurement data.

**No channel measurement data is shipped.** No raw PDPs, no thresholded
PDPs, no aggregate point-data tables, no `Results/*.mat`. You bring the
measurements; this pipeline turns them into the paper's figures and
tables.

---

## What reproduces from here

- **Fig 3** — Bland-Altman PL / DS (sub-THz + 6.75 GHz), 4 panels
- **Fig 4** — Bland-Altman ASA / ASD (sub-THz + 6.75 GHz), 4 panels
- **Fig 5** — CI path-loss scatter with pooled + per-institution fits
  (sub-THz + 6.75 GHz), 2 panels
- **Fig 6** — Omni RMS DS CDF + DKW confidence bands (sub-THz +
  6.75 GHz), 2 panels × (LOS | NLOS)
- **Fig 7** — Omni ASA CDF, 2 panels × (LOS | NLOS)
- **Fig 8** — Omni ASD CDF, 2 panels × (LOS | NLOS)
- **Table VI** — USC ↔ NYU cross-processing RMSE for ASA / ASD
- **Table VII** — Pooled per-dataset statistics (PLE, σ_SF, DS/ASA/ASD
  means + 95 % CFI widths)
- **Tables N1, N3, U1, U3** — partial per-TX-RX-link point tables

---

## Quick start (MATLAB)

```matlab
% 1. Stage your raw data per DATA_ORGANIZATION.md (see that file for
%    directory layout, filename conventions, and antenna pattern
%    contracts for each of the 4 measurement campaigns).

% 2. Point the pipeline at your data. Either:
%    (a) place everything under <share>/data/raw/<campaign>/ and
%        <share>/matlab/processing/<campaign>/*.csv and *.mat
%        exactly as DATA_ORGANIZATION.md describes -- no edits needed; OR
%    (b) set the CHANNEL_DATA_ROOT environment variable to your data drop
%        root before launching MATLAB.

% 3. From MATLAB:
cd <share>/matlab
run_all              % raw -> Results -> figures (30-60 min first run)
% or:
run_all('figures')   % skip raw processing, just regenerate figures
                     % from existing Results/*.mat
```

Figures land in `<share>/figures/matlab/` (or a custom
`paths().paper_fig_out` if you prefer), named `BA_PL.pdf`,
`BA_ASA.pdf`, `PLcombinedPlot.jpg`, `OmniDS_merged.jpg`,
`OmniASA_merged.png`, etc. — these are the filenames the paper
`\includegraphics` calls expect.

To stage those 16 files into your paper source tree in one step:

```matlab
setenv('PAPER_FIG_DIR', '/path/to/paper/figures');
sync_paper_figs();
```

---

## Quick start (Python parity)

The `python/` subtree mirrors the MATLAB figures for independent
verification. It reads the same point-data table layout as MATLAB.

```bash
cd share/python
pip install -e .
python -m channel_analysis.run_all
```

Outputs land in `figures/python/` (CSV summaries + matplotlib-rendered
PNG/PDF). The Python numbers should agree with MATLAB to ~2 % for point
estimates and ~15 % for bootstrap CFI widths (TIGHT tolerance).

---

## Directory map

```
share/
├── README.md                  ← you are here
├── DATA_ORGANIZATION.md       ← the data contract (required reading)
├── matlab/
│   ├── run_all.m              ← main driver (figures mode skips raw)
│   ├── config/paths.m         ← every file path, derived from repo root
│   ├── lib/                   ← shared math + I/O helpers
│   ├── lib_tcsl/              ← NYU TCSL-based per-location helpers
│   ├── processing/            ← raw → Results, one folder per campaign
│   │   ├── nyu_142/
│   │   ├── nyu_7/
│   │   ├── usc_145/
│   │   └── usc_7/
│   ├── paper_figures/         ← the paper-authoritative figure scripts
│   │                            (BA_AS_Merged, DS_CDF_Merged, …)
│   ├── figures/               ← unified drivers: fig03–fig08, tables,
│   │                            paper_parity
│   └── tools/                 ← helpers (stage_paper_figures,
│                                update_paper_tex, …)
├── python/                    ← Python mirror (optional parity)
└── data/
    ├── README.md              ← explains what must go under data/
    └── paper_reference/       ← paper-asserted scalar values used by
                                 paper_parity.m (NOT measurements)
```

---

## What is *explicitly* NOT shipped

| Category | Why |
|---|---|
| Raw PDPs (`data/raw/**`) | Channel measurement data — bring your own. |
| Thresholded PDPs | Derived channel measurement data. |
| Antenna pattern files (`*.DAT`, `aziCut.mat`, etc.) | Antenna characterization for the paper's hardware; document your own. |
| TX power CSVs (`140GHz_Outdoor_BaseStation.csv`, …) | Per-link calibration specific to the paper's campaigns. |
| Per-location point tables (`N1_*_UMi.xlsx`, `N3_*_UMi.xlsx`, `U3_*_UMi.xlsx`) | Aggregate measurement data. |
| Method-comparison results (`*_results.xlsx`, `Results/*.mat`) | Pipeline output, regenerated from raw. |

`paper_reference/table06_paper_values.csv` and
`paper_reference/table07_paper_values.csv` **are** shipped — they are the
paper's printed numbers, used by `paper_parity.m` to score your
pipeline's output vs the paper. They are not measurements.

---

## Repository commit the figures match

MATLAB paper-parity target: commit **`6df3164`** in the UCA repo and
commit **`a97b3c4`** (and onward) in the paper repo — the first draft
ready for submission. Against those references the pipeline scores
**108 / 108 TIGHT** for Table VII and **32 / 32 TIGHT** for Table VI.
