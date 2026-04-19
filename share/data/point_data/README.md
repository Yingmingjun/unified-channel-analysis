# Point-data xlsx inputs

These six spreadsheets are the **complete inputs** needed to reproduce
every data-driven figure (Fig. 3–8) and every data-driven table
(Table VI, Table VII) in the paper.

## Files

| File                 | Origin     | Method applied                      | Threshold sweep                              |
|----------------------|------------|-------------------------------------|----------------------------------------------|
| `N1_142_UMi.xlsx`    | NYU data   | NYU (SUM + 10/15/20 dB PAS)         | NYU                                          |
| `N1_7_UMi.xlsx`      | NYU data   | NYU                                 | NYU                                          |
| `U3_142_UMi.xlsx`    | USC data   | NYU (SUM) replicated at USC         | NYU thres / USC thres / USC orig. (U1)       |
| `U3_7_UMi.xlsx`      | USC data   | NYU replicated at USC               | ″                                            |
| `N3_142_UMi.xlsx`    | NYU data   | USC (perDelayMax) replicated at NYU | USC thres / NYU thres / NYU orig. (N1)       |
| `N3_7_UMi.xlsx`      | NYU data   | USC replicated at NYU               | ″                                            |

Each row is one TX–RX link and holds the per-link large-scale
parameters (PL, directional DS, omni DS, lobe/omni ASA, lobe/omni ASD,
and ZSA/ZSD where the antenna pattern supports it). Column headers are
self-describing; see Section III of the main paper for the precise
definitions and the threshold conventions.

## Where N1 and U1 live

Only **four** of the six files carry the *institution-consistent*
reference values — the U1 and N1 "golden" numbers that the paper
reports as "NYU method on NYU data" (N1) and "USC method on USC data"
(U1). Those values are **not** in standalone N1/U1 files; they are
embedded as shaded columns inside the cross-processing tables:

| Reference label | Where it lives                                                |
|-----------------|---------------------------------------------------------------|
| **N1 @ 142 GHz**  | `N1_142_UMi.xlsx` (standalone) *and* the `NYU orig. (N1)` column of `N3_142_UMi.xlsx` |
| **N1 @ 6.75 GHz** | `N1_7_UMi.xlsx` (standalone) *and* the `NYU orig. (N1)` column of `N3_7_UMi.xlsx`     |
| **U1 @ 145 GHz**  | `U3_142_UMi.xlsx`, `USC orig. (U1)` column (no standalone U1 file) |
| **U1 @ 6.75 GHz** | `U3_7_UMi.xlsx`,   `USC orig. (U1)` column (no standalone U1 file) |

This is why `matlab/config/paths.m` aliases `u1_*_xlsx = u3_*_xlsx`:
the pipeline reads U1 values from the same file that holds U3, just
from a different column.

## Units

| Quantity              | Unit                          |
|-----------------------|-------------------------------|
| TR separation         | metres                        |
| Path loss             | dB                            |
| Delay spread          | nanoseconds                   |
| Angular spread        | degrees (Fleury definition; 3GPP form available in `angular_spread_3gpp.m`) |

## How the code reads these

* **MATLAB:** [`matlab/lib/load_point_data.m`](../../matlab/lib/load_point_data.m)
  returns a single long-form MATLAB table with one row per
  (institution × band × TX–RX link); U1 and N1 values appear as
  dedicated columns so the figure drivers never have to track which
  xlsx they came from.
* **Python:** `channel_analysis.io.load_point_data()` returns the same
  tidy `pandas.DataFrame` layout.

See [`docs/input_formats.md`](../../docs/input_formats.md) §1 for the
column-by-column schema.

## Provenance

The xlsx files are produced by the raw-PDP processing pipelines at NYU
and USC from the original directional measurements. The raw PDPs are
too large (≈ 11 GB per campaign) and partly proprietary and are NOT
included in this shareable package. To regenerate these xlsx files
from your own raw data, see
[`matlab/processing/README.md`](../../matlab/processing/README.md).
