# Code Inventory — Index

The full inventories live in two files, split by codebase:

- [`code_inventory_A.md`](code_inventory_A.md) — Codebase A (PL/DS): `D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare/`. 104 `.m` files. Entry points: `cdf_ci_pl_analysis.m`, `bland_altman_analysis.m`, `USC/USCprocessNYUdata/USCprocessNYU142M_exp.m`, `NYU/NYUprocessUSCdata/NYUprocessUSC145.m`, `USC/USCprocessUSCdata/USCprocessUSC145_exp.m`.
- [`code_inventory_B.md`](code_inventory_B.md) — Codebase B (AS): `D:/NYU-USC/Cross-Processing/`. 142 `.m` files. Entry point for paper figs: `AS_CDF_Merged.m`, `BA_AS_Merged.m`, `Plot_BlandAltman_PL_DS_AS.m`, `Comprehensive_NYU_USC_Analysis_v7.m` (authoritative version).

See also:

- [`paper_to_code_mapping.md`](paper_to_code_mapping.md) — which MATLAB script and which Python driver produces each paper figure / table / numerical claim.
- [`code_conflicts.md`](code_conflicts.md) — version conflicts (v2–v7), duplicate functions, and how each was resolved.
- [`issues_log.md`](issues_log.md) — unmapped / diagnostic scripts, ambiguities, and best-judgment decisions made during the port.

## Plotting style (aggregated from both codebases)

Extracted from actual `plot()` / `set(gca,...)` / `xlabel(...)` calls across the paper-figure MATLAB scripts. This is the specification matched by `python/src/channel_analysis/styles/paper.mplstyle`.

- **Font:** Times New Roman (LaTeX interpreter) — fallback `serif`
- **Axis label font size:** 14–16 pt (paper figs); tick labels 12–14 pt
- **Legend font size:** 12–14 pt, `Location='best'` default
- **Line width:** 2.0–2.4 for CDF curves; 1.6 for fit lines; 1.2 for reference lines
- **Marker size:** 70–90 pt² (CDF overlays); 50 pt² (PL scatter); 120 pt² (Bland–Altman)
- **Colors (canonical):**
  - NYU: `#0072BD` (blue) `[0.00, 0.45, 0.74]`
  - USC: `#D95319` (orange) `[0.85, 0.33, 0.10]`
  - Pooled: `#333333` (gray) or `#1A26E6` (royal-blue) in merged plots
  - NYU threshold variants: 10 dB blue, 15 dB orange, 20 dB gold `[0.929, 0.694, 0.125]`, 25 dB USC-green `[0.466, 0.674, 0.188]`
- **Markers:** `o` LOS, `s` NLOS (Codebase A); `o` NYU / `d` NLOS / `s` USC (Codebase B, BA figs)
- **CDF confidence band:** DKW `ε = sqrt(ln(2/0.05)/(2n))`, `fill_between` with alpha 0.10–0.12, no edge
- **Grid:** on, `alpha=0.3`, linestyle `:`
- **PL axis:** x `log10(d)` display as log scale, `xlim=[1, 200]` m
- **Export:** 300 dpi, white background, both `.pdf` and `.png`
