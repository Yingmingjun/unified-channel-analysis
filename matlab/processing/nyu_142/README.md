# NYU 142 GHz cross-processing

Produces `Results/all_comparison_results.mat` and the companion
`.xlsx` / `.csv` method-comparison tables. These are the inputs for
Fig 3 / Fig 4 (BA PL/DS/AS at sub-THz) and Fig 6 / Fig 7 / Fig 8
(CDFs) at sub-THz for the NYU dataset.

## Inputs you must stage

| File | Path | What it is |
|---|---|---|
| Raw PDPs | `data/raw/nyu_142/142GHz_Outdoor_*.mat` (27 files) | One per TX-RX link. See the file header of `NYU142GHz_Method_Comparison.m` for the field-name contract (PDP vectors, azimuth / elevation grids, frequency, TX/RX heights). |
| TX power table | `share/matlab/processing/nyu_142/140GHz_Outdoor_BaseStation.csv` | Per-link TX power (one row per TX-RX ID) |
| H-plane pattern | `share/matlab/patterns/HPLANE Pattern Data 261D-27.DAT` | NYU 261D-27 horn H-plane |
| E-plane pattern | `share/matlab/patterns/EPLANE Pattern Data 261D-27.DAT` | Same horn E-plane |

If your measurement hardware is not the NYU 261D-27 horn, drop your own
equivalents at the same filenames (or edit `paths().nyu_142_hplane_pattern`
/ `eplane_pattern` to point to your files).

## Run

```matlab
P = paths();
addpath(fullfile(P.repo_root, 'matlab', 'config'));
addpath(fullfile(P.repo_root, 'matlab', 'lib'));
addpath(genpath(fullfile(P.repo_root, 'matlab', 'lib_tcsl')));
addpath(fullfile(P.repo_root, 'matlab', 'processing', 'nyu_142'));
NYU142GHz_Method_Comparison;
```

Or, together with all 4 campaigns + figures: `run_all` from the
`matlab/` root.

## Outputs

```
share/matlab/processing/nyu_142/Results/
  ├── all_comparison_results.mat                       ← struct `results`
  ├── NYU142GHz_Method_Comparison_Results.xlsx         ← per-link method comparison
  └── NYU142GHz_Method_Comparison_Results.csv          ← CSV copy
```
