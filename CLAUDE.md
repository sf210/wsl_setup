# wsl_setup

## Project

Bootstrap script (`scripts/setup.sh`) for a fresh Ubuntu-on-WSL work machine:
installs tmux, uv, a pinned Neovim release, and Claude Code, and writes
starter `.bashrc`/`.bash_aliases` plus an `~/.anthropic.env` slot for
`ANTHROPIC_API_KEY`. The rest of the repo is the standard project scaffold
(unused for now — the bootstrap script is a standalone bash script since it
has to install `uv` itself before any `uv run` tooling exists).

## Environment

- Python deps are managed by **uv**, in this project's own `.venv/`.
- Run things with `uv run <cmd>`; add deps with `uv add <pkg>` (dev deps: `uv add --dev <pkg>`).
- Never `pip install` into the system Python, and never reuse another project's venv.
- Secrets live in `.env` (git-ignored). `.env.example` lists the required keys with no values.

- `./sbx <cmd>` runs a command inside bubblewrap: this project read-write,
  the system tree read-only, an empty `$HOME`, nothing else visible.
- Paths outside the project are only reachable if listed in
  `.sandbox/binds.conf`. If something is missing inside the sandbox, add it
  there rather than working around it.

## Conventions

- `make fmt`, `make lint`, `make test` before committing (or just `make check`).
- Data under `data/` is never committed; only the directory layout is tracked.
