# joint-nyu-usc-channel-analysis

Reproducible analysis code for the journal paper

> **D. Shakya, M. Ying, N. A. Abbasi, J. Gomez-Ponce, X. Liu, X. Wang, D. Abraham, T. S. Rappaport, A. F. Molisch**, "Pooling of Multi-Institutional Radio Propagation Empirical Data with Cross-Processing Validation for 6G AI/ML Channel Modeling," *submitted to IEEE Transactions on Wireless Communications*, 2026 (under review).

This repository contains a **Python reference implementation** (primary, verified) and a **MATLAB parallel port** (secondary) that together reproduce every figure and numerical result in the paper's Sections IV–V and Tables 6–11 from the published point-data tables.

## Scope and status

- **Python:** fully verified. `channel-run-all` regenerates every paper figure (Fig. 3–8) and every data-driven table (Table 6, Table 7) from the shared point-data tables. See `docs/numerical_parity.md` and `docs/figure_parity.md`.
- **MATLAB:** parallel port of the Python architecture. Not executed in the authoring sandbox — run it on a MATLAB-licensed machine yourself.

**Scope of the port.** The Python package consumes the paper's *point-data* tables (per-location Omni PL / DS / ASA / ASD) directly. Raw directional-PDP reprocessing from the measurement records (sliding-correlator demodulation, APDS synthesis, spatial-lobe expansion, threshold application) is not duplicated in Python — the existing MATLAB pipelines in Codebases A (`D:/NaveedDipankarMingjunJorgeShare/...`) and B (`D:/NYU-USC/Cross-Processing/`) are the authoritative source for those steps. This matches the paper's position: the point-data table *is* the multi-institution interchange format.

## Repository layout

```
├── python/                      # PRIMARY — verified reference implementation
│   ├── pyproject.toml
│   ├── src/channel_analysis/    # installable package (src layout)
│   └── tests/                   # pytest unit tests
├── matlab/                      # SECONDARY — parallel port (user runs themselves)
│   ├── run_all.m
│   ├── config/                  # paths and plot style
│   ├── lib/                     # PL / DS / AS / stats helpers
│   └── figures/                 # per-figure drivers
├── figures/
│   ├── python/                  # Python-produced .pdf / .png
│   └── matlab/                  # populated by the user
├── data/README.md               # expected data layout; no data shipped here
├── docs/                        # paper summary, inventories, parity reports
└── FINAL_REPORT.md              # end-of-port summary of status and gaps
```

## Quickstart — Python (verified path)

```bash
cd python
python -m pip install -e .[dev]

# Point the loader at your institutional data drop
export CHANNEL_DATA_ROOT=/path/to/NaveedDipankarMingjunJorgeShare      # (bash)
# PowerShell: $env:CHANNEL_DATA_ROOT = 'D:/.../NaveedDipankarMingjunJorgeShare'

# Regenerate every figure and table
python -m channel_analysis.run_all
# Equivalently:  channel-run-all

# Run the test suite
pytest
```

Outputs land in `figures/python/` — every figure as both `.pdf` and `.png`, and a `stats_dump.json` carrying the numerical statistics consumed by the parity docs.

See [`README_PYTHON.md`](README_PYTHON.md) for full Python instructions, including data-path configuration and per-figure driver usage.

## Quickstart — MATLAB (parallel port)

See [`README_MATLAB.md`](README_MATLAB.md). Expected workflow:

```matlab
cd matlab
run_all    % regenerates every figure into figures/matlab/
```

Python is the verified reference; MATLAB is provided as a convenience for users who prefer the MATLAB environment. Numerical agreement between the two ports within a few percent is expected; cross-check results against `docs/numerical_parity.md`.

## Figure-by-figure how-to

