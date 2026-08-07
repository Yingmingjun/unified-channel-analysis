#!/usr/bin/env python3
"""Decide whether two datasets may be pooled, and in what form.

This is the admission procedure of the manuscript, packaged so that any
pair of organizations can run it on their own point data. It is
organization-agnostic: the two labels are whatever appears in the
institution column.

Input: one CSV, one row per TX-RX link, with these columns.

    institution   any two distinct labels
    band          any label; cells are evaluated per band
    loc_class     LOS / NLOS (or any labels; cells are evaluated per class)
    dist_m        TX-RX separation in metres
    freq_ghz      carrier frequency in GHz, for the free-space reference
    pl_db         omnidirectional path loss in dB          (optional)
    ds_ns         RMS delay spread in ns                   (optional)
    asa_deg       azimuth spread of arrival in degrees     (optional)
    asd_deg       azimuth spread of departure in degrees   (optional)

Any parameter column that is absent is skipped. Only rows with a value
for the parameter under test take part in that test.

The offset is fitted per parameter with the model the manuscript declares
for it: excess path loss carries a distance slope, delay spread is a
location shift on log10, angular spreads are location shifts in degrees.

    PL : pl - FSPL(1 m) = 10 n log10 d + beta 1[B] + eps
    DS : log10(ds)      = a + beta 1[B] + eps
    AS : as             = a + beta 1[B] + eps

Verdicts, per parameter and cell:

    pool          the CI contains zero and is no wider than the bound, so
                  a pooled model may omit the organization term
    term          the CI excludes zero: pool, but keep the term
    more-data     the CI contains zero but is wider than the bound; the
                  required per-organization link count is reported

Pooling is never precluded. The verdict fixes the defensible form.

Usage
    python poolability.py links.csv
    python poolability.py links.csv --bound-pl 1.0 --bound-as 2.0 -B 200000

The default bounds are twice the replication tolerances declared in the
manuscript (path loss 0.5 dB, delay spread 5%, angular spread 1 degree).
Set them to twice your own declared tolerances.
"""

from __future__ import annotations

import argparse
import sys
import zlib

import numpy as np
import pandas as pd

C_LIGHT = 299_792_458.0

PARAMS = [
    # name, column,   model,   default bound, unit
    ("PL", "pl_db", "slope", 1.0, "dB"),
    ("DS", "ds_ns", "log10", 0.0414, "decades"),
    ("ASA", "asa_deg", "linear", 2.0, "deg"),
    ("ASD", "asd_deg", "linear", 2.0, "deg"),
]


def fspl_1m_db(f_ghz):
    return 20.0 * np.log10(4.0 * np.pi * np.asarray(f_ghz, float) * 1e9 / C_LIGHT)


def rng_for(key: str, seed: int) -> np.random.Generator:
    """Per-cell stream, so a verdict does not depend on iteration order."""
    return np.random.default_rng([seed, zlib.crc32(key.encode())])


def _boot(X, y, rng, B, chunk=25_000):
    """Bootstrap the last coefficient of a two-column design.

    Resamples drawing links from only one organization are discarded: the
    indicator is then constant, so such a replicate carries no information
    about an inter-organization offset.
    """
    m = len(y)
    keep, drawn = [], 0
    while drawn < B:
        k = min(chunk, B - drawn)
        i = rng.integers(0, m, (k, m))
        Xb, yb = X[i], y[i]
        c0, c1 = Xb[:, :, 0], Xb[:, :, 1]
        a = np.einsum("bm,bm->b", c0, c0)
        b = np.einsum("bm,bm->b", c0, c1)
        d = np.einsum("bm,bm->b", c1, c1)
        t0 = np.einsum("bm,bm->b", c0, yb)
        t1 = np.einsum("bm,bm->b", c1, yb)
        det = a * d - b * b
        ok = np.abs(det) > 1e-9 * np.maximum(a * d, 1.0)
        keep.append((-b[ok] * t0[ok] + a[ok] * t1[ok]) / det[ok])
        drawn += k
    return np.concatenate(keep)


def design(sub, col, model, inst_a):
    """Two-column design; the second column flags the second organization."""
    z = (sub.institution != inst_a).to_numpy(float)
    if model == "slope":
        y = sub[col].to_numpy(float) - fspl_1m_db(sub.freq_ghz)
        x = 10.0 * np.log10(sub.dist_m.to_numpy(float))
    else:
        v = sub[col].to_numpy(float)
        y = np.log10(v) if model == "log10" else v
        x = np.ones(len(sub))
    return np.column_stack([x, z]), y


