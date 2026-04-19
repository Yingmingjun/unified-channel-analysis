"""Bland-Altman agreement analysis: mean-vs-difference, limits of agreement."""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

__all__ = ["bland_altman", "BAResult"]


@dataclass
class BAResult:
    mean: np.ndarray           # (a+b)/2
    diff: np.ndarray           # a - b
    bias: float                # mean(diff)
    sd: float                  # sd(diff)
    loa_low: float             # bias - 1.96 sd
    loa_high: float            # bias + 1.96 sd
    n: int


def bland_altman(a: np.ndarray, b: np.ndarray) -> BAResult:
    """Compute Bland-Altman agreement between paired samples."""
    a = np.asarray(a, dtype=float).ravel()
    b = np.asarray(b, dtype=float).ravel()
    mask = np.isfinite(a) & np.isfinite(b)
    a, b = a[mask], b[mask]
    m = 0.5 * (a + b)
    d = a - b
    bias = float(d.mean()) if d.size else float("nan")
    sd = float(d.std(ddof=1)) if d.size > 1 else float("nan")
    return BAResult(
        mean=m,
        diff=d,
        bias=bias,
        sd=sd,
        loa_low=bias - 1.96 * sd,
        loa_high=bias + 1.96 * sd,
        n=d.size,
    )
