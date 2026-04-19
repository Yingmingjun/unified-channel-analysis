# Pipeline overview

End-to-end flow, so a reader can navigate the code independently of
the paper prose. Both the Python and MATLAB implementations follow
the same stages.

## Inputs

Six **point-data xlsx files** under `data/point_data/`, one per
dataset × frequency × processing method:

```
N1_142_UMi.xlsx     NYU data, NYU processing,  142 GHz
N1_7_UMi.xlsx       NYU data, NYU processing,  6.75 GHz
U3_142_UMi.xlsx     USC data, NYU replicated at USC, 145 GHz
                     (with NYU thres, USC thres, USC orig. (U1) columns)
U3_7_UMi.xlsx       USC data, NYU replicated at USC, 6.75 GHz
N3_142_UMi.xlsx     NYU data, USC replicated at NYU, 142 GHz
                     (with USC thres, NYU thres, NYU orig. (N1) columns)
N3_7_UMi.xlsx       NYU data, USC replicated at NYU, 6.75 GHz
```

Column-level schema lives in
[`docs/input_formats.md`](input_formats.md) §1. The U1 and N1
"golden" reference values (institution method on its own data) are
embedded as shaded columns inside the U3/N3 files — there are no
standalone U1 files by design.

## Analysis conventions

| Quantity | Definition used in this package |
|----------|--------------------------------|
| **Path loss** | `PL = -10·log10(sum(omni_PDP))` in dB, where the omni PDP is synthesized by the row-owning method (NYU SUM or USC perDelayMax). |
| **Delay spread** | 2nd central moment of the omni PDP, in nanoseconds. |
| **Angular spread** | Fleury circular definition `AS = sqrt(-2·ln|E[e^{jφ}]|)` on the PAS; 3GPP circular STD is available via `fleury_to_gpp.m` for cross-validation. |
| **Lognormal fit** | Compute `mean ± std` on `log10(x)`; report `mean_lin = 10^(μ + ½σ²·ln 10)` (lognormal mean, not median). |
| **Bootstrap CFI** | 2000 percentile-method resamples on `log10(x)`; CFIs reported in both log and linear scale. RNG seed = 0 on both Python and MATLAB. |
| **DKW CDF band** | `ε = sqrt(½·ln(2/α)/n)`, α = 0.05. |

Section III of the main paper documents the institution-specific
thresholds (NYU 25 dB below peak / 5 dB above noise, + 10 dB spatial
SLT; USC 12 dB above max-per-direction noise) and the NYU-SUM vs
USC-perDelayMax omni-PDP syntheses.

## Flow

```
         ┌─────────────────────┐
         │ 6 point-data xlsx   │
         │ data/point_data/    │
         └──────────┬──────────┘
                    │   MATLAB: lib/load_point_data.m
                    │   Python: channel_analysis.io.load_point_data
                    ▼
         ┌─────────────────────────┐
         │ tidy long-form table:    │
         │   institution, band,     │
         │   tx_rx_id, env (LOS/    │
         │     NLOS), d_m,          │
         │   pl_nyu_sum, pl_usc_pdm,│
         │   ds_*, asa_*, asd_*     │
         └──────────┬──────────────┘
                    │
   ┌────────────────┼─────────────────────┐
   ▼                ▼                     ▼
Fig 3–4          Fig 5                 Fig 6–8
 BA PL/DS/AS      CI PL scatter         CDFs (DS, ASA, ASD)
   │                │                     │
   │            Table VI               Table VII
   │            cross-threshold RMSE    pooled lognormal
   │            (N3 vs N1, U3 vs U1)    + bootstrap CFI
   ▼
all outputs  →  figures/{python,matlab}/
                ├── fig03_BA_PL{,7}{.png,.pdf,.fig}
                ├── fig03_BA_DS{,7}{.png,.pdf,.fig}
                ├── fig04_BA_ASA{,7}{.png,.pdf,.fig}
                ├── fig04_BA_ASD{,7}{.png,.pdf,.fig}
                ├── fig05_PLcombinedPlot{,7}{.png,.pdf,.fig}
                ├── fig06_OmniDS_merged{,7}{.png,.pdf,.fig}
                ├── fig07_OmniASA_merged{,7}{.png,.pdf,.fig}
                ├── fig08_OmniASD_merged{,7}{.png,.pdf,.fig}
                ├── table06_rmse.csv
                ├── table07_pooled_stats.csv
                └── paper_parity.csv        ← TIGHT / CLOSE / MISS vs published
```

The `paper_parity` audit reports each figure/table cell side-by-side
with the paper's published value and tags each cell:

| Tag    | Criterion                    |
|--------|------------------------------|
| TIGHT  | within ±2 % of paper value   |
| CLOSE  | within ±30 %                 |
| MISS   | outside both                 |

A clean run shows TIGHT on every cell; CLOSE rows are expected only
where the paper quotes a different level of rounding.

## Cross-processing terminology

| Label | Dataset  | Processing method                              | Role               |
|-------|----------|------------------------------------------------|--------------------|
| N1    | NYU data | NYU methodology                                | published reference |
| U1    | USC data | USC methodology                                | published reference |
| N2    | USC data | NYU replicated **at USC** (reads NYU's code)   | validation only    |
| U2    | NYU data | USC replicated **at NYU** (reads USC's code)   | validation only    |
| N3    | NYU data | USC method replicated **at NYU** + NYU threshold sweep | cross-proc output |
| U3    | USC data | NYU method replicated **at USC** + USC threshold sweep | cross-proc output |

The key comparisons in the paper are:

* **N3 vs N1** — isolates the *method* effect (dataset fixed to NYU,
  method varies). Populates paper Table VI rows 1–4.
* **U3 vs U1** — same, with the dataset fixed to USC. Populates Table
  VI rows 5–8.
* **Pooled (N1 ∪ U1)** — drives paper Table VII lognormal rows after
  the cross-processing confirms the two datasets are method-compatible.

The Table VI ASA/ASD rows have zero RMSE *by construction*: the
angular-spread analysis runs on the PAS before the omni-PDP synthesis,
so the SUM/perDelayMax choice doesn't enter.

## Paper-tree sync (optional)

Set any of `PAPER_TREE_DIR`, `PAPER_FIG_DIR`, `PAPER_TEX_PATH`,
`PAPER_SUPP_PATH` in your environment *before* launching `run_all` to
also copy the 16 paper figures to their canonical names (e.g.
`fig03_BA_PL.png` → `BA_PL.png`) inside a local paper tex tree and
regenerate `supplement.tex`. See the top-level README for the full
table.

When none of those env vars are set the pipeline writes everything
locally and never touches an external directory.
