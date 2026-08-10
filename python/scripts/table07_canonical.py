"""table07_canonical.py -- bit-exact regeneration of the revised paper's
Table VII (pooled statistics) from the canonical point-data xlsx.

Conventions (single released state, revised manuscript):
  - links/labels/values from the "orig." columns of N3_142/U3_142/N3_7/U3_7
    (identical to the released supplementary tables); OLOS -> NLOS;
  - CI path-loss fit (1 m free-space reference, no intercept, sigma ddof=0);
  - lognormal means exp(mu*ln10 + (sigma*ln10)^2/2) on log10 values (ddof=0);
  - bootstrap 95% CFIs, full width, B=2000, numpy default_rng(seed=0) per
    cell in fixed cell order (bit-exact regeneration of the published CFIs);
  - the declared 2 ns delay-resolution floor is EXECUTED for DS fits.

Usage:  python python/scripts/table07_canonical.py
Output: figures/python/table07_canonical.csv

The MATLAB counterpart (matlab/figures/table07_canonical.m) reproduces all
deterministic columns exactly; its bootstrap CFI widths differ within RNG
convention (<8%).
"""

from pathlib import Path

import numpy as np
import pandas as pd

REPO = Path(__file__).resolve().parents[2]
PD_DIR = REPO / "data" / "point_data"
OUT = REPO / "figures" / "python"
OUT.mkdir(parents=True, exist_ok=True)

C = 299_792_458.0
B_BOOT = 2000
SEED = 0
DS_FLOOR_NS = 2.0

# Order matters for bit-exact bootstrap CFIs: concat order fixes the link
# order inside pooled cells (matches the paper's generator).
FILES = [
    ("USC", "Sub-THz", 145.5, "U3_142_UMi.xlsx"),
    ("USC", "6.75 GHz", 6.75, "U3_7_UMi.xlsx"),
    ("NYU", "Sub-THz", 142.0, "N3_142_UMi.xlsx"),
    ("NYU", "6.75 GHz", 6.75, "N3_7_UMi.xlsx"),
]


def read_canonical(path):
    raw = pd.read_excel(path, header=None, sheet_name="FinalTable")
    rows = []
    cur_tx = ""
    for r in range(3, len(raw)):
        tx = raw.iat[r, 1]
        if isinstance(tx, str) and tx.strip():
            cur_tx = tx.strip()
        rx = raw.iat[r, 2]
        if not (isinstance(rx, str) and rx.strip()):
            continue
        vals = [pd.to_numeric(raw.iat[r, c], errors="coerce")
                for c in (4, 7, 10, 13, 16)]
        dist, pl, ds, asa, asd = vals
        if pd.isna(dist) or all(pd.isna(v) for v in (pl, ds, asa, asd)):
            continue  # outage row
        rows.append(dict(tx=cur_tx, rx=str(rx).strip(),
                         loc_type=str(raw.iat[r, 3]).strip().upper(),
                         dist_m=dist, pl=pl, ds=ds, asa=asa, asd=asd))
    return pd.DataFrame(rows)


def fspl_1m_db(f_ghz):
    return 20.0 * np.log10(4.0 * np.pi * np.asarray(f_ghz, float) * 1e9 / C)


def ci_fit(d, pl, f):
    x = 10.0 * np.log10(np.asarray(d, float))
    y = np.asarray(pl, float) - fspl_1m_db(f)
    n = float(np.sum(x * y) / np.sum(x * x))
    return n, float(np.std(y - n * x, ddof=0))


def ci_boot_width(d, pl, f, rng):
    d, pl, f = (np.asarray(a, float) for a in (d, pl, f))
    m = len(d)
    vals = np.empty(B_BOOT)
    for b in range(B_BOOT):
        i = rng.integers(0, m, m)
        vals[b], _ = ci_fit(d[i], pl[i], f[i])
    lo, hi = np.percentile(vals, [2.5, 97.5])
    return float(hi - lo)


def lognormal_mean(x):
    lx = np.log10(np.asarray(x, float))
    ln10 = np.log(10.0)
    return float(np.exp(lx.mean() * ln10 + 0.5 * (lx.std(ddof=0) * ln10) ** 2))


def lognormal_boot_width(x, rng):
    x = np.asarray(x, float)
    m = len(x)
    vals = np.empty(B_BOOT)
    for b in range(B_BOOT):
        vals[b] = lognormal_mean(x[rng.integers(0, m, m)])
    lo, hi = np.percentile(vals, [2.5, 97.5])
    return float(hi - lo)


def main() -> None:
    frames = []
    for inst, band, f_ghz, name in FILES:
        t = read_canonical(PD_DIR / name)
        t["institution"], t["band"], t["f_ghz"] = inst, band, f_ghz
        frames.append(t)
    df = pd.concat(frames, ignore_index=True)
    df["cls"] = df.loc_type.replace({"OLOS": "NLOS"})
    print(f"{len(df)} valid links loaded")

    rows = []
    for band in ["Sub-THz", "6.75 GHz"]:
        for dataset in ["NYU only", "USC only", "Pooled"]:
            for cls in ["LOS", "NLOS"]:
                sel = (df.band == band) & (df.cls == cls)
                if dataset != "Pooled":
                    sel &= df.institution == dataset.split()[0]
                g = df[sel]
                rng = np.random.default_rng(SEED)
                p = g.dropna(subset=["pl"])
                ple, sig = ci_fit(p.dist_m, p.pl, p.f_ghz)
                cfi = ci_boot_width(p.dist_m, p.pl, p.f_ghz, rng)
                row = dict(Band=band, Dataset=dataset, LocType=cls,
                           n_links=len(g), PLE=round(ple, 2),
                           sigma_SF_dB=round(sig, 2),
                           PLE_CFI_width=round(cfi, 2))
                for name_, col, floor in [("DS", "ds", DS_FLOOR_NS),
                                          ("ASA", "asa", 0.0),
                                          ("ASD", "asd", 0.0)]:
                    v = g[col].dropna()
                    v = v[v >= floor] if floor else v[v > 0]
                    rng2 = np.random.default_rng(SEED)
                    row[f"{name_}_mean"] = round(lognormal_mean(v), 2)
                    row[f"{name_}_CFI_width"] = round(
                        lognormal_boot_width(v, rng2), 2)
                    row[f"{name_}_n"] = len(v)
                rows.append(row)

    out = pd.DataFrame(rows)
    out.to_csv(OUT / "table07_canonical.csv", index=False)
    print(f"wrote {OUT / 'table07_canonical.csv'}")
    print(out.to_string(index=False))


if __name__ == "__main__":
    main()
