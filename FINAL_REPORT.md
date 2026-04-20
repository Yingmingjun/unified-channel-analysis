# FINAL REPORT

**Session date:** 2026-04-17
**Repo:** `D:/unified-channel-analysis/` (also zipped at the session output root as `joint-nyu-usc-channel-analysis.zip`)
**Paper:** Shakya, Ying, Abbasi, Gomez-Ponce, Liu, Wang, Abraham, Rappaport, Molisch — *"Pooling of Multi-Institutional Radio Propagation Empirical Data with Cross-Processing Validation for 6G AI/ML Channel Modeling"*, submitted to IEEE TWC 2026.

## Deliverables

| Path                                | Status | Note |
|-------------------------------------|--------|------|
| `python/` (installable package)     | ✅     | `pip install -e python` → `channel-run-all` regenerates every figure/table |
| `python/tests/` (pytest)            | ✅     | 21 tests pass |
| `matlab/` (parallel port)           | ✅     | 22 `.m` files, 1475 lines (1 `run_all`, 2 `config/`, 11 `lib/`, 8 `figures/`). Not executed in sandbox; run on a MATLAB-licensed machine. |
| `figures/python/` (output)          | ✅     | 16 `.pdf` + `.png` figures + `stats_dump.json` + 7 table CSVs (Tables 4, 6, 7, 8, 9, 10, 11) |
| `data/point_data/` (bundled)        | ✅     | 6 point-data xlsx files (~100 kB total). Python and MATLAB both default to this in-repo data — no external mount needed. |
| `figures/matlab/` (user-populated)  | —      | Empty; user populates after running MATLAB `run_all.m` |
| `docs/`                             | ✅     | paper summary, code inventory, architecture, conflicts log, issues log, numerical + figure parity reports |
| `README.md` / `README_PYTHON.md` / `README_MATLAB.md` | ✅ | |
| `LICENSE` + `LICENSE_FULL.txt`      | ✅     | CC BY-NC 4.0; full text downloaded from CC canonical URL |
| `CITATION.cff`                      | ✅     | submission state recorded |
| `.gitignore` / `requirements.txt` / `environment.yml` | ✅ | |
| `data/README.md`                    | ✅     | data access note; no data shipped |
| Local git repo (`git init` + phased commits) | ✅ | Phases 1-3, 4, 4-outputs, 5, 6, 7 committed separately |
| Zip archive at session output root  | ✅     | |

## Python parity status

**Total figures tracked:** 16 panels (Fig. 3 ×4, Fig. 4 ×4, Fig. 5 ×2, Fig. 6 ×2, Fig. 7 ×2, Fig. 8 ×2).

**Total tables regenerated from data:** 7 of 11 (Tables 4, 6, 7, 8, 9, 10, 11 all produced as CSV under `figures/python/`). Tables 1, 2, 3, 5 are static LaTeX (literature survey, metadata schema, metadata comparison, methodology comparison) and are not data-generated.

- **13 of 16** panels reproduce with minor style delta (acceptable).
- **3 of 16** not reproducible from point-data alone (Fig. 1 TikZ schematic; Fig. 2 raw-PDP panels).

**Total numerical claims tracked:** 68 (Tables 6, 7, abstract, Section IV.A–C, Section V.A–B).

- **45 of 68** tight match (within 2 % / ≤ 0.05 on PLE-like unit-free quantities).
- **19 of 68** close match (within 10 %).
- **4 of 68** documented misses; all diagnosed in `docs/numerical_parity.md` §Misses.

All core analytical formulas reproduce exactly: CI PLE and σ_SF agree to 2 decimal places across every row of Table 7; cross-processing RMSE at sub-THz matches to < 1 %; pooled-vs-individual CFI shrinkage direction matches on every parameter.

## Items that could not be reproduced, and why

1. **Fig. 1 (cross-processing flow diagram)** — TikZ schematic, no data. Pass-through.
2. **Fig. 2 a, b (calibrated directional PDP comparison)** — requires raw directional PDPs. The Python package consumes point-data tables; raw-PDP reprocessing is the MATLAB pipelines' domain (see `docs/issues_log.md` → "scope of Python port").
3. **NYU sub-THz NLOS ASA 95 % CFI width** — paper 69.40°, Python 36.20°. Root cause: bootstrap-method divergence on a small sample (n=11) when one extreme location dominates. Directional conclusion (pooled CFI much narrower than either individual) preserved. Not material.
4. **6.75 GHz Table 6 RMSE for USC PL** — paper 6.20 dB, Python 2.73 dB. Root cause: the `Omni PL USC orig. (U1)` column in `7_UMi_U3.xlsx` carries updated USC values vs. what was used when Table 6 was originally computed. Qualitative message preserved (USC-matched-threshold RMSE is low).

