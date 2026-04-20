"""Unit tests for RMS delay spread and lognormal stats."""
from __future__ import annotations

import numpy as np
import pytest

from channel_analysis.ds import lognormal_stats, rms_delay_spread_from_pdp


def test_delta_pdp_zero_ds():
    tau = np.array([0.0, 1.0, 2.0])
    p = np.array([0.0, 1.0, 0.0])
    assert rms_delay_spread_from_pdp(tau, p) == pytest.approx(0.0, abs=1e-10)


def test_symmetric_two_taps():
    tau = np.array([0.0, 10.0])
    p = np.array([1.0, 1.0])
    # mean = 5, var = 25, sigma = 5
    assert rms_delay_spread_from_pdp(tau, p) == pytest.approx(5.0, rel=1e-9)


def test_zero_power_returns_nan():
    tau = np.array([0.0, 1.0])
    p = np.array([0.0, 0.0])
    assert np.isnan(rms_delay_spread_from_pdp(tau, p))


def test_lognormal_stats_on_constant_sample():
    x = np.full(10, 20.0)
    res = lognormal_stats(x)
    assert res.mean_arith == pytest.approx(20.0)
    assert res.mean_lognormal == pytest.approx(20.0)
    assert res.cfi_width == pytest.approx(0.0, abs=1e-9)
    assert res.sigma_log10 == pytest.approx(0.0, abs=1e-9)


def test_lognormal_stats_bootstrap_ci_shrinks_with_n():
    rng = np.random.default_rng(0)
    small = rng.lognormal(mean=2, sigma=0.5, size=20)
    big = rng.lognormal(mean=2, sigma=0.5, size=2000)
    r_small = lognormal_stats(small, n_boot=500)
    r_big = lognormal_stats(big, n_boot=500)
    assert r_big.cfi_width < r_small.cfi_width
