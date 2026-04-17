# Bundled point-data tables

These six xlsx files are the multi-institution interchange format described in the paper (Section II). Both the Python and MATLAB pipelines read them directly; nothing else is required to regenerate every data-driven figure and table in the paper.

| File | Contents |
|------|----------|
| `N1_142_UMi.xlsx`     | NYU original point-data, 142 GHz UMi (27 locations, 16 LOS / 11 NLOS). `FinalTable` sheet, single-row header. |
| `N1_7_UMi.xlsx`       | NYU original point-data, 6.75 GHz UMi (20 locations, 7 LOS / 13 NLOS).  |
| `N3_142_UMi.xlsx`     | NYU data cross-processed by the USC pipeline, 142 GHz. Two-row header (`Omni PL / DS / ASA / ASD` metrics × `NYU thres / USC thres / NYU orig. (N1)` sub-columns). |
| `N3_7_UMi.xlsx`       | Same structure at 6.75 GHz. |
| `U3_142_UMi.xlsx`     | USC data cross-processed by the NYU pipeline, 145.5 GHz. Two-row header (`Omni PL / DS / ASA / ASD` × `NYU thres / USC thres / USC orig. (U1)`). |
| `U3_7_UMi.xlsx`       | Same structure at 6.75 GHz (6 LOS + 11 OLOS; OLOS re-labeled to NLOS for pooled modeling). |

Authoritative `N1` values are pulled from the `NYU orig. (N1)` column of the N3 xlsx (and similarly for U1); see `docs/issues_log.md` for why those columns are preferred over the standalone N1/U1 drops that were at earlier processing stages.

## Schema — two-row header tables (N3, U3)

Rows in the xlsx:

```
Row 1  :  free-form title
Row 2  :  "Freq."  "TX"  "RX"  "Loc Type"  "TR Sep"  "Omni PL" (merged 3)  "Omni DS" (merged 3)  "Omni ASA" (merged 3)  "Omni ASD" (merged 3)
Row 3  :  (blank×5)                                  "NYU thres"  "USC thres"  "NYU orig. (N1)"  "NYU thres"  "USC thres"  "NYU orig. (N1)"  ...
Row 4+ :  data rows
```

In `U3_*.xlsx` the third sub-column within each metric is `USC orig. (U1)` instead of `NYU orig. (N1)`.

## Schema — single-row header table (N1)

One row per location. Columns:
`Freq., TX, RX, Loc Type, TR Sep, PL, Mean Dir DS, Omni DS, Mean Lobe ASA, Omni ASA, Mean Lobe ASD, Omni ASD, Mean Lobe ZSA, Omni ZSA, Mean Lobe ZSD, Omni ZSD.`

(The 6.75 GHz file has an extra `PL_X` column between `PL` and `Mean Dir DS` that the Python loader drops.)

## Point-data schema (Section II of the paper)

Each row corresponds to a single TX-RX pair:

| Column        | Type  | Units | Description                                   |
|---------------|-------|-------|-----------------------------------------------|
| Freq.         | str   | —     | "142 GHz", "145 GHz", "6.75 GHz"              |
| TX, RX        | str   | —     | Transmitter / receiver identifier             |
| Loc Type      | str   | —     | "LOS", "NLOS", "OLOS"                         |
| TR Sep        | float | m     | 2-D TX-RX separation                          |
| Omni PL       | float | dB    | Omnidirectional path loss                     |
| Omni DS       | float | ns    | Omnidirectional RMS delay spread              |
| Omni ASA/ASD  | float | °     | Omni azimuth spread of arrival / departure    |
| (other)       | ...   | ...   | Mean-lobe AS and ZSA/ZSD variants             |

## Provenance

These xlsx files are the same ones used by the authors to generate the paper's Tables 4, 7, 8, 9, 10, 11. They are copied verbatim — no post-processing has been applied.

## Not included in the bundle

- Raw directional PDP recordings (tens of GB). These are NOT required to reproduce the paper's figures; they are the upstream input to the MATLAB pipelines that generated these xlsx tables.
- `NYU_Data/`, `USC_Data/` folders — same rationale.

If you need the raw measurement data, contact the authors (see `CITATION.cff`).
