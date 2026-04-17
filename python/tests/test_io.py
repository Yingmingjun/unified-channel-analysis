"""Smoke test: the loader produces the expected row counts from real xlsx.

Marked skip if the DATA_ROOT is unreachable (e.g. running the tests outside
the authoring environment).
"""
from __future__ import annotations

from pathlib import Path

import pytest

from channel_analysis import config
from channel_analysis.io import load_all


def _data_available() -> bool:
    return all(Path(p).exists() for p in config.DATA_PATHS.values())


@pytest.mark.skipif(not _data_available(), reason="institutional data not mounted")
def test_row_counts():
    df = load_all()
    # Counts per variant should match xlsx row counts
    # N1 is now pulled from the NYU-orig column of the N3 xlsx (27/20 valid
    # locations after N3 stripping); U1 from U3 xlsx USC-orig column.
    # Actual row counts from the N3/U3 xlsx: NYU 142 has 28 rows (some outage),
    # NYU 6.75 has 20 rows; USC 145.5 has 26; USC 6.75 has 17.
    expected = {
        "N1":           28 + 20,
        "N3_nyu_thr":   28 + 20,
        "N3_usc_thr":   28 + 20,
        "U1":           26 + 17,
        "U3_nyu_thr":   26 + 17,
        "U3_usc_thr":   26 + 17,
    }
    actual = df["variant"].value_counts().to_dict()
    for k, v in expected.items():
        assert actual.get(k, 0) == v, f"{k}: expected {v}, got {actual.get(k)}"
