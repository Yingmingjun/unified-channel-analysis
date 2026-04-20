"""Compare Processing*/Results CSVs directly against main_final.tex Table VI and VII."""
from __future__ import annotations
import numpy as np
import pandas as pd

pd.set_option("display.width", 220)

BASE = "D:/NYU-USC/Cross-Processing"
PATHS = {
    "NYU_142": f"{BASE}/ProcessingNYU142GHzData/Results/NYU142GHz_Method_Comparison_Results.csv",
    "NYU_7":   f"{BASE}/ProcessingNYU7GHzData/Results/NYU7GHz_Method_Comparison_Results.csv",
    "USC_145": f"{BASE}/ProcessingUSC145GHzData/Results/USC145GHz_Full_Results.csv",
    "USC_7":   f"{BASE}/ProcessingUSC7GHzData/Results/USC7GHz_NewData_Results.csv",
}

# Paper Table VII values from main_final.tex
# (PLE, sigma_SF, PLE_CFI, DS_mean, DS_CFI, ASA_mean, ASA_CFI, ASD_mean, ASD_CFI)
PAPER_T7 = {
    ("142_NYU", "LOS"):   (1.96, 2.63, 0.16, 15.77, 34.62, 6.27, 9.35, 5.13, 3.06),
    ("142_NYU", "NLOS"):  (2.92, 8.28, 0.54, 35.27, 41.77, 45.97, 69.40, 8.95, 10.66),
    ("145_USC", "LOS"):   (1.90, 0.86, 0.05, 26.57, 26.77, 15.74, 6.54, 10.98, 1.73),
    ("145_USC", "NLOS"):  (2.84, 6.00, 0.37, 31.88, 28.67, 31.10, 19.74, 21.60, 11.62),
    ("subTHz",  "LOS"):   (1.93, 2.09, 0.09, 24.29, 27.14, 11.09, 6.80, 8.03, 3.84),
    ("subTHz",  "NLOS"):  (2.88, 7.18, 0.34, 34.72, 27.19, 36.56, 26.42, 16.51, 11.02),
    ("7_NYU",   "LOS"):   (1.79, 2.56, 0.19, 67.55, 97.97, 25.97, 25.95, 37.98, 40.71),
    ("7_NYU",   "NLOS"):  (2.56, 6.51, 0.42, 129.79, 184.38, 32.02, 20.40, 40.76, 30.88),
    ("7_USC",   "LOS"):   (1.92, 1.42, 0.12, 14.63, 21.06, 10.48, 6.96, 5.87, 0.91),
    ("7_USC",   "NLOS"):  (2.62, 7.33, 0.37, 29.00, 55.32, 12.60, 4.89, 12.23, 3.00),
    ("7_pooled","LOS"):   (1.85, 2.44, 0.13, 49.90, 87.45, 18.10, 9.09, 21.57, 13.79),
    ("7_pooled","NLOS"):  (2.59, 6.96, 0.26, 68.40, 70.19, 22.53, 6.91, 26.87, 10.17),
}

PAPER_T6 = {
    # (band, metric): (USC_data_NYUthr, USC_data_USCthr, NYU_data_USCthr, NYU_data_NYUthr)
    ("142",  "PL"):  (3.39, 3.01, 14.24, 1.50),
    ("142",  "DS"):  (61.63, 4.71, 46.13, 18.60),
    ("142",  "ASA"): (6.12, 0.00, 8.62, 0.00),
    ("142",  "ASD"): (2.01, 0.00, 4.16, 0.00),
    ("6.75", "PL"):  (6.20, 6.19, 3.30, 3.68),
    ("6.75", "DS"):  (39.47, 7.21, 28.17, 14.79),
    ("6.75", "ASA"): (7.44, 0.00, 17.52, 0.00),
    ("6.75", "ASD"): (3.78, 0.00, 38.06, 0.00),
}


def fspl_1m(f_ghz: float) -> float:
    c = 299_792_458.0
    lam = c / (f_ghz * 1e9)
    return 20.0 * np.log10(4.0 * np.pi / lam)


def ci_fit(d, pl, freq_ghz, nboot=2000, seed=0):
    d = np.asarray(d, dtype=float)
    pl = np.asarray(pl, dtype=float)
    m = np.isfinite(d) & np.isfinite(pl) & (d > 0)
    d = d[m]; pl = pl[m]
    if len(d) < 2:
        return np.nan, np.nan, np.nan
    fspl = fspl_1m(freq_ghz)
    x = 10.0 * np.log10(d)
    y = pl - fspl
    ple = float((x @ y) / (x @ x))
    sigma = float(np.sqrt(np.mean((y - ple * x) ** 2)))
    rng = np.random.default_rng(seed)
    idx = rng.integers(0, len(d), size=(nboot, len(d)))
    xb = x[idx]; yb = y[idx]
    n_rep = (xb * yb).sum(1) / (xb * xb).sum(1)
    lo, hi = np.quantile(n_rep, [0.025, 0.975])
    return ple, sigma, float(hi - lo)


