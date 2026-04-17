"""General statistical utilities: DKW CDF bands, ECDF, bootstrap."""
from __future__ import annotations

import numpy as np

from .config import RNG_SEED

__all__ = ["ecdf", "dkw_band", "bootstrap_ci", "lognormal_mean_from_params"]


def ecdf(x: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Empirical CDF. Returns sorted x and F(x)."""
    x = np.asarray(x, dtype=float)
    x = x[np.isfinite(x)]
    xs = np.sort(x)
    n = xs.size
    if n == 0:
        return xs, np.empty(0)
    fs = np.arange(1, n + 1) / n
    return xs, fs


def dkw_band(n: int, alpha: float = 0.05) -> float:
    """Dvoretzky-Kiefer-Wolfowitz uniform confidence band half-width.

    For n samples at confidence level 1-alpha, |F_emp - F_true| <= eps holds
    uniformly with probability >= 1-alpha, where eps = sqrt(ln(2/alpha)/(2n)).
    """
    if n <= 0:
        return 0.0
    return float(np.sqrt(np.log(2.0 / alpha) / (2.0 * n)))


def bootstrap_ci(
    data: np.ndarray,
    statistic,
    n_boot: int = 2000,
    alpha: float = 0.05,
    seed: int = RNG_SEED,
) -> tuple[float, float, float]:
    """Nonparametric bootstrap CI for a scalar statistic.

    Returns (point_estimate, lo, hi) at confidence 1-alpha (percentile method).
    ``data`` is resampled with replacement along its first axis.
    """
    rng = np.random.default_rng(seed)
    data = np.asarray(data)
    data = data[np.isfinite(data)] if data.ndim == 1 else data
    n = data.shape[0]
    if n == 0:
        return float("nan"), float("nan"), float("nan")
    point = float(statistic(data))
    idx = rng.integers(0, n, size=(n_boot, n))
    replicates = np.empty(n_boot)
    for b in range(n_boot):
        replicates[b] = statistic(data[idx[b]])
    lo, hi = np.quantile(replicates, [alpha / 2, 1 - alpha / 2])
    return point, float(lo), float(hi)


def lognormal_mean_from_params(mu_log10: float, sigma_log10: float) -> float:
    """Mean of X when log10(X) ~ Normal(mu, sigma).

    E[X] = exp(mu*ln10 + 0.5*(sigma*ln10)^2).
    """
    ln10 = np.log(10.0)
    return float(np.exp(mu_log10 * ln10 + 0.5 * (sigma_log10 * ln10) ** 2))
