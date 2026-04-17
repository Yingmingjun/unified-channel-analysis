# Delay gating parity across the 4 Processing pipelines

## Problem

The paper methodology claims USC uses a delay-domain gate `τ_gate = 966.67 ns` for 145.5 GHz (Section IV.A). NYU's corresponding threshold is power-domain only (`max(peak − 25 dB, NF + 5 dB)`). But the cross-processing scripts have inconsistent gating:

| Script | Applies delay gate `t <= tgate`? |
|--------|-----------------------------------|
| `USC/USCprocessUSCdata/rms_delay_spread_calc.m` (U1 reference) | ✅ YES |
| `USC/USCprocessNYUdata/rms_delay_spread_calc.m` (N3 cross-processed) | ❌ NO (tgate param silently dropped) |
| `NYU/NYUprocessUSCdata/rms_delay_spread_calc.m` (U3 cross-processed) | ❌ NO (tgate param silently dropped) |

All three files share the identical misleading comment: `"% Apply delay gating (This point is redundant)"`.

## Upstream: 4 Processing/* pipelines

| Pipeline | Had delay gate before patch? |
|----------|------------------------------|
| `matlab/processing/usc_145/USC142GHz_Method_Comparison_Full.m` | ✅ YES (`(d(end) − 10 + d_LOS)/c`) |
| `matlab/processing/usc_7/USC7GHz_NewData_Processing.m` | ✅ YES (same formula) |
| `matlab/processing/nyu_142/NYU142GHz_Method_Comparison.m` | ❌ NO |
| `matlab/processing/nyu_7/NYU7GHz_Method_Comparison.m` | ❌ NO |

## Patch applied (this commit)

Added an optional `tgate_ns` parameter to the local `compute_RMS_DS` function in both NYU pipelines plus a top-level `params.DS_DELAY_GATE_NS` config flag that is passed to each call site.

### Behavior

- **Default (`params.DS_DELAY_GATE_NS = Inf`)**: no change. DS computation is identical to the historical NYU behavior — no time-domain gate, only the upstream per-PDP power threshold.
- **Set to a finite value (e.g. `966.67`)**: samples with `delays_ns > tgate_ns` are excluded from the DS computation, matching the USC-side `USCprocessUSCdata/rms_delay_spread_calc.m` line:
    ```matlab
    pdp_val = pdp .* pdp_Ind .* (t <= tgate).';
    ```

### Files changed

- `matlab/processing/nyu_142/NYU142GHz_Method_Comparison.m`:
  - `params.DS_DELAY_GATE_NS = Inf;` at the top of the config block.
  - `compute_RMS_DS(..., params.DS_DELAY_GATE_NS)` at 2 call sites (DS_NYU, DS_USC).
  - Local `compute_RMS_DS` function signature extended to `(delays_ns, PDP_lin, tgate_ns)` with back-compat default.
- `matlab/processing/nyu_7/NYU7GHz_Method_Comparison.m`:
  - Same 3 edits; 4 call sites (DS_NYUthr_{SUM,pDM}, DS_USCthr_{SUM,pDM}).

### Zero effect by default

Because the default is `Inf`, running `run_all` or `run_all('rebuild')` without editing anything produces **identical** per-location PL/DS/AS values to before this patch — verified by the fact that the computation `x .* (x <= Inf)` equals `x` elementwise.

## To enable the gate and see if Table VI closes

Edit two lines — one in each NYU script — and re-run:

```matlab
% matlab/processing/nyu_142/NYU142GHz_Method_Comparison.m
params.DS_DELAY_GATE_NS = 966.67;    % or other value matching USC

% matlab/processing/nyu_7/NYU7GHz_Method_Comparison.m
params.DS_DELAY_GATE_NS = 966.67;
```

Then:

```matlab
cd D:/unified-channel-analysis/matlab
run_all('rebuild')     % forces STEP 1 raw processing to rerun with new gate
```

STEP 4 (`paper_parity`) will print the new TIGHT/CLOSE/MISS tally. Expect:

- **DS values on a few long-NLOS links at 6.75 GHz shift downward** by up to tens of ns (gate excludes late multipath)
- **Table VI 6.75 GHz USC-data DS RMSE** moves toward the paper's 39.47 / 7.21 ns if the paper was computed with USC-style gating applied uniformly

If the gate DOESN'T close the 4 MISSes, set it back to `Inf` and the gate isn't the right fix for that residual drift — it's then clearly a xlsx-snapshot issue.

## Cross-processing scripts (`matlab/processing_cb_a/`)

The `rms_delay_spread_calc.m` files in the cb_a folders (Codebase-A cross-processing) were NOT patched in this commit because (a) the paper's own scripts have the tgate-dropped signature and (b) those are the authors' own scripts; editing them invasively would diverge from what the paper describes. If you want them patched too, the same recipe works — add optional `tgate` parameter and apply `.*(t<=tgate).'` mask.

## References

- Paper Section IV.A: NYU delay-domain threshold (`max(peak−25, NF+5)`), USC delay-domain threshold (noise-floor + 12 dB) + `τ_gate = 966.67 ns`.
- `USC/USCprocessUSCdata/rms_delay_spread_calc.m` line 9 for the USC gating formula.
- `matlab/processing/usc_145/USC142GHz_Method_Comparison_Full.m` lines 329 / 370 / 386 for the dynamic gate `(d(end) − 10 + d_LOS) / c`.
