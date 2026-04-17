"""Smoke test: the loader produces paper-matching row counts.

Skipped if the bundled data/point_data/ directory is not reachable.
"""
from __future__ import annotations

from pathlib import Path

import pytest

from channel_analysis import config
from channel_analysis.io import expected_counts, load_all


def _data_available() -> bool:
    return (config.DATA_ROOT / "NYU142GHz_Method_Comparison_Results.csv").exists()


@pytest.mark.skipif(not _data_available(), reason="authoritative CSVs not mounted")
def test_per_dataset_counts():
    df = load_all()
    exp = expected_counts()
    for (inst, freq), counts in exp.items():
        sub = df[(df.institution == inst) & (df.freq_ghz == freq)]
        assert len(sub) == counts["total"], f"{inst} {freq}: {len(sub)} != {counts['total']}"
        los = (sub["loc_type"] == "LOS").sum()
        nlos = (sub["loc_type"] == "NLOS").sum()
        assert los == counts["LOS"], f"{inst} {freq} LOS: {los}"
        assert nlos == counts["NLOS"], f"{inst} {freq} NLOS: {nlos}"


@pytest.mark.skipif(not _data_available(), reason="authoritative CSVs not mounted")
def test_pooled_totals():
    df = load_all()
    assert (df.band == "subTHz").sum() == 53     # 27 + 26
    assert (df.band == "FR1C").sum()  == 35      # 18 + 17


@pytest.mark.skipif(not _data_available(), reason="authoritative CSVs not mounted")
def test_olos_relabeled_for_usc_6p75():
    df = load_all()
    usc_7 = df[(df.institution == "USC") & (df.freq_ghz == 6.75)]
    # Modeled type should be NLOS for everything non-LOS
    assert not (usc_7["loc_type"] == "OLOS").any()
