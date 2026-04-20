# Contributing

Thanks for taking the time to contribute. This reproduction package is
primarily a research artifact, so the scope is deliberately narrow:

**In scope**
- Bug fixes in the figure / table / processing scripts.
- Documentation improvements (README, DATA_ORGANIZATION, per-campaign
  READMEs).
- Support for additional measurement campaigns that fit the existing
  per-link point-data schema.
- MATLAB version compatibility fixes (we target R2021a and later).

**Out of scope**
- New modeling methodologies that don't map to the paper's pipeline.
- Re-packaging under a different license.
- Adding raw / thresholded / measurement-like data to the repo. See
  `DATA_ORGANIZATION.md` — this repo ships code only.

## How to report a bug

Open an issue on GitHub with:

1. MATLAB release + OS.
2. The exact command you ran (e.g. `run_all('figures')`).
3. The first 20 lines of the error stack, verbatim.
4. The output of `paths()` (paste the struct fields) so we can see
   where your data is resolved.

## How to propose a change

1. Fork, branch, open a PR against `main`.
2. Keep the BA / CDF / CI numerics reproducible — if your change affects
   any of the 16 paper figures, attach before/after screenshots plus the
   new `paper_parity` output (`docs/paper_parity_matlab.md` after
   running `run_all('figures')`).
3. Match the surrounding MATLAB style. No new dependencies
   without a short rationale in the PR description.

## Maintainers

Paper corresponding authors — see `CITATION.cff`.
