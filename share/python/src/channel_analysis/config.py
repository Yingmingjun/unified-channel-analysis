"""Central configuration: data paths, output locations, figure style.

Override DATA_ROOT via env var CHANNEL_DATA_ROOT. Individual file paths can be
overridden by editing DATA_PATHS in-place before calling the loader.
"""
from __future__ import annotations

import os
from pathlib import Path

# --- Input data (point-data tables bundled under data/point_data/) -----------
# The point-data xlsx files are the multi-institution interchange format and
# are shipped with the repo under data/point_data/. Set CHANNEL_DATA_ROOT to
# a folder of your own if you want to override (must contain the same file
# names; see data/point_data/README.md).
_DEFAULT_DATA_ROOT = Path(__file__).resolve().parents[3] / "data" / "point_data"
DATA_ROOT = Path(os.environ.get("CHANNEL_DATA_ROOT", _DEFAULT_DATA_ROOT))

DATA_PATHS: dict[str, Path] = {
    # Authoritative per-TX-RX result CSVs (source: D:/NYU-USC/Cross-Processing/
    # ProcessingXXXGHzData/Results/). These are the exact files the paper-
    # figure MATLAB scripts read.
    "nyu_142_csv": DATA_ROOT / "NYU142GHz_Method_Comparison_Results.csv",
    "nyu_7_csv":   DATA_ROOT / "NYU7GHz_Method_Comparison_Results.csv",
    "usc_145_csv": DATA_ROOT / "USC145GHz_Full_Results.csv",
    "usc_7_csv":   DATA_ROOT / "USC7GHz_NewData_Results.csv",
    # Legacy two-row-header xlsx point-data tables (kept for the Table 4/8-11
    # dumps and for MATLAB's load_point_data backwards-compat).
    "n3_142_xlsx": DATA_ROOT / "N3_142_UMi.xlsx",
    "n3_7_xlsx":   DATA_ROOT / "N3_7_UMi.xlsx",
    "u3_142_xlsx": DATA_ROOT / "U3_142_UMi.xlsx",
    "u3_7_xlsx":   DATA_ROOT / "U3_7_UMi.xlsx",
    "n1_142_xlsx": DATA_ROOT / "N1_142_UMi.xlsx",
    "n1_7_xlsx":   DATA_ROOT / "N1_7_UMi.xlsx",
}

# --- Output ------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[3]   # D:/unified-channel-analysis
FIGURE_DIR = REPO_ROOT / "figures" / "python"
STATS_DUMP = FIGURE_DIR / "stats_dump.json"

STYLE_PATH = Path(__file__).parent / "styles" / "paper.mplstyle"

# --- Analysis constants ------------------------------------------------------
D0_METERS = 1.0            # CI model free-space reference distance
CONFIDENCE = 0.95          # confidence level for all CFIs
BOOTSTRAP_ITERS = 2000     # bootstrap resamples
RNG_SEED = 0               # deterministic bootstraps

# Canonical colors (RGB tuples in [0,1], matches MATLAB codebase defaults)
COLORS = {
    "nyu": (0.00, 0.45, 0.74),
    "usc": (0.85, 0.33, 0.10),
    "pooled": (0.10, 0.15, 0.90),
    "gray": (0.20, 0.20, 0.20),
    "nyu_face": (0.60, 0.78, 0.92),
    "usc_face": (0.98, 0.78, 0.68),
}
MARKERS = {"LOS": "o", "NLOS": "s", "OLOS": "s"}


def ensure_output_dirs() -> None:
    """Create output directories if missing."""
    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
