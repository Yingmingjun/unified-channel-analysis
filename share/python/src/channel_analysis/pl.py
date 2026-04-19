"""Path-loss models: Close-In (CI), Floating Intercept (FI), and their bootstrap CIs.

Paper references:
    Eq. 13: PL(d) = PL(d0) + 10 n log10(d/d0) + X_sigma,  d0 = 1 m.
    Section V.A: 95% CFI widths on PLE reported from bootstrap resampling.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .config import BOOTSTRAP_ITERS, D0_METERS, RNG_SEED
from .stats import bootstrap_ci

__all__ = ["ci_fit", "fi_fit", "CIFit"]

FSPL_1M = {
    142.0: 75.50,     # 20 log10(4 pi * 1 / lambda) at 142 GHz
    145.5: 75.72,     # at 145.5 GHz
    6.75: 49.03,      # at 6.75 GHz
    7.0: 49.35,
}


def _fspl_db(freq_ghz: float, d0: float = 1.0) -> float:
    """Free-space path loss at reference distance d0 for the CI model."""
    c = 299_792_458.0
    lam = c / (freq_ghz * 1e9)
    return 20.0 * np.log10(4.0 * np.pi * d0 / lam)


@dataclass
class CIFit:
    ple: float           # path-loss exponent n
    sigma_sf: float      # shadowing std dev [dB]
    ple_lo: float        # PLE 95% lower CI
    ple_hi: float        # PLE 95% upper CI
    cfi_width: float     # CFI width = ple_hi - ple_lo
    fspl_1m_db: float    # free-space intercept in dB at 1 m

    def predict(self, d_m: np.ndarray) -> np.ndarray:
        d_m = np.asarray(d_m, dtype=float)
        return self.fspl_1m_db + 10.0 * self.ple * np.log10(d_m)


def _ci_point_estimate(d_m: np.ndarray, pl_db: np.ndarray, fspl_1m: float) -> tuple[float, float]:
    """Least-squares PLE with d0 intercept fixed at FSPL(1m).

    PL_i - FSPL(1m) = 10 n log10(d_i)   -> n = mean(y/x) weighted by LS.
    """
    x = 10.0 * np.log10(d_m)
    y = pl_db - fspl_1m
    n = float(np.dot(x, y) / np.dot(x, x))
    residuals = y - n * x
    sigma = float(np.sqrt(np.mean(residuals ** 2)))
    return n, sigma


def ci_fit(
    d_m: np.ndarray,
    pl_db: np.ndarray,
    freq_ghz: float,
    n_boot: int = BOOTSTRAP_ITERS,
    seed: int = RNG_SEED,
) -> CIFit:
    """Close-in PL fit with bootstrap 95% CFI on the PLE.

    Drops non-finite entries; requires at least 2 valid points.
    """
    d_m = np.asarray(d_m, dtype=float)
    pl_db = np.asarray(pl_db, dtype=float)
    mask = np.isfinite(d_m) & np.isfinite(pl_db) & (d_m > 0)
    d_m = d_m[mask]
    pl_db = pl_db[mask]
    if d_m.size < 2:
        return CIFit(np.nan, np.nan, np.nan, np.nan, np.nan, _fspl_db(freq_ghz))
    fspl_1m = _fspl_db(freq_ghz)
    n, sigma = _ci_point_estimate(d_m, pl_db, fspl_1m)

    # Bootstrap on paired samples
    rng = np.random.default_rng(seed)
    idx = rng.integers(0, d_m.size, size=(n_boot, d_m.size))
    x_all = 10.0 * np.log10(d_m)
    y_all = pl_db - fspl_1m
    # Vectorized bootstrap: n_b = sum(x*y)/sum(x*x) per resample
    x_b = x_all[idx]  # (n_boot, n)
    y_b = y_all[idx]
    n_reps = (x_b * y_b).sum(axis=1) / (x_b * x_b).sum(axis=1)
    lo, hi = np.quantile(n_reps, [0.025, 0.975])
    return CIFit(n, sigma, float(lo), float(hi), float(hi - lo), fspl_1m)


@dataclass
class FIFit:
    alpha_db: float   # intercept
    beta: float       # slope (like PLE, unconstrained intercept)
    sigma_sf: float


def fi_fit(d_m: np.ndarray, pl_db: np.ndarray) -> FIFit:
    """Floating-intercept PL fit: PL = alpha + 10 beta log10(d) + X_sigma."""
    d_m = np.asarray(d_m, dtype=float)
    pl_db = np.asarray(pl_db, dtype=float)
    mask = np.isfinite(d_m) & np.isfinite(pl_db) & (d_m > 0)
    d_m = d_m[mask]
    pl_db = pl_db[mask]
    if d_m.size < 2:
        return FIFit(np.nan, np.nan, np.nan)
    X = np.column_stack([np.ones_like(d_m), 10.0 * np.log10(d_m)])
    coef, *_ = np.linalg.lstsq(X, pl_db, rcond=None)
    alpha, beta = float(coef[0]), float(coef[1])
    residuals = pl_db - (alpha + beta * 10.0 * np.log10(d_m))
    sigma = float(np.sqrt(np.mean(residuals ** 2)))
    return FIFit(alpha, beta, sigma)
