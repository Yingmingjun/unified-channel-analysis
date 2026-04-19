# `lib_tcsl/` — vendored NYU angular-spread helpers

These 28 `.m` files are **NYU WIRELESS / Tandon Channel Sounder Lab
(TCSL) internal helpers** that the raw-processing and angular-spread
computation code depends on. They are vendored here (verbatim, with
their original file names) so that the MATLAB pipeline reproduces
NYU's published N1 angular-spread values bit-for-bit.

> **You almost certainly should not call anything in this folder
> directly.** Use the higher-level API in [`../lib/`](../lib/) and
> [`../figures/`](../figures/) instead.

## Where these are consumed

* `matlab/processing/nyu_142/NYU142GHz_Method_Comparison.m`
  and `matlab/processing/nyu_7/NYU7GHz_Method_Comparison.m` call
  `PASgenerator`, `SecondaryStats_circD`, `computeDSonMPC`,
  `boundaryMPCsD`, `lobeShaperCounterD`, and friends during
  raw-PDP → angular-spread reduction.
* `matlab/processing/usc_145/USC142GHz_Method_Comparison_Full.m`
  and `matlab/processing/usc_7/USC7GHz_NewData_Processing.m` reuse
  the same helpers so the USC pipeline's NYU-method replication
  produces byte-identical angular-spread outputs.
* The downstream figure drivers (`fig03..fig08`, `paper_figures/*`)
  never touch `lib_tcsl/` directly — they read already-reduced
  xlsx tables via `lib/load_point_data.m`.

## Public entry points you *can* rely on

If you want to compute angular spread on your own PAS arrays, use
these two stable wrappers in the same folder:

| File                      | Use                                                    |
|---------------------------|--------------------------------------------------------|
| `compute_angular_spread.m`| Given a PAS array, compute Fleury / 3GPP AS            |
| `computeDSonMPC.m`        | RMS delay spread from an MPC list (not a raw PDP)      |

Everything else (`PASgenerator`, `clusterSearch`, `boundaryMPCs*`,
`lobeShaperCounter*`, `SubPathPwrDirs*`, `SecondaryStats*`,
`meanSLangles`, `mmsefit`, `circ_{mean,r,std}`, `AS_PAS`, `CDFplots`,
`PDPdenoise`) is called only from within the raw-processing scripts.

## File groups

The files fall into four functional groups (only noted here for orientation —
the pipeline handles call order for you):

1. **PAS / angular reduction**
   `PASgenerator`, `AS_PAS`, `angularSpread`, `compute_angular_spread`
2. **Multipath-component extraction** (with and without 10 dB PAS SLT)
   `SubPathPwrDirs`, `SubPathPwrDirsD`, `boundaryMPCs`, `boundaryMPCsD`,
   `lobeShaperCounter`, `lobeShaperCounterD`, `clusterSearch`,
   `meanSLangles`
3. **Secondary statistics**
   `SecondaryStats`, `SecondaryStatsD`, `SecondaryStats_circ`,
   `SecondaryStats_circD`, `computeDSonMPC`, `computeDirDS`,
   `getdirRMSDS`
4. **Utilities**
   `circ_mean`, `circ_r`, `circ_std`, `mmsefit`, `PDPdenoise`,
   `CDFplots`, `natsort`, `natsortfiles`

## Provenance and modifications

* Source: NYU WIRELESS TCSL internal toolbox as of 2024-Q4.
* No file has been modified except `PDPdenoise.m` to fix the eps →
  realmin clamp (see the fix commit `88e17fe`). That change affects
  *delay-spread* computation; angular-spread numbers are byte-identical
  to NYU's original values.
* If you need to update from a newer upstream TCSL release, diff the
  result against our bundled copies and re-run `run_all` to confirm
  the N1 xlsx columns still match paper Table VII.

## License

Files inherit NYU WIRELESS's academic-research license terms.
Redistributed here by permission of the authors for the sole purpose
of reproducing the results in the companion paper.