def lognormal_mean(x):
    x = np.asarray(x, dtype=float)
    x = x[np.isfinite(x) & (x > 0)]
    if len(x) == 0:
        return np.nan
    lx = np.log10(x)
    ln10 = np.log(10.0)
    return float(np.exp(lx.mean() * ln10 + 0.5 * (lx.std(ddof=0) * ln10) ** 2))


def pick_col(df, method, metric):
    cols = df.columns
    if method == "NYU":
        candidates = {
            "PL":  ["PL_NYU_SUM_dB", "NYUthr_PL_SUM_dB", "PL_NYU_dB"],
            "DS":  ["DS_NYU_SUM_ns", "NYUthr_DS_SUM_ns", "DS_NYU_ns"],
            "ASA": ["ASA_NYU_10dB", "NYUthr_ASA_N10"],
            "ASD": ["ASD_NYU_10dB", "NYUthr_ASD_N10"],
        }
    else:
        candidates = {
            "PL":  ["PL_USC_perDelayMax_dB", "NYUthr_PL_pDM_dB", "PL_USC_dB"],
            "DS":  ["DS_USC_perDelayMax_ns", "NYUthr_DS_pDM_ns", "DS_USC_ns"],
            "ASA": ["ASA_USC", "NYUthr_ASA_U"],
            "ASD": ["ASD_USC", "NYUthr_ASD_U"],
        }
    for c in candidates[metric]:
        if c in cols:
            return df[c].astype(float)
    raise KeyError(f"no {method}-{metric} column in {list(cols)}")


def tag(v, p, cfi_col=False):
    if not np.isfinite(v) or not np.isfinite(p):
        return "--"
    d = abs(v - p)
    r = d / max(abs(p), 1e-9)
    tight_thresh = 0.15 if cfi_col else 0.02
    if d < 0.05 or r < tight_thresh:
        return "T"
    if r < 0.30:
        return "C"
    return "M"


