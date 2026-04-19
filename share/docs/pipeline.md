# Pipeline overview

This document describes the end-to-end flow, so a reader can navigate
the code independently of the paper prose.

## Inputs

The pipeline begins from **six point-data xlsx files** (one per
dataset × frequency × processing method). These files contain per-link
large-scale parameters already computed from raw channel measurements:

```
N1_142_UMi.xlsx  NYU data, NYU processing,  142 GHz
N1_7_UMi.xlsx    NYU data, NYU processing,  6.75 GHz
U3_142_UMi.xlsx  USC data, USC processing,  145 GHz (also: NYU thr, USC thr, USC orig.)
U3_7_UMi.xlsx    USC data, USC processing,  6.75 GHz
N3_142_UMi.xlsx  NYU data, USC processing,  142 GHz (also: USC thr, NYU thr, NYU orig.)
N3_7_UMi.xlsx    NYU data, USC processing,  6.75 GHz
```

## Conventions

* **Path loss** is computed as `PL = -10*log10(sum(PDP_omni))`, in dB,
  with the omni PDP synthesized by the institution's method.
* **Delay spread** is the 2nd central moment of the omni PDP, converted
  to nanoseconds.
* **Angular spread** uses the Fleury circular definition
  `sqrt(E[|e^{jφ}|²]) → arccos`. 3GPP form
  `sqrt(-2 ln r)` is used for cross-institution validation only.
* **Lognormal fits** convert each per-link value `x` to `log10(x)`,
  compute mean/std of the base-10 log, then report
  `mean_lin = 10^(μ + ½σ² ln 10)` (the lognormal mean, not the
  median).
* **Bootstrap CI** uses 2000 bootstrap resamples on log10(x); the 95 %
  CI is reported on both the log and the linear scale.
* **DKW bands** use ε = √(½ ln(2/α)/n) with α = 0.05.

See Section III of the main paper for institution-specific thresholds
and for the **NYU SUM** vs **USC perDelayMax** omni-PDP synthesis
methods. The xlsx columns reflect those conventions verbatim.

## Flow

```
      ┌─────────────────────┐
      │ 6 point-data xlsx   │
      │ (data/point_data/)  │
      └──────────┬──────────┘
                 │ load_point_data() in MATLAB
                 │ io.load_point_data() in Python
                 ▼
        ┌────────────────────┐
        │ tidy DataFrame /   │
        │ table with cols:   │
        │   institution,     │
        │   band, link_id,   │
        │   env, d_m, pl_*, │
        │   ds_*, asa_*, asd_*│
        └──────────┬─────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
Fig 3–4        Fig 5           Fig 6–8
 BA PL/DS/AS    CI PL scatter    CDFs (DS/ASA/ASD)
    │              │              │
    │          Table 6            Table 7
    │          RMSE (N3-N1,       lognormal
    │           U3-U1)             pooled stats
    ▼
 fig03..fig08
 .png/.pdf/.fig
```

## Cross-processing terminology

| Label | Dataset        | Processing method       |
|-------|----------------|-------------------------|
| N1    | NYU data       | NYU methodology         |
| U1    | USC data       | USC methodology         |
| N2    | USC data       | NYU (replicated at USC) — validation only |
| U2    | NYU data       | USC (replicated at NYU) — validation only |
| N3    | NYU data       | USC replicated at NYU; USC threshold      |
| U3    | USC data       | NYU replicated at USC; NYU threshold      |

The **N3–N1** and **U3–U1** comparisons in Table VI isolate the
method effect with the dataset fixed. The zero-RMSE rows in Table VI
for AS confirm that the angular-spread analysis is insensitive to the
omni-PDP synthesis choice (it operates on the PAS before synthesis).

## Outputs

```
figures/matlab/     and     figures/python/
├── fig03_BA_PL{,7}.png/.pdf/.fig
├── fig03_BA_DS{,7}.png/.pdf/.fig
├── fig04_BA_ASA{,7}.png/.pdf/.fig
├── fig04_BA_ASD{,7}.png/.pdf/.fig
├── fig05_CI_PL{,7}.png/.pdf/.fig
├── fig06_DS_CDF{,7}.png/.pdf/.fig
├── fig07_ASA_CDF{,7}.png/.pdf/.fig
├── fig08_ASD_CDF{,7}.png/.pdf/.fig
├── table06_rmse.csv
├── table07_pooled_stats.csv
└── paper_parity.md           ← TIGHT/CLOSE/MISS vs published values
```

The `paper_parity.md` report tells you at a glance whether your run
matches the numbers in the paper (TIGHT = within 2 %; CLOSE = within
30 %; MISS = outside both).
