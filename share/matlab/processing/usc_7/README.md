# USC 6.75 GHz cross-processing

Produces `Results/USC7GHz_Full_Results.{mat,xlsx,csv}`. Feeds the
6.75 GHz USC panels of Fig 3 / Fig 4 and the USC curves in
Fig 6 / Fig 7 / Fig 8 at FR1C.

Note: USC 6.75 GHz labels environments as `LOS` / `OLOS`. The pipeline
folds `OLOS → NLOS` for model fitting consistency; `loc_type_raw` in
downstream tables preserves the `OLOS` label.

## Inputs you must stage

| File | Path | What it is |
|---|---|---|
| Raw PDPs (LoS) | `data/raw/usc_7/LOS Study/…` | USC LoS 6.75 GHz links |
| Raw PDPs (OLoS) | `data/raw/usc_7/OLOS Study/…` | USC OLoS 6.75 GHz links |
| 3D antenna pattern | `share/matlab/processing/usc_7/USC_Midband_Pattern.mat` | USC midband antenna 3D pattern |

File-name conventions for individual PDPs inside each subdir are
documented at the top of `USC7GHz_NewData_Processing.m`. The companion
`USC7GHz_Method_Comparison.m` (older variant, kept for reference) runs
the same analysis on an earlier file layout.

## Run

```matlab
USC7GHz_NewData_Processing;    % canonical, feeds run_all
```

## Outputs

```
share/matlab/processing/usc_7/Results/
  ├── USC7GHz_Full_Results.mat
  ├── USC7GHz_Full_Results.xlsx
  └── USC7GHz_NewData_Results.csv
```
