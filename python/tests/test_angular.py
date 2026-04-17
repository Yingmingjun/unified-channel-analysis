"""Unit tests for angular-spread formulas.

These tests pin behavior on synthetic PAS so regressions in the numerical
definitions surface immediately.
"""
from __future__ import annotations

import numpy as np
import pytest

from channel_analysis.angular import (
    angular_spread_fleury,
    angular_spread_gpp,
    angular_spread_nyu_360,
    fleury_to_gpp,
    mean_phasor_magnitude,
)


def test_delta_function_zero_spread():
    """A single-direction PAS has zero angular spread."""
    theta = np.array([45.0])
    power = np.array([1.0])
    assert angular_spread_gpp(theta, power) == pytest.approx(0.0, abs=1e-9)
    assert angular_spread_fleury(theta, power) == pytest.approx(0.0, abs=1e-9)
    assert angular_spread_nyu_360(theta, power) == pytest.approx(0.0, abs=1e-9)


def test_two_peak_symmetric_small_spread():
    """Two equal-power peaks at +/- 5 deg have small AS; 3GPP ~ deg."""
    theta = np.array([-5.0, 5.0])
    power = np.array([1.0, 1.0])
    sigma_gpp = angular_spread_gpp(theta, power)
    # Expected via R = |cos(5°)|, sigma = sqrt(-2 ln R); convert to deg
    expected_rad = np.sqrt(-2.0 * np.log(np.cos(np.deg2rad(5.0))))
    assert sigma_gpp == pytest.approx(np.rad2deg(expected_rad), rel=1e-6)


def test_fleury_gpp_relationship():
    """For any power-weighted phasor, sigma_gpp(deg) == fleury_to_gpp(sigma_fleury)."""
    rng = np.random.default_rng(42)
    for _ in range(20):
        k = rng.integers(3, 40)
        theta = rng.uniform(-180, 180, k)
        power = rng.uniform(0.1, 10.0, k)
        sigma_gpp = angular_spread_gpp(theta, power)
        sigma_fleury = angular_spread_fleury(theta, power)
        sigma_gpp_from_fleury = fleury_to_gpp(sigma_fleury)
        assert sigma_gpp == pytest.approx(sigma_gpp_from_fleury, rel=1e-9, abs=1e-9)


def test_uniform_full_circle_degenerate():
    """Uniform PAS over full circle produces Fleury sigma = 1 (max R=0)."""
    theta = np.linspace(-180, 180, 361, endpoint=False)
    power = np.ones_like(theta)
    assert mean_phasor_magnitude(theta, power) == pytest.approx(0.0, abs=1e-10)
    assert angular_spread_fleury(theta, power) == pytest.approx(1.0, abs=1e-10)


def test_db_linear_consistency():
    """Passing dB vs linear power should yield identical AS values."""
    theta = np.array([-30.0, 0.0, 30.0])
    p_lin = np.array([0.5, 1.0, 0.25])
    p_db = 10.0 * np.log10(p_lin)
    assert angular_spread_gpp(theta, p_lin, is_db=False) == pytest.approx(
        angular_spread_gpp(theta, p_db, is_db=True), rel=1e-10)
    assert angular_spread_fleury(theta, p_lin, is_db=False) == pytest.approx(
        angular_spread_fleury(theta, p_db, is_db=True), rel=1e-10)


def test_fleury_two_forms_equivalent():
    """
    Paper gives two forms of Fleury AS. On unit phasors they are equivalent:
        sigma^2 = 1 - |R|^2  ==  sum(|e^{j phi} - mu|^2 p) / sum p.
    This is a direct algebraic identity; verify numerically for safety.
    """
    rng = np.random.default_rng(7)
    for _ in range(20):
        k = rng.integers(3, 50)
        theta = rng.uniform(-180, 180, k)
        p = rng.uniform(0.1, 5.0, k)
        total = p.sum()
        phi = np.exp(1j * np.deg2rad(theta))
        mu = (p * phi).sum() / total
        sigma2_a = 1.0 - abs(mu) ** 2
        sigma2_b = (p * np.abs(phi - mu) ** 2).sum() / total
        assert sigma2_a == pytest.approx(sigma2_b, rel=1e-10)


def test_nyu_360_matches_3gpp_small_spread():
    """For a single lobe, NYU 360-search reduces to the standard RMS formula
    which in the small-spread limit equals the 3GPP circular std dev."""
    theta = np.array([-2.0, 0.0, 2.0])
    power = np.array([0.5, 1.0, 0.5])
    sigma_nyu = angular_spread_nyu_360(theta, power)
    sigma_gpp = angular_spread_gpp(theta, power)
    # Small-spread limit: agreement within 2 %
    assert sigma_nyu == pytest.approx(sigma_gpp, rel=0.02)
