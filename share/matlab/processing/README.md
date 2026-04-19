# Raw-PDP processing — bring your own data

Each of the four subfolders here converts raw directional PDP
measurements into a point-data xlsx table of the same schema as the
ones bundled under `../../data/point_data/`. The published xlsx files
were produced by these exact scripts.

**The raw measurement data itself is NOT redistributable.** If you
want to process your own measurement campaign with the same
methodology (so your output is directly comparable to the paper's
tables), drop your data into `data/raw/<band>/` in the format below
and run `run_all('raw')`.

## Expected raw-data layout

```
<repo>/data/raw/
├── nyu_142/                    NYU sliding-correlator 142 GHz
│   └── 142GHz_Outdoor_T<TXID>-R<RXID>.mat
│       └─ Outdoor142 cell array [Ndir x 10] with PDP (col 1, dB) and
│          metadata (cols 2-10: TX_ID, RX_ID, TxEl, TxAz, RxEl, RxAz,
│          Env, …).  Time-domain dilation factor is 20 samples/ns.
├── nyu_7/                      NYU 6.75 GHz
│   └── (same .mat schema; TX/RX-specific antenna patterns live next to scripts)
├── usc_145/                    USC VNA-based 145.5 GHz microcellular
│   ├── LOS_*.mat  NLOS_*.mat
│   │   └─ H matrix, complex, size [Nf, 13, 3, 36, 3]
│   │      (Nf=1001 freq pts, TxAz, TxEl, RxAz, RxEl)
│   └── <LOS_files.txt>         optional listing with TR-separation distances
└── usc_7/                      USC FR3 midband 6.25-7.25 GHz
    └── LOS Study/*.mat  OLOS Study/*.mat
        └─ H matrix, complex, size varies (see script header)
```

Each subfolder's script (e.g. `nyu_142/NYU142GHz_Method_Comparison.m`)
documents its own data format in the top docstring. The TX-power
lookup CSV bundled with the NYU scripts
(`140GHz_Outdoor_BaseStation.csv`) comes from NYU's published
measurement metadata; if you process your own campaign, replace or
extend this CSV.

## What each script computes

| Script                                  | Input              | Output                                            |
|-----------------------------------------|--------------------|---------------------------------------------------|
| `nyu_142/NYU142GHz_Method_Comparison`   | directional PDPs   | `Results/all_comparison_results.mat` (PL, DS, ASA, ASD per TX-RX) |
| `nyu_7/NYU7GHz_Method_Comparison`       | directional PDPs   | ″                                                 |
| `usc_145/USC142GHz_Method_Comparison_Full` | H matrix (freq)  | `Results/USC145GHz_Full_Results.mat`              |
| `usc_7/USC7GHz_NewData_Processing`      | H matrix (freq)    | `Results/USC7GHz_Full_Results.mat`                |

Each script applies:
- The institution's noise-floor estimator and threshold margin
  (max per-direction noise + 12 dB for USC; max(peak-25 dB, nf+5 dB)
  per-direction for NYU).
- The omni-PDP synthesis (NYU SUM *and* USC perDelayMax, both kept for
  method comparison).
- 10× oversampled DS chain (USC convention; Naveed's
  `USCprocessing.m` lines 97–114 exactly).
- Dynamic delay gate at 6.75 GHz; fixed 966.67 ns (paper Eq. 9) at
  sub-THz.
- Angular-spread computation with Fleury's circular definition.

See Section III of the main paper for the full method descriptions.

## Running

```matlab
cd matlab
run_all('raw')     % raw PDPs  →  Results/*.mat  →  figures + tables
% or
run_all            % skip raw stage, use bundled xlsx directly
```

If `data/raw/` is empty and `Results/*.mat` hasn't been populated,
`run_all('raw')` will log `FAIL` for each pipeline and skip ahead to
the figure stage (which will still work off the bundled xlsx under
`data/point_data/`).

## Dependencies

- MATLAB R2022b+
- Statistics and Machine Learning Toolbox (bootstrap CI)
- Signal Processing Toolbox (Hann, Hamming windowing)
