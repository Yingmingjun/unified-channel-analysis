"""Central configuration: data paths, output locations, figure style.

Override DATA_ROOT via env var CHANNEL_DATA_ROOT. Individual file paths can be
overridden by editing DATA_PATHS in-place before calling the loader.
"""
from __future__ import annotations

import os
from pathlib import Path

# --- Input data (read-only; not shipped with the repo) -----------------------
DATA_ROOT = Path(
    os.environ.get(
        "CHANNEL_DATA_ROOT",
        r"D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare",
    )
)

# Per-institution point-data tables. These are the canonical inputs.
DATA_PATHS: dict[str, Path] = {
    # NYU original point-data (N1), produced by NYU's native pipeline
    "n1_142_xlsx": DATA_ROOT / "USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi.xlsx",
    "n1_7_xlsx": DATA_ROOT / "USC/USCprocessNYUdata/OriginalNYU_pointData/7_UMi.xlsx",
    # USC original point-data (U1), produced by USC's native pipeline
    "u1_142_los_csv": DATA_ROOT
    / "NYU/NYUprocessUSCdata/OriginalUSC-PointData/usc_microcellular_LOS_metrics.csv",
    "u1_142_nlos_csv": DATA_ROOT
    / "NYU/NYUprocessUSCdata/OriginalUSC-PointData/usc_microcellular_NLOS_metrics.csv",
    "u1_7_los_csv": DATA_ROOT
    / "NYU/NYUprocessUSCdata/OriginalUSC-PointData/usc_microcellular_LOS_metrics7.csv",
    "u1_7_nlos_csv": DATA_ROOT
    / "NYU/NYUprocessUSCdata/OriginalUSC-PointData/usc_microcellular_NLOS_metrics7.csv",
    # Cross-processed tables (N3, U3): partner-applied processing
    "n3_142_xlsx": DATA_ROOT / "USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi_N3.xlsx",
    "n3_7_xlsx": DATA_ROOT / "USC/USCprocessNYUdata/OriginalNYU_pointData/7_UMi_N3.xlsx",
    "u3_142_xlsx": DATA_ROOT
    / "NYU/NYUprocessUSCdata/OriginalUSC-PointData/142_UMi_U3.xlsx",
    "u3_7_xlsx": DATA_ROOT / "NYU/NYUprocessUSCdata/OriginalUSC-PointData/7_UMi_U3.xlsx",
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
