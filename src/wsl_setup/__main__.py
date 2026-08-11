"""Command-line entry point for wsl_setup."""

from __future__ import annotations

import argparse


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="wsl_setup")
    parser.parse_args(argv)
    print("wsl_setup is alive")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
