# NYU 6.75 GHz cross-processing

Produces `Results/all_comparison_results.mat` and companion
`.xlsx` / `.csv`. Feeds the 6.75 GHz NYU panels of Fig 3 / Fig 4
(BA PL/DS/AS at FR1C) and Fig 6 / Fig 7 / Fig 8 (CDFs at 6.75 GHz).

## Inputs you must stage

| File | Path | What it is |
|---|---|---|
| Raw PDPs | `data/raw/nyu_7/Data7Pack_TX*_RX*_Aligned.mat` (18 files) | One per TX-RX link. The .mat must contain the aligned / phased-combined PDP per link. See the file header of `NYU7GHz_Method_Comparison.m` for required fields. |
| TX power table | `share/matlab/processing/nyu_7/7GHz_Outdoor (1).csv` | Per-link TX power |
| Azimuth pattern | `share/matlab/processing/nyu_7/7_phi0_pd.mat` | H-plane antenna pattern (.mat, two columns: angle_deg, gain_dB) |
| Elevation pattern | `share/matlab/processing/nyu_7/7_phi90_pd.mat` | E-plane antenna pattern (same format) |

If your hardware differs, drop equivalent files at the same filenames or
redirect via `paths().nyu_7_phi0` / `nyu_7_phi90`.

## Run

```matlab
NYU7GHz_Method_Comparison;     % with repo addpaths set up
```

## Outputs

```
share/matlab/processing/nyu_7/Results/
  ├── all_comparison_results.mat
  ├── NYU7GHz_Method_Comparison_Results.xlsx
  └── NYU7GHz_Method_Comparison_Results.csv
```
