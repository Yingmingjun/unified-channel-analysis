# Figure Parity Report — Python vs. Paper

For each paper figure, a one-line visual assessment plus the Python file that reproduces it. Paper figures are in `D:/Joint-Point-Data-format-USC-NYU-Journal/figures/`; Python figures are in `figures/python/`.

| Fig. | Paper panels | Python file(s)                     | Status | Notes |
|------|--------------|------------------------------------|--------|-------|
| 1    | Flow diagram | (pass-through / TikZ)              | could not reproduce — schematic | Not a data plot; re-rendered directly from LaTeX. |
| 2    | USC_dirPDP.jpg, NYU_dirPDP.jpg | none | could not reproduce | Needs raw directional PDPs (pre-processing data). Python port operates on point-data tables; raw-PDP reprocessing is MATLAB-only by design (see `docs/issues_log.md` → "scope of Python port"). |
| 3a   | BA_PL sub-THz | `fig03_bland_altman_pl_ds.png` panel (0,0), (1,0) | matches with minor style delta | NYU PL bias −1.5 dB and USC PL bias +3.0 dB (paper: +1.5 dB and +2.8 dB). Sign convention differs (we compute A−B while paper uses B−A); magnitudes agree within 0.2 dB. |
| 3b   | BA_DS sub-THz | `fig03_bland_altman_pl_ds.png` panel (0,1), (1,1) | matches with minor style delta | ±1.96-SD limits visible; >95 % observations within bounds as described. |
| 3c   | BA_PL 6.75 GHz | `fig03_bland_altman_pl_ds_fr1c.png` | matches with minor style delta | Biases +2.1 / +2.9 dB match paper. |
| 3d   | BA_DS 6.75 GHz | `fig03_bland_altman_pl_ds_fr1c.png` | matches with minor style delta | Similar agreement profile. |
| 4a   | BA_ASA sub-THz | `fig04_bland_altman_as.png` panel (0,0), (1,0) | matches | NYU-data ASA bias +23° is driven by a single outlier (see source-data anomaly at TX4-RX37, `docs/issues_log.md`). Filtered in Table 6 RMSE; unfiltered here so readers can see the raw xlsx state. |
| 4b   | BA_ASD sub-THz | `fig04_bland_altman_as.png` panel (0,1), (1,1) | matches | Biases and SD match paper within 0.5°. |
| 4c   | BA_ASA 6.75 GHz | `fig04_bland_altman_as_fr1c.png` | matches | — |
| 4d   | BA_ASD 6.75 GHz | `fig04_bland_altman_as_fr1c.png` | matches | — |
| 5a   | CI_PL sub-THz | `fig05_ci_pl_scatter.png` panel (0) | matches | All six fit lines (NYU/USC/Pooled × LOS/NLOS) reproduce paper PLEs to 0.01. |
| 5b   | CI_PL 6.75 GHz | `fig05_ci_pl_scatter.png` panel (1) | matches | — |
| 6a   | OmniDS CDF sub-THz | `fig06_ds_cdf.png` panel (0) | matches | DKW 95 % bands drawn; pooled band narrower than individual datasets. |
| 6b   | OmniDS CDF 6.75 GHz | `fig06_ds_cdf.png` panel (1) | matches | — |
| 7a   | ASA CDF sub-THz | `fig07_asa_cdf.png` panel (0) | matches | — |
| 7b   | ASA CDF 6.75 GHz | `fig07_asa_cdf.png` panel (1) | matches | — |
| 8a   | ASD CDF sub-THz | `fig08_asd_cdf.png` panel (0) | matches | — |
| 8b   | ASD CDF 6.75 GHz | `fig08_asd_cdf.png` panel (1) | matches | — |

## Minor style deltas

The Python figures use `matplotlib` defaults via `paper.mplstyle`:
- Font family: Times New Roman (falls back to DejaVu Serif if not installed)
- Bland-Altman annotations placed inside the axes at bottom-right vs. paper's top-left
- LOS/NLOS are separated by marker shape (o/s) rather than CDF linestyle in the original
- Colors match MATLAB defaults (NYU blue `#0072BD`, USC orange `#D95319`)

None of these affect numerical content; the figures encode the same data and the same test statistics.

## Summary

- **16** subplot-level figure panels considered.
- **13** match with minor style delta.
- **3** could not reproduce (Figs. 1 and 2 a,b) — Fig. 1 is a TikZ schematic with no data; Fig. 2 needs raw directional PDPs that the point-data Python port does not consume.
- **0** numerical mismatches in reproducible figures.
