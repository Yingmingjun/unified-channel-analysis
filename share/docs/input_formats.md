# Input data formats

The pipeline has two entry points:

1. **Point-data xlsx** (default): all downstream figures and tables
   read from six xlsx files under `data/point_data/`. Described in
   §1 below.
2. **Raw PDPs** (bring your own): if you want to process your own
   measurement campaign end-to-end, drop raw data under `data/raw/`
   and run `run_all('raw')`. Described in §2 below.

---

## 1. Point-data xlsx schema

Six files under `data/point_data/`, one per (dataset × frequency):

### 1.1  N1 / N1_7 (NYU data, NYU method)

Single-header table. Each row = one TX–RX link.

| Column              | Unit     | Notes                                       |
|---------------------|----------|---------------------------------------------|
| `Freq.`             | GHz      | "142 GHz" or "6.75 GHz" string              |
| `TX`                | string   | TX ID (e.g., "TX1")                         |
| `RX`                | string   | RX ID (e.g., "RX5")                         |
| `Loc Type`          | string   | "LOS", "NLOS", or "OLOS"                    |
| `TR Sep`            | m        | TX–RX separation distance                   |
| `PL`                | dB       | omni path loss (NYU SUM synthesis)          |
| `Mean Dir DS`       | ns       | mean per-direction RMS delay spread         |
| `Omni DS`           | ns       | RMS DS on the omni PDP                      |
| `Mean Lobe ASA`     | deg      | mean lobe ASA (Fleury)                      |
| `Omni ASA`          | deg      | total omni ASA (Fleury)                     |
| `Mean Lobe ASD`     | deg      |                                             |
| `Omni ASD`          | deg      |                                             |
| `Mean Lobe ZSA`     | deg      | (only when elevation data is available)     |
| `Omni ZSA`          | deg      |                                             |
| `Mean Lobe ZSD`     | deg      |                                             |
| `Omni ZSD`          | deg      |                                             |

Optional column `PL_X` may appear in N1_7 (NYU 6.75 GHz) only; it is
ignored by the downstream pipeline.

### 1.2  U3 / U3_7 (USC data, NYU method + USC thresholds)

Two-row header with three method variants per metric (columns 6 onwards):

```
| Freq. | TX | RX | Loc Type | TR Sep |
|       |    |    |          |        |  Omni PL [dB]                    |  Omni DS [ns]                    | … ASA … | … ASD … |
|       |    |    |          |        | NYU thres | USC thres | USC orig. | NYU thres | USC thres | USC orig. |         |         |
```

* NYU thres – USC data processed with NYU's delay-domain + SLT threshold
* USC thres – USC data processed with USC's own threshold (institution-consistent cell)
* USC orig. (U1) – published U1 value (USC processing on USC data); same column replicated for reference

### 1.3  N3 / N3_7 (NYU data, USC method + NYU thresholds)

Same two-row-header schema as U3, but column ordering flipped:

```
| Omni PL [dB]                    | Omni DS [ns]                    | …
| USC thres | NYU thres | NYU orig. | USC thres | NYU thres | NYU orig. | …
```

* USC thres – NYU data processed with USC's threshold
* NYU thres – NYU data processed with its own threshold (institution-consistent cell)
* NYU orig. (N1) – published N1 value (NYU processing on NYU data); reference

### 1.4  How the code reads these

**MATLAB:** `lib/load_point_data.m` returns a struct with fields
`N1_142, N1_7, U3_142, U3_7, N3_142, N3_7`. Each field is a table with
the columns above (sanitized MATLAB-variable-safe names).

**Python:** `channel_analysis.io.load_point_data()` returns a tidy
pandas `DataFrame`:

```python
columns = [
    'institution',     # 'NYU' or 'USC'
    'band',            # 'subTHz' or 'FR1C'
    'freq_ghz',        # 142 / 145 / 6.75 (float)
    'tx_rx_id',        # e.g. 'T1-R5'
    'd_m',             # TR separation, metres
    'loc_type',        # 'LOS' / 'NLOS'  (OLOS -> NLOS already applied)
    'loc_type_raw',    # original label before OLOS->NLOS collapse
    # Path loss (dB):
    'pl_nyu_sum',      # NYU SUM synthesis
    'pl_usc_pdm',      # USC perDelayMax synthesis
    # Delay spread (ns):
    'ds_nyu_method', 'ds_usc_method',
    # Angular spread (deg) — Fleury definition:
    'asa_nyu_10', 'asa_nyu_15', 'asa_nyu_20',   # NYU with 10/15/20 dB PAS SLT
    'asa_usc',                                  # USC (no spatial threshold)
    'asd_nyu_10', 'asd_nyu_15', 'asd_nyu_20',
    'asd_usc',
]
```

