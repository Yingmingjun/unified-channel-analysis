"""End-to-end orchestrator: regenerates every figure and table.

Usage:
    python -m channel_analysis.run_all
or (after ``pip install -e python``):
    channel-run-all
"""
from __future__ import annotations

import json
import sys
import traceback
from pathlib import Path

import numpy as np

from . import config
from .figures import (
    fig03_bland_altman_pl_ds,
    fig04_bland_altman_as,
    fig05_ci_pl_scatter,
    fig06_ds_cdf,
    fig07_asa_cdf,
    fig08_asd_cdf,
    paper_parity,
    table06_rmse,
    table07_pooled_stats,
    table_dumps,
)

DRIVERS = [
    ("fig03_bland_altman_pl_ds", fig03_bland_altman_pl_ds.render),
    ("fig04_bland_altman_as", fig04_bland_altman_as.render),
    ("fig05_ci_pl_scatter", fig05_ci_pl_scatter.render),
    ("fig06_ds_cdf", fig06_ds_cdf.render),
    ("fig07_asa_cdf", fig07_asa_cdf.render),
    ("fig08_asd_cdf", fig08_asd_cdf.render),
    ("table06_rmse", table06_rmse.render),
    ("table07_pooled_stats", table07_pooled_stats.render),
    ("table_dumps_4_8_9_10_11", table_dumps.render),
    ("paper_parity",              paper_parity.render),
]


def _coerce(o):
    if isinstance(o, dict):
        return {k: _coerce(v) for k, v in o.items()}
    if isinstance(o, (list, tuple)):
        return [_coerce(v) for v in o]
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    if isinstance(o, np.ndarray):
        return o.tolist()
    return o


def main() -> int:
    np.random.seed(config.RNG_SEED)
    config.ensure_output_dirs()
    results: dict = {}
    errors: dict = {}
    for name, driver in DRIVERS:
        print(f"[run_all] {name} …", flush=True)
        try:
            results[name] = driver()
            print(f"[run_all] {name} OK", flush=True)
        except Exception as exc:   # noqa: BLE001 — log and continue
            errors[name] = repr(exc)
            print(f"[run_all] {name} FAILED: {exc}", flush=True)
            traceback.print_exc()
    dump_path = Path(config.STATS_DUMP)
    with open(dump_path, "w") as fh:
        json.dump({"results": _coerce(results), "errors": errors}, fh, indent=2)
    print(f"[run_all] wrote stats to {dump_path}")
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
