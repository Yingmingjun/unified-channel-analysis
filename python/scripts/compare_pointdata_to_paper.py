"""Compare per-location point-data tables: Processing*/Results/*.csv vs tables in
main_final.tex + main_clean.tex (N1 @ 6.75 which is commented out in main_final).

Paper tables with per-link data:
  tab:LSPs                → Partial N1 @ 142 GHz  (~27 rows in main_clean; partial in main_final)
  tab:optimized_all_columns_UMi → N1 @ 6.75 GHz (rendered in main_clean, commented in main_final)
  tab:U3_145              → Partial U3 @ 145.5 GHz
  tab:U3_7                → Partial U3 @ 6.75 GHz
  tab:N3_142              → Partial N3 @ 142 GHz
  tab:N3_7                → Partial N3 @ 6.75 GHz
"""
from __future__ import annotations
import re
import numpy as np
import pandas as pd

TEX_FINAL = "D:/Joint-Point-Data-format-USC-NYU-Journal/main_final.tex"
TEX_CLEAN = "D:/Joint-Point-Data-format-USC-NYU-Journal/main_clean.tex"

PROC = "D:/NYU-USC/Cross-Processing"


def load_tex(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def extract_table_block(tex: str, label_fragment: str) -> str:
    """Return the text between the most recent \\begin{tabular} and the matching
    \\end{tabular} that contains the given label."""
    idx = tex.find(label_fragment)
    if idx < 0:
        return ""
    bs = tex.rfind("begin{tabular}", 0, idx)
    be = tex.find("end{tabular}", idx)
    if bs < 0 or be < 0:
        return ""
    return tex[bs:be]


def parse_paper_rows(block: str):
    """Parse each line in a paper tabular block that looks like a per-TX/RX data row
    and return a list of dicts with rx, loc, dist, values[]."""
    rows = []
    for raw_line in block.split("\n"):
        line = raw_line.strip().rstrip("\\").rstrip()
        # row must contain '& RX<digits>' and LOS/NLOS/OLOS
        if "&" not in line:
            continue
        if not re.search(r"&\s*RX\d+\s*&", line):
            continue
        parts = [p.strip() for p in line.split("&")]
        rx_i = next((i for i, p in enumerate(parts) if re.match(r"^RX\d+$", p)), None)
        if rx_i is None:
            continue
        rx = parts[rx_i]
        if rx_i + 2 >= len(parts):
            continue
        loc = parts[rx_i + 1]
        if loc not in ("LOS", "NLOS", "OLOS"):
            continue
        try:
            dist = float(parts[rx_i + 2])
        except ValueError:
            continue
        rest = parts[rx_i + 3:]
        # Check for multicolumn "Outage" rows
        if "Outage" in " ".join(rest) or "multicolumn" in " ".join(rest):
            rows.append({"rx": rx, "loc": loc, "dist": dist, "outage": True, "vals": []})
            continue
        vals = []
        for p in rest:
            p = p.strip().replace("\\\\", "").strip()
            if p in ("--", ""):
                vals.append(None)
            else:
                try:
                    vals.append(float(p))
                except ValueError:
                    vals.append(None)
        rows.append({"rx": rx, "loc": loc, "dist": dist, "outage": False, "vals": vals})
    return rows


def rmse_or_diff(paper_vals, our_vals, tol=0.1):
    """Return (n, max_abs_diff, rmse, n_tight) for paired floats; NaN skipped."""
    a = np.asarray(paper_vals, dtype=float)
    b = np.asarray(our_vals, dtype=float)
    m = np.isfinite(a) & np.isfinite(b)
    if not m.any():
        return 0, np.nan, np.nan, 0
    d = np.abs(a[m] - b[m])
    return int(m.sum()), float(d.max()), float(np.sqrt(np.mean(d ** 2))), int((d < tol).sum())


def main():
    final_tex = load_tex(TEX_FINAL)
    clean_tex = load_tex(TEX_CLEAN)

    # ----- NYU 142 GHz N1 table (tab:LSPs) — in main_final.tex partial -----
    print("=" * 90)
    print(" N1 @ 142 GHz — paper table (tab:LSPs, main_final) vs NYU142GHz CSV")
    print("=" * 90)
    block_n1_142_final = extract_table_block(final_tex, "tab:LSPs")
    rows_n1_142_final = parse_paper_rows(block_n1_142_final)
    # Also check clean for full version
    block_n1_142_clean = extract_table_block(clean_tex, "tab:LSPs")
    rows_n1_142_clean = parse_paper_rows(block_n1_142_clean)
    use = rows_n1_142_clean if len(rows_n1_142_clean) > len(rows_n1_142_final) else rows_n1_142_final
    src_name = "main_clean.tex" if use is rows_n1_142_clean else "main_final.tex"
    print(f"  Source file: {src_name}   rows: {len(use)}")

    nyu142 = pd.read_csv(f"{PROC}/ProcessingNYU142GHzData/Results/NYU142GHz_Method_Comparison_Results.csv")
    # Build TX-RX lookup
    # Paper N1 @ 142 GHz columns (from tab:LSPs header): PL, Mean Dir DS, Omni DS, Mean Lobe ASA, Omni ASA, Mean Lobe ASD, Omni ASD, Mean Lobe ZSA, Omni ZSA, Mean Lobe ZSD, Omni ZSD
    # vals[] indexing: [0]=PL, [1]=MeanDirDS, [2]=OmniDS, [3]=MeanLobeASA, [4]=OmniASA, [5]=MeanLobeASD, [6]=OmniASD, [7-10]=ZSA/ZSD
    # TX assignment from multirow pattern
    tx_order_142 = ["TX1"]*9 + ["TX2"]*4 + ["TX3"]*4 + ["TX4"]*5 + ["TX5"]*4 + ["TX6"]*3  # = 29 total (with outages)
    # Trim/align — paper N1 @ 142 has 27 links (3 outages in the rendered data)

    # Compare PL from paper vs NYU142 CSV (PL_NYU_SUM_dB is the NYU-method PL)
    # Build the paper rows with TX numbering
    rx_ptr = 0
    # Just assign positionally — use_rows are in paper order
    paper_df = pd.DataFrame([{
        "rx": r["rx"], "loc": r["loc"], "dist": r["dist"],
        "outage": r["outage"],
        "pl": r["vals"][0] if r["vals"] and len(r["vals"])>0 else np.nan,
        "omni_ds": r["vals"][2] if r["vals"] and len(r["vals"])>2 else np.nan,
        "omni_asa": r["vals"][4] if r["vals"] and len(r["vals"])>4 else np.nan,
        "omni_asd": r["vals"][6] if r["vals"] and len(r["vals"])>6 else np.nan,
    } for r in use if not r["outage"]])
    if len(paper_df) == 0:
        print("  [no paper rows extracted — check regex]")
        return
    print(f"  Paper rows with data (no outage): {len(paper_df)}")

    # Assemble a key like 'T?-RX?' — need TX from position
    # TX order from main_clean.tex N1 @ 142 rendered table: TX1 (9 rows), TX2 (5), TX3 (4), TX4 (5), TX5 (4), TX6 (4) = 31 total? Actually it varies
    # Better: use DISTANCE matching to CSV's missing-distance-col problem — but NYU142 CSV has no distance, so pair by position
    # NYU142 CSV TX_RX_ID is 'T1-R1', 'T1-R14', etc. (27 rows). The paper N1 table has similar order.
    csv_keys = nyu142["TX_RX_ID"].tolist()
    print(f"  CSV rows: {len(csv_keys)}  (keys like {csv_keys[:3]})")

    # Try matching paper rows to CSV by distance + rx id pattern
    # Paper rx column is "RXn"; CSV is "T-?R-?" — need distances. Load from N1 xlsx.
    n1 = pd.read_excel(
        "D:/unified-channel-analysis/data/point_data/N1_142_UMi.xlsx",
        sheet_name="FinalTable", header=0,
    )
    n1["TX"] = n1["TX"].ffill()
    n1 = n1[pd.to_numeric(n1["PL"], errors="coerce").notna()].reset_index(drop=True)
    # Now positionally align paper_df (which follows the paper's table order) with n1 (xlsx order)
    n = min(len(paper_df), len(n1), len(nyu142))
    paper_df = paper_df.iloc[:n].reset_index(drop=True)

    # Get n1's TX-RX ID matching CSV's format
    n1["key"] = n1.apply(
        lambda r: f"T{int(str(r.TX).replace('TX',''))}-R{int(str(r.RX).replace('RX',''))}", axis=1
    )
    csv_indexed = nyu142.set_index("TX_RX_ID")

    print("\n  PL and Omni DS comparison (paper vs xlsx N1 vs CSV NYU-method):")
    print(f"  {'TX-RX':<10}{'loc':<6}{'dist':>7}  {'PL(paper)':>10} {'PL(xlsx)':>10} {'PL(CSV)':>10}     {'DS(paper)':>10} {'DS(xlsx)':>10} {'DS(CSV)':>10}")
    pl_paper_vs_xlsx=[]; pl_paper_vs_csv=[]
    ds_paper_vs_xlsx=[]; ds_paper_vs_csv=[]
    for i in range(n):
        pr = paper_df.iloc[i]
        nr = n1.iloc[i]
        ck = nr["key"]
        cr = csv_indexed.loc[ck] if ck in csv_indexed.index else None
        pl_x = nr["PL"]
        ds_x = nr["Omni DS"]
        pl_c = cr["PL_NYU_SUM_dB"] if cr is not None else np.nan
        ds_c = cr["DS_NYU_SUM_ns"] if cr is not None else np.nan
        print(f'  {ck:<10}{pr["loc"]:<6}{pr["dist"]:>7.2f}  {pr["pl"]:>10.2f} {pl_x:>10.2f} {pl_c:>10.2f}     {pr["omni_ds"]:>10.2f} {ds_x:>10.2f} {ds_c:>10.2f}')
        if np.isfinite(pr["pl"]) and np.isfinite(pl_x): pl_paper_vs_xlsx.append((pr["pl"], pl_x))
        if np.isfinite(pr["pl"]) and np.isfinite(pl_c): pl_paper_vs_csv.append((pr["pl"], pl_c))
        if np.isfinite(pr["omni_ds"]) and np.isfinite(ds_x): ds_paper_vs_xlsx.append((pr["omni_ds"], ds_x))
        if np.isfinite(pr["omni_ds"]) and np.isfinite(ds_c): ds_paper_vs_csv.append((pr["omni_ds"], ds_c))

    def summ(pairs, label, tol):
        if not pairs: return
        a = np.array([x[0] for x in pairs])
        b = np.array([x[1] for x in pairs])
        d = np.abs(a-b)
        print(f'  {label:40s} n={len(pairs)} max|d|={d.max():.3f} rmse={np.sqrt((d**2).mean()):.3f} within_{tol}={np.sum(d<tol)}')

    print()
    summ(pl_paper_vs_xlsx, 'PL paper vs xlsx N1', 0.1)
    summ(pl_paper_vs_csv,  'PL paper vs CSV PL_NYU_SUM_dB', 0.1)
    summ(ds_paper_vs_xlsx, 'DS paper vs xlsx N1 Omni DS', 1.0)
    summ(ds_paper_vs_csv,  'DS paper vs CSV DS_NYU_SUM_ns', 1.0)


if __name__ == "__main__":
    main()
