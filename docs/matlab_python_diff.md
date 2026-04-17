# MATLAB ↔ Python port — cell-level diff report

Tolerance: |Δ| < 0.05 OR relative Δ < 2 %.

## `table04_N1_142.csv`

- Python rows: 27, MATLAB rows: 30
- Common numeric columns (after name normalization): 12
- ⚠️ Row count mismatch (27 vs 30) — skipping cell diff.

## `table06_rmse.csv`

- Python rows: 8, MATLAB rows: 8
- Common numeric columns (after name normalization): 4
- Max |Δ|: **0.0004503**   Max rel Δ: **0.01942** — ✅ all cells within tolerance

## `table07_pooled_stats.csv`

- Python rows: 12, MATLAB rows: 12
- Common numeric columns (after name normalization): 10
- Max |Δ|: **4.626**   Max rel Δ: **0.08811** — ⚠️ 17 cell(s) exceed tolerance

| Row | Column (normalized) | Python | MATLAB | |Δ| | Δ/Py |
|-----|---------------------|--------|--------|-----|------|
| Band=Sub-THz (142/145.5); Dataset=NYU only; LocType=LOS | asacfiwidthd | 8.158 | 8.876 | 0.7187 | 0.08811 |
| Band=Sub-THz (142/145.5); Dataset=NYU only; LocType=NLOS | dscfiwidthns | 34.72 | 36.58 | 1.862 | 0.05364 |
| Band=Sub-THz (142/145.5); Dataset=Pooled; LocType=LOS | asdcfiwidthd | 3.932 | 4.104 | 0.1725 | 0.04388 |
| Band=Sub-THz (142/145.5); Dataset=USC only; LocType=LOS | asdcfiwidthd | 1.69 | 1.761 | 0.07129 | 0.04218 |
| Band=6.75 GHz; Dataset=Pooled; LocType=LOS | dscfiwidthns | 76.37 | 79.58 | 3.213 | 0.04207 |

## `table08_U3_145.csv`

- Python rows: 26, MATLAB rows: 26
- Common numeric columns (after name normalization): 13
- Max |Δ|: **0.0004986**   Max rel Δ: **0.0001871** — ✅ all cells within tolerance

## `table09_U3_7.csv`

- Python rows: 17, MATLAB rows: 17
- Common numeric columns (after name normalization): 13
- Max |Δ|: **0.0004999**   Max rel Δ: **0.0006426** — ✅ all cells within tolerance

## `table10_N3_142.csv`

- Python rows: 28, MATLAB rows: 28
- Common numeric columns (after name normalization): 12
- Max |Δ|: **0.0004998**   Max rel Δ: **0.0005486** — ✅ all cells within tolerance

## `table11_N3_7.csv`

- Python rows: 20, MATLAB rows: 20
- Common numeric columns (after name normalization): 12
- Max |Δ|: **0.0004994**   Max rel Δ: **0.000512** — ✅ all cells within tolerance