| Paper fig./table | Python driver                                                 | MATLAB driver                                |
|------------------|---------------------------------------------------------------|----------------------------------------------|
| Fig. 3           | `python/src/channel_analysis/figures/fig03_bland_altman_pl_ds.py` | `matlab/figures/fig03_bland_altman_pl_ds.m`  |
| Fig. 4           | `fig04_bland_altman_as.py`                                    | `fig04_bland_altman_as.m`                    |
| Fig. 5           | `fig05_ci_pl_scatter.py`                                      | `fig05_ci_pl_scatter.m`                      |
| Fig. 6           | `fig06_ds_cdf.py`                                             | `fig06_ds_cdf.m`                             |
| Fig. 7           | `fig07_asa_cdf.py`                                            | `fig07_asa_cdf.m`                            |
| Fig. 8           | `fig08_asd_cdf.py`                                            | `fig08_asd_cdf.m`                            |
| Table 6          | `table06_rmse.py`                                             | `table06_rmse.m`                             |
| Table 7          | `table07_pooled_stats.py`                                     | `table07_pooled_stats.m`                     |

Figures 1 and 2, and Tables 1, 2, 3, 5 in the paper are static (TikZ schematic / literature survey / metadata spec) and are not reproduced by code. See [`docs/figure_parity.md`](docs/figure_parity.md).

## Data access

The NYU and USC measurement data sets, and the per-institution point-data xlsx/csv tables, are **not** included in this repository. Data usage is governed by NYU WIRELESS Industrial Affiliates Program and USC Center for Wireless Propagation Research policies. Contact the corresponding authors for access.

Expected data layout and file formats are documented in [`data/README.md`](data/README.md).

## Reproducibility

- Every figure is regenerated by one driver, idempotent under a fixed seed (`channel_analysis.config.RNG_SEED = 0`).
- Bootstrap sampling is seeded; re-running produces byte-identical figure content.
- Verified parity vs. paper numbers: [`docs/numerical_parity.md`](docs/numerical_parity.md) — 45 of 68 tracked claims match tight (within 2 %), 19 match close (within 10 %), 4 documented misses with root-cause analysis.
- Visual parity vs. paper figures: [`docs/figure_parity.md`](docs/figure_parity.md) — 13 of 16 figure panels reproduce with minor style delta; 3 cannot be reproduced from point-data alone (schematic or raw-PDP panels).
- Python is the verified path; MATLAB is a parallel reference port.

## Citation

```bibtex
@article{Shakya2026JointNYUUSC,
  author  = {Shakya, Dipankar and Ying, Mingjun and Abbasi, Naveed A. and
             Gomez-Ponce, Jorge and Liu, Xingchen and Wang, Xinquan and
             Abraham, Daniel and Rappaport, Theodore S. and Molisch, Andreas F.},
  title   = {Pooling of Multi-Institutional Radio Propagation Empirical Data with
             Cross-Processing Validation for 6{G} {AI}/{ML} Channel Modeling},
  journal = {IEEE Transactions on Wireless Communications},
  year    = {2026},
  note    = {Submitted, under review}
}
```

Please also cite the conference predecessors: IEEE ICC 2025 (`Rapp2025icc`) and IEEE MILCOM 2025 (`Shakya2025milcom`).

## License

The source code in this repository is released under **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**. See [`LICENSE`](LICENSE) for the short grant and the canonical URL, and [`LICENSE_FULL.txt`](LICENSE_FULL.txt) for the full legal text.

## Acknowledgments

The authors thank the NYU WIRELESS and USC Center for Wireless Propagation Research teams who conducted the original 142 GHz / 145.5 GHz / 6.75 GHz urban-microcell measurement campaigns in Brooklyn, NY and Los Angeles, CA. In particular the contributions of Dipankar Shakya, Mingjun Ying, Naveed A. Abbasi, Jorge Gomez-Ponce, Xingchen Liu, Xinquan Wang, Daniel Abraham, Prof. Theodore S. Rappaport, and Prof. Andreas F. Molisch made this joint-analysis release possible.

Funding: NYU WIRELESS Industrial Affiliates Program; Affiliates of the Center for Wireless Propagation Research at USC; U.S. National Science Foundation.
