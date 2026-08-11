.RECIPEPREFIX = >
.DEFAULT_GOAL := help
.PHONY: help install fmt lint typecheck test check run clean

help:  ## Show this help
> @grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install:  ## Create/refresh the project venv from pyproject.toml
> uv sync

fmt:  ## Format code
> uv run ruff format .

lint:  ## Lint (with autofix)
> uv run ruff check --fix .

typecheck:  ## Static type check
> uv run mypy

test:  ## Run the test suite
> uv run pytest

check: lint typecheck test  ## Lint + typecheck + test

run:  ## Run the package entry point
> uv run python -m wsl_setup

clean:  ## Remove caches and build artefacts
> rm -rf .pytest_cache .ruff_cache .mypy_cache dist build
> find . -name __pycache__ -type d -prune -exec rm -rf {} +
