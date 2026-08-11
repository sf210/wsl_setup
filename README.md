# wsl_setup

Bootstrap script for a fresh Ubuntu-on-WSL work machine: tmux, uv, a pinned
Neovim release, Claude Code, and starter `.bashrc`/`.bash_aliases`.

## Bootstrap a machine

```bash
./scripts/setup.sh
```

Installs (skipping anything already present, safe to re-run):

- `tmux`, plus a handful of apt prerequisites (`curl`, `git`, `build-essential`, ...)
- [`uv`](https://docs.astral.sh/uv/) via the official installer
- Neovim, pinned to the version set in `NVIM_VERSION` at the top of the script
  (currently `0.12.4` — Ubuntu's apt package lags upstream)
- [Claude Code](https://claude.ai/download) via the official native installer
- `~/.anthropic.env` — a `chmod 600` placeholder for your `ANTHROPIC_API_KEY`.
  Get a key at <https://console.anthropic.com/settings/keys>, then edit that
  file to paste it in. It's sourced automatically from `~/.bashrc`; the script
  never overwrites it once it exists.
- A managed block in `~/.bashrc` and `~/.bash_aliases` (marked with
  `# >>> wsl_setup managed >>>` / `# <<< ... <<<`) with PATH setup, `EDITOR=nvim`,
  a `tm [name]` tmux session helper, and a few novice-friendly aliases
  (`ll`, `vim` -> `nvim`, `reload`, ...). Re-running the script replaces only
  that block — anything else you add to those files is left alone.

Run it directly on the host, not through `./sbx` below — the sandbox gives an
empty `$HOME` and can't touch real dotfiles.

## Python project setup

```bash
cd /home/aiwork/projects/wsl_setup
uv sync                 # creates ./.venv and installs deps
cp .env.example .env    # then fill in secrets
```

## Usage

```bash
uv run wsl_setup
# or: uv run python -m wsl_setup
```

## Sandbox

`./sbx` runs a command inside bubblewrap with only this project
visible read-write, the system tree read-only, and an otherwise empty
`$HOME`. Everything else on the filesystem is absent.

```bash
./sbx                 # shell inside the sandbox
./sbx claude          # Claude Code, confined to this project
./sbx make check
./sbx --no-net uv run pytest
```

To expose a path from outside the project, add it to
`.sandbox/binds.conf`:

```
ro  /home/dad/data/prices.db
ro  /home/dad/data/prices.db  external/prices.db
rw  ~/shared/scratch
```

Machine-specific paths belong in `.sandbox/binds.local.conf`, which is
git-ignored.

## Layout

| Path | Purpose |
|------|---------|
| `src/wsl_setup/` | Library / application code |
| `tests/` | pytest suite |
| `notebooks/` | Exploratory notebooks (not import paths) |
| `scripts/setup.sh` | Bootstraps a fresh Ubuntu-on-WSL machine (tmux, uv, Neovim, Claude Code, dotfiles) |
| `scripts/` | One-off and operational scripts |
| `data/` | raw -> interim -> processed (git-ignored) |
| `docs/` | Design notes and documentation |
| `sbx` | Bubblewrap launcher |
| `.sandbox/binds.conf` | Paths exposed inside the sandbox |
| `external/` | Symlinks to host paths (git-ignored) |
