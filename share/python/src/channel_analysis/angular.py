"""Angular spread definitions used in the paper.

Three formulas are provided, matching the MATLAB implementations:

    1. 3GPP circular standard deviation (Eq. 10):
           sigma = sqrt(-2 ln |R|)
    2. Fleury (Eq. 12, Table 5):
           sigma = sqrt(1 - |R|^2)            (unitless in [0, 1])
    3. NYU 360-degree minimum-search RMS:
           iterates over integer origin shifts d in [0, 360) and returns
           the minimum of second-central-moment; equivalent to the 3GPP
           circular-std-dev for power-weighted phasors in the small-AS
           limit but generalizes to wider distributions.

R is the magnitude of the power-weighted mean phasor:
    R = | sum_k p_k exp(j theta_k) / sum_k p_k |.

All inputs expect ``theta`` in degrees (converted internally) and ``power``
either linear or dB (see boolean flag). Outputs in degrees.
"""
from __future__ import annotations

import numpy as np

__all__ = [
    "angular_spread_gpp",
    "angular_spread_fleury",
    "angular_spread_nyu_360",
    "fleury_to_gpp",
    "mean_phasor_magnitude",
]


def _as_linear_power(power, is_db: bool) -> np.ndarray:
    p = np.asarray(power, dtype=float).ravel()
    if is_db:
        p = 10.0 ** (p / 10.0)
    return p


def mean_phasor_magnitude(theta_deg, power, is_db: bool = False) -> float:
    """|R| of the power-weighted unit phasor."""
    theta = np.asarray(theta_deg, dtype=float).ravel()
    p = _as_linear_power(power, is_db)
    total = p.sum()
    if total <= 0:
        return float("nan")
    phasor = (p * np.exp(1j * np.deg2rad(theta))).sum() / total
    return float(np.abs(phasor))


def angular_spread_gpp(theta_deg, power, is_db: bool = False) -> float:
    """3GPP TR 38.901 circular standard deviation (Eq. 10), degrees."""
    r = mean_phasor_magnitude(theta_deg, power, is_db=is_db)
    if not np.isfinite(r) or r <= 0:
        return float("nan")
    r = min(r, 1.0)
    return float(np.rad2deg(np.sqrt(-2.0 * np.log(r))))


def angular_spread_fleury(theta_deg, power, is_db: bool = False) -> float:
    """Fleury angular spread (Eq. 12), unitless in [0, sqrt(2)].

    To convert to an angle in degrees use ``fleury_to_gpp`` or multiply
    by 180/pi only in the small-spread limit.
    """
    theta = np.asarray(theta_deg, dtype=float).ravel()
    p = _as_linear_power(power, is_db)
    total = p.sum()
    if total <= 0:
        return float("nan")
    phi = np.exp(1j * np.deg2rad(theta))
    mu = (p * phi).sum() / total
    # Equivalent forms: sqrt(1 - |mu|^2)  ==  sqrt(sum(|phi - mu|^2 * p) / total)
    return float(np.sqrt(max(1.0 - np.abs(mu) ** 2, 0.0)))


def fleury_to_gpp(sigma_fleury: float) -> float:
    """Convert a Fleury-form AS (unitless) to 3GPP AS in degrees.

    R = sqrt(1 - sigma_fleury^2); sigma_gpp_deg = rad2deg(sqrt(-2 ln R)).
    """
    if not np.isfinite(sigma_fleury):
        return float("nan")
    r2 = max(1.0 - sigma_fleury ** 2, 1e-16)
    return float(np.rad2deg(np.sqrt(-2.0 * np.log(np.sqrt(r2)))))


def angular_spread_nyu_360(theta_deg, power, is_db: bool = False) -> float:
    """NYU 360-degree-search RMS angular spread (compute_angular_spread.m).

    For each integer d in [0, 360): shift origin, compute power-weighted mean,
    then second central moment. Return the minimum across d.
    Result in degrees.
    """
    theta = np.asarray(theta_deg, dtype=float).ravel()
    p = _as_linear_power(power, is_db)
    total = p.sum()
    if total <= 0:
        return float("nan")
    d = np.arange(360)[:, None]         # (360, 1)
    th = theta[None, :]                  # (1, K)
    shifted = ((th + d + 180.0) % 360.0) - 180.0
    mu = (p * shifted).sum(axis=1, keepdims=True) / total
    centered = ((shifted - mu + 180.0) % 360.0) - 180.0
    sigma2 = (p * centered ** 2).sum(axis=1) / total
    return float(np.sqrt(np.min(sigma2)))
