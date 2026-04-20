"""Unit tests for statistical utilities."""
from __future__ import annotations

import numpy as np
import pytest

from channel_analysis.bland_altman import bland_altman
from channel_analysis.stats import bootstrap_ci, dkw_band, ecdf


def test_ecdf_monotone():
    xs, fs = ecdf(np.array([3, 1, 4, 1, 5, 9, 2, 6]))
    assert np.all(np.diff(fs) >= 0)
    assert xs[0] == 1 and fs[-1] == 1.0


def test_dkw_band_formula():
    # At n=100, alpha=0.05: eps = sqrt(ln(40)/200)
    assert dkw_band(100) == pytest.approx(np.sqrt(np.log(40) / 200), rel=1e-9)
    assert dkw_band(0) == 0.0


def test_bootstrap_ci_covers_known_mean():
    rng = np.random.default_rng(0)
    data = rng.normal(3.0, 1.0, 200)
    pt, lo, hi = bootstrap_ci(data, np.mean, n_boot=500)
    assert lo <= 3.0 <= hi
    assert pt == pytest.approx(data.mean())


def test_bland_altman_identical_inputs_have_zero_bias():
    rng = np.random.default_rng(0)
    a = rng.uniform(10, 100, 50)
    res = bland_altman(a, a)
    assert res.bias == pytest.approx(0.0, abs=1e-10)
    assert res.sd == pytest.approx(0.0, abs=1e-10)
