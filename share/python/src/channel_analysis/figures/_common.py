"""Shared plotting utilities for per-figure drivers."""
from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt

from .. import config


def apply_style() -> None:
    plt.style.use(str(config.STYLE_PATH))


def save(fig, stem: str) -> list[str]:
    """Save a figure as both PNG and PDF under FIGURE_DIR. Return paths."""
    config.ensure_output_dirs()
    paths = []
    for ext in ("png", "pdf"):
        p = Path(config.FIGURE_DIR) / f"{stem}.{ext}"
        fig.savefig(p, dpi=300)
        paths.append(str(p))
    plt.close(fig)
    return paths
