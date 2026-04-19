# Point-data xlsx inputs

These six spreadsheets are the **complete inputs** needed to reproduce
every data-driven figure (Fig. 3–8) and every data-driven table
(Table VI, Table VII) in the paper.

| File                 | Origin     | Method applied                     | Threshold applied |
|----------------------|------------|------------------------------------|-------------------|
| `N1_142_UMi.xlsx`    | NYU data   | NYU (SUM + 10/15/20 dB PAS)        | NYU               |
| `N1_7_UMi.xlsx`      | NYU data   | NYU                                | NYU               |
| `U3_142_UMi.xlsx`    | USC data   | NYU (SUM) replicated at USC        | NYU thres / USC thres / USC orig. (U1) |
| `U3_7_UMi.xlsx`      | USC data   | NYU replicated at USC              | ″                 |
| `N3_142_UMi.xlsx`    | NYU data   | USC (perDelayMax) replicated at NYU | USC thres / NYU thres / NYU orig. (N1) |
| `N3_7_UMi.xlsx`      | NYU data   | USC replicated at NYU              | ″                 |

Each row is one TX–RX link and holds the per-link large-scale
parameters (PL, directional DS, omni DS, lobe/omni ASA, lobe/omni ASD,
and ZSA/ZSD where the antenna pattern supports it). Column headers are
self-describing; see Section III of the main paper for the precise
definitions and the threshold conventions.

## Units

| Quantity              | Unit    |
|-----------------------|---------|
| TR separation distance | metres  |
| Path loss             | dB      |
| Delay spread          | nanoseconds |
| Angular spread        | degrees (Fleury definition) |

## Provenance

The xlsx files are produced by the raw-PDP processing pipelines at NYU
and USC from the original directional measurements. The raw PDPs are
too large (≈ 11 GB) and partly proprietary and are NOT included in this
shareable package. To regenerate the xlsx files from raw, contact the
corresponding authors.