def main():
    dfs = {k: pd.read_csv(p) for k, p in PATHS.items()}
    # Stamp distances onto NYU_142 from N1 xlsx (CSV doesn't have distances)
    try:
        n1 = pd.read_excel(
            "D:/unified-channel-analysis/data/point_data/N1_142_UMi.xlsx",
            sheet_name="FinalTable",
            header=0,
        )
        n1["TX"] = n1["TX"].ffill()
        n1 = n1[pd.to_numeric(n1["PL"], errors="coerce").notna()]
        dist_map = {
            f'T{int(str(r.TX).replace("TX",""))}-R{int(str(r.RX).replace("RX",""))}': r["TR Sep"]
            for _, r in n1.iterrows()
        }
        dfs["NYU_142"]["Distance_m"] = dfs["NYU_142"]["TX_RX_ID"].map(dist_map)
    except Exception as e:
        print(f"Distance map warning: {e}")

    print("=" * 115)
    print(" TABLE VII — Processing*/Results/*.csv vs paper main_final.tex")
    print(" Format: computed / paper   [T=within 2% (15% for CFI), C=within 30%, M=miss]")
    print("=" * 115)
    header = f'{"Row":<24}{"n":>3}  {"PLE":<17}{"sigma":<15}{"PLE_CFI":<15}{"DS_mean":<20}{"ASA_mean":<17}{"ASD_mean":<15}'
    print(header)
    print("-" * 115)

    # Per-institution
    configs = [
        ("142_NYU",  "NYU_142", 142.0, "NYU", "142 GHz NYU"),
        ("145_USC",  "USC_145", 145.5, "USC", "145 GHz USC"),
        ("7_NYU",    "NYU_7",     6.75, "NYU", "6.75 GHz NYU"),
        ("7_USC",    "USC_7",     6.75, "USC", "6.75 GHz USC"),
    ]
    results = []
    for key, dset, freq, method, label in configs:
        df = dfs[dset]
        env_col = "Environment" if "Environment" in df.columns else "Env"
        dff = df.copy()
        dff[env_col] = dff[env_col].replace({"OLOS": "NLOS"})
        for loc in ("LOS", "NLOS"):
            sub = dff[dff[env_col] == loc]
            if len(sub) < 2:
                continue
            pl = pick_col(sub, method, "PL").values
            ds = pick_col(sub, method, "DS").values
            asa = pick_col(sub, method, "ASA").values
            asd = pick_col(sub, method, "ASD").values
            d = sub["Distance_m"].values if "Distance_m" in sub.columns else np.full(len(sub), np.nan)
            ple, sigma, cfi = ci_fit(d, pl, freq)
            ds_m = lognormal_mean(ds)
            asa_m = lognormal_mean(asa)
            asd_m = lognormal_mean(asd)
            p = PAPER_T7[(key, loc)]
            row = (label, loc, len(sub), ple, sigma, cfi, ds_m, asa_m, asd_m, p)
            results.append(row)
            print(
                f'{label+" "+loc:<24}{len(sub):>3}  '
                f'{ple:5.2f}/{p[0]:5.2f}{tag(ple,p[0]):<4}'
                f'{sigma:5.2f}/{p[1]:5.2f}{tag(sigma,p[1]):<4}'
                f'{cfi:5.2f}/{p[2]:5.2f}{tag(cfi,p[2],True):<4}'
                f'{ds_m:7.2f}/{p[3]:7.2f}{tag(ds_m,p[3]):<4}'
                f'{asa_m:5.2f}/{p[5]:5.2f}{tag(asa_m,p[5]):<4}'
                f'{asd_m:5.2f}/{p[7]:5.2f}{tag(asd_m,p[7]):<4}'
            )

    # Pooled
    for key, dsets, freq, label in [
        ("subTHz",  [("NYU_142","NYU"), ("USC_145","USC")], 143.75, "sub-THz Pooled"),
        ("7_pooled",[("NYU_7","NYU"), ("USC_7","USC")],       6.75, "6.75 GHz Pooled"),
    ]:
        for loc in ("LOS", "NLOS"):
            all_pl=[]; all_ds=[]; all_asa=[]; all_asd=[]; all_d=[]
            for dset, method in dsets:
                df = dfs[dset]
                env_col = "Environment" if "Environment" in df.columns else "Env"
                sub = df[df[env_col].replace({"OLOS":"NLOS"}) == loc]
                if len(sub) == 0: continue
                all_pl.append(pick_col(sub,method,"PL").values)
                all_ds.append(pick_col(sub,method,"DS").values)
                all_asa.append(pick_col(sub,method,"ASA").values)
                all_asd.append(pick_col(sub,method,"ASD").values)
                all_d.append(sub["Distance_m"].values if "Distance_m" in sub.columns else np.full(len(sub), np.nan))
            if not all_pl: continue
            pl = np.concatenate(all_pl); ds = np.concatenate(all_ds)
            asa = np.concatenate(all_asa); asd = np.concatenate(all_asd); d = np.concatenate(all_d)
            ple, sigma, cfi = ci_fit(d, pl, freq)
            ds_m = lognormal_mean(ds); asa_m = lognormal_mean(asa); asd_m = lognormal_mean(asd)
            p = PAPER_T7[(key, loc)]
            print(
                f'{label+" "+loc:<24}{len(pl):>3}  '
                f'{ple:5.2f}/{p[0]:5.2f}{tag(ple,p[0]):<4}'
                f'{sigma:5.2f}/{p[1]:5.2f}{tag(sigma,p[1]):<4}'
                f'{cfi:5.2f}/{p[2]:5.2f}{tag(cfi,p[2],True):<4}'
                f'{ds_m:7.2f}/{p[3]:7.2f}{tag(ds_m,p[3]):<4}'
                f'{asa_m:5.2f}/{p[5]:5.2f}{tag(asa_m,p[5]):<4}'
                f'{asd_m:5.2f}/{p[7]:5.2f}{tag(asd_m,p[7]):<4}'
            )

    # Table VI — method comparison RMSE from CSVs directly
    print()
    print("=" * 95)
    print(" TABLE VI — method comparison RMSE computed from Processing*/Results CSVs vs paper")
    print("=" * 95)
    print(f'{"Band":<10}{"Metric":<8}{"Paper [USC-NYUt, USC-USCt, NYU-USCt, NYU-NYUt]":<55}{"Our CSV method-comparison":<30}')
    print("-" * 95)
    for band, freq_pair, dset_usc, dset_nyu in [
        ("142",  (142.0, 145.5), "USC_145", "NYU_142"),
        ("6.75", (6.75, 6.75),   "USC_7",   "NYU_7"),
    ]:
        for metric in ("PL","DS","ASA","ASD"):
            try:
                # USC-side: method comparison RMSE (PL_NYU vs PL_USC) — covers "USC-data NYU-thr vs USC-thr"
                usc = dfs[dset_usc]
                a = pick_col(usc, "NYU", metric); b = pick_col(usc, "USC", metric)
                r_usc = float(np.sqrt(np.mean((a-b)**2)))
                nyu = dfs[dset_nyu]
                a = pick_col(nyu, "NYU", metric); b = pick_col(nyu, "USC", metric)
                r_nyu = float(np.sqrt(np.mean((a-b)**2)))
            except KeyError as e:
                r_usc = r_nyu = float('nan')
            p = PAPER_T6[(band, metric)]
            print(
                f'{band:<10}{metric:<8}'
                f'{p[0]:6.2f} {p[1]:6.2f} {p[2]:6.2f} {p[3]:6.2f}'
                f'           USC_CSV_NYU-vs-USC={r_usc:.2f}   NYU_CSV_NYU-vs-USC={r_nyu:.2f}'
            )


if __name__ == "__main__":
    main()
