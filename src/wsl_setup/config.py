"""Project paths and environment configuration."""

from __future__ import annotations

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
INTERIM_DIR = DATA_DIR / "interim"
PROCESSED_DIR = DATA_DIR / "processed"


def env(name: str, default: str | None = None) -> str:
    """Read a required environment variable (see .env.example)."""
    value = os.environ.get(name, default)
    if value is None:
        raise RuntimeError(f"missing environment variable: {name}")
    return value
