"""Unit tests for the close-in and floating-intercept path-loss fits."""
from __future__ import annotations

import numpy as np
import pytest

from channel_analysis.pl import ci_fit, fi_fit, _fspl_db


def _synthetic_ci(n=200, ple=2.5, sigma=4.0, freq_ghz=142.0, seed=0):
    rng = np.random.default_rng(seed)
    d = rng.uniform(5, 200, n)
    fspl = _fspl_db(freq_ghz)
    pl = fspl + 10 * ple * np.log10(d) + rng.normal(0, sigma, n)
    return d, pl


def test_ci_recovers_ple_on_clean_data():
    d, pl = _synthetic_ci(n=1000, ple=2.3, sigma=0.1)
    fit = ci_fit(d, pl, freq_ghz=142.0, n_boot=200)
    assert fit.ple == pytest.approx(2.3, abs=0.01)
    assert fit.sigma_sf < 0.2


def test_ci_cfi_covers_truth_most_of_time():
    covers = 0
    for seed in range(25):
        d, pl = _synthetic_ci(n=50, ple=2.5, sigma=3.0, freq_ghz=6.75, seed=seed)
        fit = ci_fit(d, pl, freq_ghz=6.75, n_boot=400, seed=seed)
        if fit.ple_lo <= 2.5 <= fit.ple_hi:
            covers += 1
    # For 25 trials of a 95 % interval, expect >= ~20 hits
    assert covers >= 20


def test_ci_handles_nans_and_min_sample():
    fit = ci_fit(np.array([1.0]), np.array([60.0]), freq_ghz=6.75)
    assert np.isnan(fit.ple)


def test_fi_fit_recovers_slope_intercept():
    # Synthetic FI: alpha=20, beta=3.0 at d0 implicit in formula
    rng = np.random.default_rng(0)
    d = rng.uniform(5, 200, 300)
    alpha, beta = 20.0, 3.0
    pl = alpha + beta * 10 * np.log10(d) + rng.normal(0, 0.5, 300)
    fit = fi_fit(d, pl)
    assert fit.alpha_db == pytest.approx(alpha, abs=0.5)
    assert fit.beta == pytest.approx(beta, abs=0.02)
