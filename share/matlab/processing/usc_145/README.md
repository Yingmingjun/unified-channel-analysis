# USC 145 GHz cross-processing

Produces `Results/USC145GHz_Full_Results.{mat,xlsx,csv}`. Feeds the
sub-THz USC panels of Fig 3 / Fig 4 and the USC curves in
Fig 6 / Fig 7 / Fig 8.

## Inputs you must stage

| File | Path | What it is |
|---|---|---|
| Raw PDPs (LoS) | `data/raw/usc_145/LoS/…` | USC LoS links |
| Raw PDPs (NLoS) | `data/raw/usc_145/NLoS/…` | USC NLoS links |
| H-plane pattern | `share/matlab/processing/usc_145/aziCut.mat` | USC horn H-plane cut, `[181 × 2]` (angle_deg, gain_dB) |
| E-plane pattern | `share/matlab/processing/usc_145/elevCut.mat` | USC horn E-plane cut, same shape |

File-name conventions for individual PDPs inside `LoS/` / `NLoS/` are
documented at the top of `USC142GHz_Method_Comparison_Full.m`. If your
USC drop has different file naming, edit the `dir()` glob and field
accessors in that script; everything downstream is name-agnostic once
the per-link struct is populated.

## Run

```matlab
USC142GHz_Method_Comparison_Full;
```

## Outputs

```
share/matlab/processing/usc_145/Results/
  ├── USC145GHz_Full_Results.mat                ← struct `results`
  ├── USC145GHz_Full_Results.xlsx
  └── USC145GHz_Full_Results.csv
```
