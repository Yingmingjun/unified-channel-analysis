"""RMS delay spread statistics and lognormal CFI computation.

Paper references:
    Eq. 9: sigma_tau = sqrt(E[tau^2] - E[tau]^2).
    Section V.B: mean omni RMS DS and 95% CFI widths by LOS/NLOS and per dataset.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .config import BOOTSTRAP_ITERS, RNG_SEED

__all__ = ["rms_delay_spread_from_pdp", "lognormal_stats", "LognormalStats"]


def rms_delay_spread_from_pdp(tau_s: np.ndarray, power_lin: np.ndarray) -> float:
    """RMS delay spread from a power-delay profile (Eq. 9).

    tau_s : delay bins (arbitrary consistent units; ns conventional)
    power_lin : linear power per bin (non-negative)
    """
    tau = np.asarray(tau_s, dtype=float)
    p = np.asarray(power_lin, dtype=float)
    total = p.sum()
    if total <= 0:
        return float("nan")
    mean_tau = (p * tau).sum() / total
    mean_tau2 = (p * tau * tau).sum() / total
    var = mean_tau2 - mean_tau * mean_tau
    return float(np.sqrt(max(var, 0.0)))


@dataclass
class LognormalStats:
    mu_log10: float         # sample mean of log10(x)
    sigma_log10: float      # sample std dev of log10(x), ddof=0
    mean_arith: float       # arithmetic sample mean of x
    mean_lognormal: float   # lognormal expectation: exp(mu*ln10 + 0.5*(sigma*ln10)^2)
    cfi_low: float          # 95% bootstrap CFI lower bound on the lognormal mean
    cfi_high: float
    cfi_width: float
    n: int


def _lognormal_expectation(lx: np.ndarray) -> float:
    """E[X] for X with log10(X) ~ N(mean(lx), std(lx, ddof=0))."""
    ln10 = np.log(10.0)
    mu = lx.mean()
    sigma = lx.std(ddof=0)
    return float(np.exp(mu * ln10 + 0.5 * (sigma * ln10) ** 2))


def lognormal_stats(
    x: np.ndarray,
    n_boot: int = BOOTSTRAP_ITERS,
    seed: int = RNG_SEED,
) -> LognormalStats:
    """Lognormal summary with bootstrap CFI on the lognormal-expectation mean.

    Paper Eq. 11: E[X] = exp(mu*ln10 + (sigma*ln10)^2 / 2), where mu and
    sigma are the sample mean and std dev of log10(X). Table 7 values are
    reported as this lognormal expectation.
    """
    x = np.asarray(x, dtype=float)
    x = x[np.isfinite(x) & (x > 0)]
    n = x.size
    if n == 0:
        return LognormalStats(np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, 0)
    lx = np.log10(x)
    mu_log10 = float(lx.mean())
    sigma_log10 = float(lx.std(ddof=0))
    mean_arith = float(x.mean())
    mean_lognormal = _lognormal_expectation(lx)

    # Bootstrap CFI on the lognormal expectation
    rng = np.random.default_rng(seed)
    idx = rng.integers(0, n, size=(n_boot, n))
    lx_boot = lx[idx]
    ln10 = np.log(10.0)
    mu_b = lx_boot.mean(axis=1)
    sigma_b = lx_boot.std(axis=1, ddof=0)
    ln_means = np.exp(mu_b * ln10 + 0.5 * (sigma_b * ln10) ** 2)
    lo, hi = np.quantile(ln_means, [0.025, 0.975])
    return LognormalStats(
        mu_log10=mu_log10,
        sigma_log10=sigma_log10,
        mean_arith=mean_arith,
        mean_lognormal=mean_lognormal,
        cfi_low=float(lo),
        cfi_high=float(hi),
        cfi_width=float(hi - lo),
        n=n,
    )
