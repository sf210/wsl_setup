from wsl_setup import __version__
from wsl_setup.__main__ import main


def test_version() -> None:
    assert __version__


def test_main_runs() -> None:
    assert main([]) == 0
