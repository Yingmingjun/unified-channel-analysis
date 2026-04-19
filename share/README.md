# Unified NYU/USC Channel-Analysis Pipeline

Reproducible analysis code for the journal paper

> D. Shakya, M. Ying, N. A. Abbasi, J. Gomez-Ponce, X. Liu, X. Wang, D. Abraham,
> T. S. Rappaport, A. F. Molisch,
> **"Pooling of Multi-Institutional Radio Propagation Empirical Data with
> Cross-Processing Validation for 6G AI/ML Channel Modeling,"**
> *submitted to IEEE Transactions on Wireless Communications*, 2026.

## What this package reproduces

Starting from **six bundled point-data xlsx files** (no raw measurements
required), this package regenerates every data-driven result in the paper:

| Paper target                    | Script (Python / MATLAB)                                         |
|---------------------------------|------------------------------------------------------------------|
| Fig. 3 — BA of PL, DS (2 bands) | `figures/fig03_bland_altman_pl_ds.{py,m}`                        |
| Fig. 4 — BA of ASA, ASD         | `figures/fig04_bland_altman_as.{py,m}`                           |
| Fig. 5 — CI PL scatter + fit    | `figures/fig05_ci_pl_scatter.{py,m}`  /  `paper_figures/PL_CI_Merged.m` |
| Fig. 6 — Omni RMS DS CDF        | `figures/fig06_ds_cdf.{py,m}`         /  `paper_figures/DS_CDF_Merged.m` |
| Fig. 7 — Omni ASA CDF           | `figures/fig07_asa_cdf.{py,m}`        /  `paper_figures/AS_CDF_Merged.m` |
| Fig. 8 — Omni ASD CDF           | `figures/fig08_asd_cdf.{py,m}`        /  `paper_figures/AS_CDF_Merged.m` |
| Table VI — cross-threshold RMSE | `figures/table06_rmse.{py,m}`                                    |
| Table VII — pooled lognormal    | `figures/table07_pooled_stats.{py,m}`                            |
| Paper-parity audit              | `figures/paper_parity.{py,m}` — TIGHT / CLOSE / MISS vs published |

Two independent implementations (Python + MATLAB) are provided. They
read the same xlsx files and produce numerically identical results to
the precision reported in the paper.

## Layout

```
share/
├── README.md               ← you are here
├── LICENSE                 ← CC-BY-NC-4.0
│
├── docs/                   ← extended documentation (read before contributing)
│   ├── input_formats.md       schema of every input file (xlsx + raw PDP)
│   └── pipeline.md            end-to-end flow + conventions + output filenames
│
├── data/
│   └── point_data/         ← six shareable xlsx inputs  (~4.5 MB)
│       ├── N1_142_UMi.xlsx   NYU data / NYU method / sub-THz
│       ├── N1_7_UMi.xlsx     NYU data / NYU method / 6.75 GHz
│       ├── U3_142_UMi.xlsx   USC data / NYU method + USC threshold sweep
│       ├── U3_7_UMi.xlsx     ″ at 6.75 GHz
│       ├── N3_142_UMi.xlsx   NYU data / USC method + NYU threshold sweep
│       └── N3_7_UMi.xlsx     ″ at 6.75 GHz
│
├── python/                 ← verified primary implementation
│   ├── pyproject.toml         dependencies, CLI entry (`channel-run-all`)
│   └── src/channel_analysis/  package source
│
└── matlab/                 ← parallel port (byte-for-byte figure parity)
    ├── run_all.m              end-to-end driver ("default" | "raw")
    ├── config/                paths.m + plot_style.m
    ├── lib/                   math primitives (bootstrap, CI fit, DKW, BA, …)
    ├── lib_tcsl/              vendored NYU angular-spread helpers; see its README
    ├── figures/               fig03–fig08 + table06 + table07 + parity drivers
    ├── paper_figures/         Merged-style CDFs and BA figures (canonical names)
    ├── processing/            raw-PDP → xlsx (used only by `run_all('raw')`)
    ├── patterns/              antenna-pattern DAT files (used by processing/)
    └── tools/                 supplement generator, figure-staging helper
```

## Quick start — Python (recommended)

