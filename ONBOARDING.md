# Onboarding: joining the pooled-measurement framework

This checklist operationalizes the five-gate framework of the paper
*Pooling of Multi-Institutional Radio Propagation Empirical Data with
Cross-Processing Validation for 6G AI/ML Channel Modeling* (NYU + USC).
A joining institution completes the steps below **once**; the cost is
O(K) per institution, not O(K^2) pairwise replications.

## Step 1 — Obtain the golden dataset

- The per-link point-data tables and processing metadata for all 88
  NYU/USC UMi links are in `data/point_data/` of this repository.
- Golden **raw** samples (one calibrated directional-PDP location per
  institution) are available through the archival DOI / on request,
  pending institutional approval; the full raw datasets are shared
  among participating institutions under the collaboration agreement.

## Step 2 — Run the reference implementation

- MATLAB: `matlab/run_all.m` regenerates every data-derived table and
  figure of the paper from the shared raw data in one scripted run.
- Python: `python/scripts/table07_canonical.py` reproduces the paper's
  Table VI bit-exactly from the released point-data tables (no MATLAB
  required).

## Step 3 — Replicate and pass the per-link gate

- Process the golden dataset with **your own implementation** of the
  declared methods (Table II of the paper).
- Compare per link against the reference outputs under the a-priori
  tolerances: PL 0.5 dB; DS max(2 ns, 5%); AS 1 degree.
- Every out-of-tolerance cell must be diagnosed before proceeding: in
  the NYU-USC exchange this gate exposed a 533-ns delay-tail divergence
  that no aggregate statistic showed.

## Step 4 — Publish your point-data + metadata tables

- One row per TX-RX link, one column per metric, following the schema in
  the paper's supplementary material (Sec. S-IV): system parameters,
  delay/spatial thresholds, omni-synthesis method, AS definition, and
  calibration details are mandatory. Undeclared processing choices are
  the leading failure class the framework detects.

## Step 5 — Run the compatibility test before pooling

- Re-express your dataset and the pooled corpus in one common convention
  (exact per-link re-expression; no mean-offset shortcuts: the per-link
  offset is not predictable from observable statistics).
- Fit the residual inter-dataset offset beta with bootstrap CIs
  (protocol of `revision` analysis script m15 in the paper repository;
  B = 10000, percentile CIs).
- Verdicts: CI contains 0 **and** half-width <= 1 dB -> pool term-free;
  offset detected -> pool **with** an institution term; insufficient n
  -> pool with the term and consult the acquisition targets (about 40
  LOS / 400 NLOS links per institution at UMi shadowing levels).
  Pooling is never precluded; the verdict selects its statistically
  defensible form.

Quality gates that apply throughout: back-to-back calibration
verification, first-arrival causality (t >= d/c), LOS-vs-free-space
sanity, minimum dynamic range, the declared delay-resolution floor, and
Bland-Altman outlier flagging.