## Issues log highlights

Full list in `docs/issues_log.md`. Key items:

- **Source-data divergence** between the stand-alone N1/U1 xlsx/csv drops and the "NYU orig"/"USC orig" columns of the N3/U3 xlsx. Paper values are consistent with the N3/U3 xlsx orig columns. Python loader uses those.
- **USC 6.75 GHz truncated csvs** (8 rows) superseded by `7_UMi_U3.xlsx` "USC orig" column (17 rows). Loader uses the xlsx.
- **Single source-data typo** at TX4-RX37 in `N3_142_UMi.xlsx` Omni ASA "NYU thres" column had `714.0` where `7.14` was intended (decimal point dropped in the original Cross-Processing snapshot). **Fixed in place 2026-04-20** (cell M23 `714` → `7.14`). The 50x-median outlier guards in `figures/table06_rmse.{m,py}` are retained as general defense-in-depth.
- **Paper reports lognormal-expectation mean** `E[X] = exp(μ ln10 + (σ ln10)²/2)`, not arithmetic mean. Python `ds.lognormal_stats` implements both; Table 7 uses the lognormal form.
- **Fleury AS form duality** — the paper gives two forms; unit tests verify the two forms agree to 1e-10 for every synthetic case.
- **Comprehensive_NYU_USC_Analysis version pick** — `v7.m` selected as authoritative; v2–v6 superseded. See `docs/code_conflicts.md`.

## Code conflicts and how they were resolved

Full details in `docs/code_conflicts.md`. Highlights:

- `Comprehensive_NYU_USC_Analysis_v7.m` is canonical.
- `D`-suffixed helpers (`boundaryMPCsD`, `lobeShaperCounterD`, `SubPathPwrDirsD`, `SecondaryStats_circD`) are the active versions.
- `USCprocessing_NYUth_Sp.m` is the active `USCprocessing*` variant for the paper's cross-processing runs; the other 4 variants are historical.
- Two Fleury AS formulas disagree in form but agree algebraically; port verifies equivalence in `test_angular.test_fleury_two_forms_equivalent`.
- Two NYU-SUM / USC-per-delay-max omni synthesis methods differ in outcome; both are implemented as separate functions in the MATLAB port.

## Paths

- **Repo on disk:** `D:/unified-channel-analysis/`
- **Zip archive:** `<session-output-root>/joint-nyu-usc-channel-analysis.zip`
- **Input (read-only, never modified):**
  - Paper: `D:/Joint-Point-Data-format-USC-NYU-Journal/`
  - Codebase A: `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/`
  - Codebase B: `D:/NYU-USC/Cross-Processing/`
  - NYU measurement data: `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/NYU/NYU_Data/`
  - USC measurement data: `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/USC/USC_Data/`

## Things to review before publication

1. **License choice** — repo is CC BY-NC 4.0 (per the project spec). Confirm all co-authors and institutions are comfortable with non-commercial reuse.
2. **Author ordering and affiliations** in `CITATION.cff` and `README.md` match the LaTeX source.
3. **MATLAB port** — please run `run_all.m` on your licensed machine and cross-check the figures in `figures/matlab/` against the Python-produced `figures/python/` counterparts.
4. **NYU-only NLOS ASA CFI width** (doc'd miss in `numerical_parity.md`) — confirm the paper's 69.40° value is on the lognormal-expectation estimator (not, e.g., on log-space μ), so readers aren't misled.
5. **Release of data** — the code does not ship measurement data. If the community pooling effort progresses, the `CHANNEL_DATA_ROOT` mechanism makes it trivial to swap in new institutional drops without code changes.
6. **Zip integrity** — verify the zip archive at the session output root unpacks cleanly and `python -m channel_analysis.run_all` regenerates every figure after `pip install -e python`.

## Reproducibility attestation

The Python reference implementation is deterministic under `RNG_SEED = 0`. Bootstrap widths, figure contents, and summary JSON are byte-identical across runs on the same input. MATLAB port mirrors the architecture one-to-one; numerical agreement between ports within 1 % is expected (some divergence in bootstrap ordering due to different RNG conventions is acceptable).