The column mapping happens in `io.py`; adapt it if your campaign uses
a different xlsx layout. MATLAB's `lib/load_point_data.m` exposes the
same column names (MATLAB-variable-safe, e.g. `tx_rx_id`, `d_m`,
`pl_nyu_sum`, …).

---

## 2. Raw PDP schema (for `run_all('raw')`)

Place your raw measurements under `data/raw/<band>/` in one of the
formats below. Each subfolder in `matlab/processing/` hard-codes the
expected shape; the scripts fail loudly if a file is missing or the
shape is wrong.

### 2.1  NYU 142 GHz — `data/raw/nyu_142/`

Filename: `142GHz_Outdoor_T<TXID>-R<RXID>.mat` (one file per link).

MAT contents: a single variable `Outdoor142` of type **cell array**,
size `[Ndir × 10]`, where `Ndir` is the number of directional pointings
for that link (typically ≥ 100). Each row is one (TxAz, TxEl, RxAz,
RxEl) pointing with the following columns:

| Col | Type     | Meaning                                                  |
|-----|----------|----------------------------------------------------------|
|  1  | double[N,1] | PDP in **dB**, length N (dilation = 20 samples/ns)    |
|  2  | int      | TX ID                                                    |
|  3  | int      | RX ID                                                    |
|  4  | int      | TX elevation index                                       |
|  5  | int      | TX elevation angle (deg)                                 |
|  6  | double   | TX azimuth (deg)                                         |
|  7  | int      | RX elevation index                                       |
|  8  | int      | RX elevation angle (deg)                                 |
|  9  | int      | RX azimuth (deg)                                         |
| 10  | char     | Environment label: 'LOS' / 'NLOS'                        |

A second file `140GHz_Outdoor_BaseStation.csv` (shipped under
`matlab/processing/nyu_142/`) provides per-link TX power in dBm —
extend with your own rows if you add new links. Columns consumed:
`TX_ID, RX_ID, TX_Power, TX_RX_Separation_Distance`.

### 2.2  NYU 6.75 GHz — `data/raw/nyu_7/`

Same `Outdoor142`-style cell layout, but the dilation factor and
antenna patterns differ (see script header). 6.75 GHz-specific
antenna patterns (`7_phi0_pd.mat`, `7_phi90_pd.mat`) are shipped in
`matlab/processing/nyu_7/` and loaded by the script automatically.

### 2.3  USC 145.5 GHz — `data/raw/usc_145/`

Filename: one `.mat` per link, e.g., `LOS_R01_d65m.mat`,
`NLOS_R02_d73m.mat`.

MAT contents: one variable `H` (complex, size `[Nf, N_aztx, N_eltx,
N_azrx, N_elrx]` = `[1001, 13, 3, 36, 3]` — 1 GHz BW, 13 TX azimuths,
3 TX elevations, 36 RX azimuths, 3 RX elevations).

Companion listing `LOS_files.txt` / `NLOS_files.txt` (or equivalent
cell in the script) gives per-file TR-separation distances in metres.
The script reads `H`, applies Hann windowing, IFFTs to PDP, and
performs thresholding + omni synthesis. See `USC_Midband_Pattern.mat`
for antenna pattern if not bundled.

### 2.4  USC 6.75 GHz — `data/raw/usc_7/`

Filename: one `.mat` per link, under `LOS Study/` and `OLOS Study/`
subdirs. H matrix is 4D `[Nf, N_aztx, N_azrx, N_elrx]` =
`[1001, 13, 36, 5]` after band extraction to 6.25–7.25 GHz. Raw file
may span a wider band (e.g., 6–18 GHz for LOS, 6–14 GHz for OLOS);
the script slices the 1 GHz band of interest automatically.

---

## 3. Extending the pipeline to a new dataset

If you measure in a different band or with a different array geometry:

1. Match one of the raw schemas above (most likely §2.3 or §2.4).
2. Copy the closest `processing/<band>/` script and adjust:
   - `params.BW`, `params.Nf`, `params.Fs`
   - `params.N_aztx`, `params.N_eltx`, `params.N_azrx`, `params.N_elrx`
   - `params.HPBW`, `params.Az_step`, `params.El_step`
   - `params.correction_factor_dB` (elevation-sum compensation)
   - `params.delayGate_ns` (or `Inf` for no gate)
3. Keep the noise convention: **max noise floor over all directions +
   12 dB** (or the NYU per-direction alternative, also implemented).
4. Keep the oversampled DS chain (`n_oversamp = 10`) for parity with
   Naveed's `USCprocessing.m`.

The script will emit a Results `.mat` matching the existing schema;
`table_dumps.m` will then pick it up and produce a point-data xlsx in
the format of §1.
