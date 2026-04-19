"""Fig. 5 — CI path-loss scatter with per-group fits (LOS & NLOS combined).

Paper layout (from ``cdf_ci_pl_analysis.m`` → ``plot_ci_models``): two
figures (sub-THz, 6.75 GHz). Each figure has a single axes with ALL TX-RX
pairs scattered — LOS as circles, NLOS as squares — plus six fit lines:

    LOS  × {NYU, USC, Pooled}
    NLOS × {NYU, USC, Pooled}

Scatter counts per figure:
    Sub-THz: 29 LOS + 24 NLOS = 53 dots
    6.75 GHz: 12 LOS + 23 NLOS = 35 dots

CI model: PL(d) = FSPL(1 m) + 10 n log10(d) + X_σ,  d0 = 1 m.
Data source: ``pl_nyu_sum`` column (NYU-method, NYU-threshold — the paper's
Table-7 PLEs are computed on this variant for NYU and on ``pl_usc_pdm`` for
USC; we plot the NYU-method value for both, matching Fig 5 of the paper
where a single PL per location is used).
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from .. import config
from ..io import load_point_data
from ..pl import ci_fit
from ._common import apply_style, save


def _pl_values(df):
    """Paper Table 7 / Fig 5 use the institution's thresholded original PL
    (xlsx "<inst> orig" column). Fallback: per-method CSV columns."""
    if "pl_db" in df.columns and df["pl_db"].notna().any():
        return df["pl_db"].to_numpy(dtype=float)
    out = np.where(df["institution"].values == "NYU",
                   df["pl_nyu_sum"].values, df["pl_usc_pdm"].values)
    return out.astype(float)


def _fit_and_draw(ax, d, pl, loc, color, label, line_style):
    fit = ci_fit(d, pl, freq_ghz=_pooled_freq_for(loc))
    dgrid = np.logspace(np.log10(max(np.nanmin(d[np.isfinite(d)]), 1.0)),
                        np.log10(np.nanmax(d[np.isfinite(d)])), 100)
    yhat = fit.fspl_1m_db + 10.0 * fit.ple * np.log10(dgrid)
    ax.plot(dgrid, yhat, color=color, linestyle=line_style, linewidth=1.8,
            label=f"{label}: n={fit.ple:.2f}, σ={fit.sigma_sf:.2f} dB")
    return fit


def _pooled_freq_for(loc):
    # Placeholder (set by caller via side-effect) — use the module-level FREQ
    global _CURRENT_FREQ
    return _CURRENT_FREQ


_CURRENT_FREQ = 142.0


def _render_band(band, freq_label, pooled_freq, stem, xlim):
    global _CURRENT_FREQ
    _CURRENT_FREQ = pooled_freq

    df = load_point_data()
    sub = df[df.band == band].copy()
    sub["pl"] = _pl_values(sub)

    fig, ax = plt.subplots(figsize=(10, 6))

    # Scatter: LOS = circles, NLOS = squares; color by institution
    for inst, color in (("NYU", config.COLORS["nyu"]), ("USC", config.COLORS["usc"])):
        for loc, marker in (("LOS", "o"), ("NLOS", "s")):
            s = sub[(sub.institution == inst) & (sub.loc_type == loc)]
            ax.scatter(s["d_m"], s["pl"], s=50, marker=marker,
                       facecolor=color, edgecolor="k", linewidths=0.5,
                       alpha=0.75,
                       label=f"{inst} {loc} data (n={len(s)})")

    # Six fit lines
    for loc, style in (("LOS", "-"), ("NLOS", "--")):
        for inst_key, color, inst_filter in (
            ("NYU",    config.COLORS["nyu"],    lambda s: s.institution == "NYU"),
            ("USC",    config.COLORS["usc"],    lambda s: s.institution == "USC"),
            ("Pooled", config.COLORS["gray"],   lambda s: np.full(len(s), True)),
        ):
            mask = inst_filter(sub) & (sub.loc_type == loc).values
            g = sub.loc[mask]
            if len(g) < 2:
                continue
            _fit_and_draw(ax, g["d_m"].to_numpy(), g["pl"].to_numpy(), loc,
                          color, f"{inst_key} {loc} fit", style)

    ax.set_xscale("log")
    ax.set_xlim(*xlim)
    ax.set_xlabel("TX–RX Separation d (m)")
    ax.set_ylabel("Omni Path Loss (dB)")
    ax.set_title(f"CI path-loss fit — pooled NYU + USC, {freq_label}")
    ax.legend(loc="upper left", fontsize=8, ncol=2, framealpha=0.9)
    fig.tight_layout()
    save(fig, stem)

    # Collect stats for parity
    out = {}
    for inst_key, inst_filter in (("NYU",    lambda s: s.institution == "NYU"),
                                   ("USC",    lambda s: s.institution == "USC"),
                                   ("Pooled", lambda s: np.full(len(s), True))):
        for loc in ("LOS", "NLOS"):
            mask = inst_filter(sub) & (sub.loc_type == loc).values
            g = sub.loc[mask]
            if len(g) < 2:
                continue
            fit = ci_fit(g["d_m"].to_numpy(), g["pl"].to_numpy(),
                         freq_ghz=pooled_freq)
            out[f"{inst_key}_{loc}"] = {
                "n": int(len(g)), "PLE": fit.ple,
                "sigma_SF_dB": fit.sigma_sf,
                "PLE_CFI_lo": fit.ple_lo, "PLE_CFI_hi": fit.ple_hi,
                "PLE_CFI_width": fit.cfi_width,
            }
    return out


def render() -> dict:
    apply_style()
    stats: dict = {}
    stats["subTHz"] = _render_band("subTHz", "Sub-THz (142 / 145.5 GHz)",
                                    143.75,
                                    stem="fig05_PLcombinedPlot",
                                    xlim=(10, 500))
    stats["FR1C"]   = _render_band("FR1C", "FR1(C) 6.75 GHz",
                                    6.75,
                                    stem="fig05_PLcombinedPlot7",
                                    xlim=(10, 500))
    return stats