def required_n(sigma, bound):
    return int(np.ceil(2.0 * (1.96 * sigma / bound) ** 2))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv")
    ap.add_argument("-B", type=int, default=200_000,
                    help="bootstrap replicates (default 200000)")
    ap.add_argument("--seed", type=int, default=20260801)
    ap.add_argument("--bound-pl", type=float, default=1.0)
    ap.add_argument("--bound-ds", type=float, default=0.0414)
    ap.add_argument("--bound-as", type=float, default=2.0)
    ap.add_argument("--min-links", type=int, default=6,
                    help="skip a cell with fewer links than this")
    ap.add_argument("--ds-floor", type=float, default=0.0,
                    help="drop links whose delay spread is below this, in ns, "
                         "from the DS test only; set it to one delay bin at "
                         "your sounding bandwidth (the manuscript uses 2)")
    ap.add_argument("--out", help="write the verdict table to this CSV")
    a = ap.parse_args()

    bounds = {"PL": a.bound_pl, "DS": a.bound_ds,
              "ASA": a.bound_as, "ASD": a.bound_as}

    try:
        df = pd.read_csv(a.csv)
    except FileNotFoundError:
        print(f"error: no such file: {a.csv}", file=sys.stderr)
        return 2
    except Exception as exc:                       # malformed CSV
        print(f"error: could not read {a.csv}: {exc}", file=sys.stderr)
        return 2
    need = {"institution", "dist_m", "freq_ghz"}
    missing = need - set(df.columns)
    if missing:
        print(f"error: {a.csv} is missing required column(s): "
              f"{', '.join(sorted(missing))}", file=sys.stderr)
        return 2

    insts = sorted(df.institution.dropna().unique())
    if len(insts) != 2:
        print(f"error: expected exactly two organizations, found "
              f"{len(insts)}: {insts}", file=sys.stderr)
        return 2
    inst_a, inst_b = insts

    for opt in ("band", "loc_class"):
        if opt not in df.columns:
            df[opt] = "all"

    print(f"Organizations : {inst_a}  vs  {inst_b}")
    print(f"Links         : {len(df)}")
    if a.ds_floor > 0:
        print(f"DS floor      : {a.ds_floor:g} ns, applied to the DS test only")
    print(f"Bootstrap     : B = {a.B}, seed {a.seed}, per-cell stream\n")
    print(f"{'param':5s} {'band':10s} {'class':6s} {'n':>4s} {'beta':>9s} "
          f"{'95% CI':>20s} {'half':>7s}  verdict")
    print("-" * 84)

    rows = []
    for name, col, model, _, unit in PARAMS:
        if col not in df.columns:
            continue
        bound = bounds[name]
        for (band, cls), g in df.groupby(["band", "loc_class"], sort=False):
            sub = g.dropna(subset=[col, "dist_m", "freq_ghz"])
            sub = sub[sub[col] > 0] if model == "log10" else sub
            if name == "DS" and a.ds_floor > 0:
                sub = sub[sub[col] >= a.ds_floor]
            if (sub.institution == inst_a).sum() < 3 or \
               (sub.institution != inst_a).sum() < 3 or len(sub) < a.min_links:
                continue
            X, y = design(sub, col, model, inst_a)
            coef, *_ = np.linalg.lstsq(X, y, rcond=None)
            beta = float(coef[-1])
            reps = _boot(X, y, rng_for(f"{name}|{band}|{cls}", a.seed), a.B)
            lo, hi = np.percentile(reps, [2.5, 97.5])
            half = (hi - lo) / 2.0
            if lo > 0 or hi < 0:
                verdict, note = "term", ""
            elif half <= bound:
                verdict, note = "pool", ""
            else:
                res = y - X @ coef
                verdict = "more-data"
                note = f"  need ~{required_n(res.std(ddof=1), bound)}/organization"
            print(f"{name:5s} {str(band)[:10]:10s} {str(cls)[:6]:6s} {len(y):4d} "
                  f"{beta:+9.3f} {f'[{lo:+.3f},{hi:+.3f}]':>20s} {half:7.3f}  "
                  f"{verdict}{note}")
            rows.append(dict(param=name, band=band, loc_class=cls, n=len(y),
                             beta=round(beta, 4), lo=round(lo, 4),
                             hi=round(hi, 4), half=round(half, 4),
                             bound=bound, unit=unit, verdict=verdict))

    if not rows:
        print("no cell had enough links on both sides to test")
        return 1

    out = pd.DataFrame(rows)
    print("\nverdict counts:", dict(out.verdict.value_counts()))
    if (out.verdict == "pool").any():
        print("cells certified for term-free pooling:",
              int((out.verdict == "pool").sum()))
    else:
        print("no cell certifies term-free pooling at these sample sizes; "
              "pool with an organization term.")
    if a.out:
        out.to_csv(a.out, index=False)
        print("written to", a.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
