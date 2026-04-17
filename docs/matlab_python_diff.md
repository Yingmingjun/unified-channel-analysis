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
- Max |Δ|: **492.9**   Max rel Δ: **18.74** — ⚠️ 32 cell(s) exceed tolerance

| Row | Column (normalized) | Python | MATLAB | |Δ| | Δ/Py |
|-----|---------------------|--------|--------|-----|------|
| Band=Sub-THz (142/145.5); Dataset=Pooled; LocType=NLOS | dscfiwidthns | 26.29 | 519.2 | 492.9 | 18.74 |
| Band=Sub-THz (142/145.5); Dataset=Pooled; LocType=NLOS | dsmeanns | 33.34 | 309.1 | 275.7 | 8.271 |
| Band=Sub-THz (142/145.5); Dataset=USC only; LocType=NLOS | dsmeanns | 30.62 | 232.1 | 201.5 | 6.58 |
| Band=Sub-THz (142/145.5); Dataset=USC only; LocType=NLOS | dscfiwidthns | 26.2 | 103.7 | 77.5 | 2.958 |
| Band=6.75 GHz; Dataset=USC only; LocType=NLOS | dscfiwidthns | 51.19 | 185.3 | 134.1 | 2.619 |

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