```bash
cd python
pip install -e .

# (a) the entry point declared in pyproject.toml …
channel-run-all

# (b) … or equivalently as a module
python -m channel_analysis.run_all
```

Outputs land under `figures/python/` in the repo root. To regenerate
one specific figure or table:

```bash
python -m channel_analysis.figures.fig06_ds_cdf       # e.g. just Fig. 6
python -m channel_analysis.figures.table06_rmse       # just Table VI
python -m channel_analysis.figures.paper_parity       # parity audit only
```

## Quick start — MATLAB

Requires R2022b+ with the Statistics and Machine Learning Toolbox.
From MATLAB:

```matlab
cd matlab
run_all                 % default: xlsx inputs → figures + tables (≈ 1–2 min)
run_all('raw')          % also regenerate xlsx from raw PDPs (see §Raw-data mode)
```

Outputs land under `figures/matlab/` in the repo root.

## Paper-tree sync (opt-in)

Set any of these environment variables **before** launching Python or
MATLAB if you also want the pipeline to overwrite figures and the
supplement inside a local paper-source tex tree:

| Variable           | Default (when unset) | Purpose                            |
|--------------------|----------------------|------------------------------------|
| `PAPER_TREE_DIR`   | _not set_            | root of the paper tex project      |
| `PAPER_FIG_DIR`    | `$PAPER_TREE_DIR/figures`    | overrides the figure sync target |
| `PAPER_TEX_PATH`   | `$PAPER_TREE_DIR/main_final.tex` | for in-place tex updates    |
| `PAPER_SUPP_PATH`  | `$PAPER_TREE_DIR/supplement.tex` | for the supplement writer   |

When all four are unset the pipeline never touches any external
directory — it stays entirely under `<repo>/figures/{python,matlab}/`.

## Raw-data mode (bring your own measurements)

The four raw-processing scripts under `matlab/processing/` each
consume directional PDPs and emit a point-data xlsx table matching
the schema of the six bundled files. The raw measurements (≈ 11 GB
per campaign) are not redistributable, but **the processing pipeline
is fully open**:

```matlab
cd matlab
run_all('raw')   % expects raw data under <repo>/data/raw/{nyu_142,nyu_7,usc_145,usc_7}/
```

See [`docs/input_formats.md`](docs/input_formats.md) §2 for the
raw-data schema (file naming, H-matrix shapes, antenna-pattern
conventions) and
[`matlab/processing/README.md`](matlab/processing/README.md) for the
per-script expected inputs and outputs.

If you don't have raw data, the bundled xlsx files are sufficient to
reproduce every *published* figure and data-driven table.

## Further reading

| Document                                                     | Contents                                           |
|--------------------------------------------------------------|----------------------------------------------------|
| [`docs/pipeline.md`](docs/pipeline.md)                       | End-to-end flow diagram; conventions (PL, DS, AS fits, DKW, bootstrap); cross-processing terminology (N1/U1/N3/U3/N2/U2). |
| [`docs/input_formats.md`](docs/input_formats.md)             | Column-level xlsx schema; raw-PDP schema for each of the four campaigns; extension recipe for new bands. |
| [`matlab/README.md`](matlab/README.md)                       | MATLAB-specific entry points, per-figure script table, dependency list. |
| [`python/README.md`](python/README.md)                       | Python-specific entry points, package internals, module dependency graph. |
| [`matlab/processing/README.md`](matlab/processing/README.md) | Raw-processing expected layout, per-script computation summary. |
| [`data/point_data/README.md`](data/point_data/README.md)     | Per-file method and threshold conventions. |

## Citation

```bibtex
@article{Shakya2026twc,
  title   = {Pooling of Multi-Institutional Radio Propagation Empirical Data
             with Cross-Processing Validation for 6G AI/ML Channel Modeling},
  author  = {Shakya, Dipankar and Ying, Mingjun and Abbasi, Naveed A. and
             Gomez-Ponce, Jorge and Liu, Xingchen and Wang, Xinquan and
             Abraham, Daniel and Rappaport, Theodore S. and Molisch, Andreas F.},
  journal = {IEEE Transactions on Wireless Communications},
  year    = {2026},
  note    = {Submitted}
}
```

## License

CC-BY-NC-4.0 — see [`LICENSE`](LICENSE). Non-commercial reuse with
attribution.
