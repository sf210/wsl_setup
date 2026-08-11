#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu-on-WSL work machine: tmux, uv, Neovim (pinned),
# Claude Code, an Anthropic API key slot, and starter .bashrc/.bash_aliases.
#
# Run this directly on the host - NOT through ./sbx, which gives an empty
# $HOME and can't touch real dotfiles. Safe to re-run: every step skips
# itself if already satisfied.
#
# Usage: ./scripts/setup.sh

set -euo pipefail

NVIM_VERSION="0.12.4"

log() { printf '==> %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Sanity check: this is meant for Ubuntu on WSL, but still works on plain
# Ubuntu, so only warn if WSL isn't detected.
# ---------------------------------------------------------------------------
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  log "Warning: WSL not detected (/proc/version has no 'microsoft'). Continuing anyway."
fi

mkdir -p "$HOME/.local/bin"

# ---------------------------------------------------------------------------
# apt prerequisites + tmux
# ---------------------------------------------------------------------------
apt_missing=()
for pkg in tmux curl ca-certificates git build-essential unzip; do
  dpkg -s "$pkg" >/dev/null 2>&1 || apt_missing+=("$pkg")
done

if [ "${#apt_missing[@]}" -gt 0 ]; then
  log "Installing apt packages: ${apt_missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${apt_missing[@]}"
else
  log "tmux and prerequisites already installed, skipping apt"
fi

# ---------------------------------------------------------------------------
# uv
# ---------------------------------------------------------------------------
if have uv; then
  log "uv already installed ($(uv --version)), skipping"
else
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ---------------------------------------------------------------------------
# Neovim, pinned to $NVIM_VERSION (Ubuntu's apt package lags upstream)
# ---------------------------------------------------------------------------
if have nvim && nvim --version | head -1 | grep -q "NVIM v${NVIM_VERSION}$"; then
  log "Neovim ${NVIM_VERSION} already installed, skipping"
else
  log "Installing Neovim ${NVIM_VERSION}"
  case "$(uname -m)" in
    x86_64) nvim_arch="x86_64" ;;
    aarch64) nvim_arch="arm64" ;;
    *)
      echo "Unsupported architecture for pinned Neovim install: $(uname -m)" >&2
      exit 1
      ;;
  esac

  nvim_tmp="$(mktemp -d)"
  trap 'rm -rf "$nvim_tmp"' EXIT

  base_url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}"
  tarball=""
  for asset in "nvim-linux-${nvim_arch}.tar.gz" "nvim-linux64.tar.gz"; do
    if curl -fsSL -o "$nvim_tmp/nvim.tar.gz" "$base_url/$asset"; then
      tarball="$asset"
      break
    fi
  done
  if [ -z "$tarball" ]; then
    echo "Could not download a Neovim ${NVIM_VERSION} release asset for arch ${nvim_arch}" >&2
    exit 1
  fi

  if curl -fsSL -o "$nvim_tmp/nvim.tar.gz.sha256sum" "$base_url/${tarball}.sha256sum"; then
    (cd "$nvim_tmp" && sha256sum -c <(awk -v f="nvim.tar.gz" '{print $1"  "f}' "nvim.tar.gz.sha256sum"))
  else
    log "No checksum file published for ${tarball}, skipping verification"
  fi

  install_dir="$HOME/.local/opt/nvim-${NVIM_VERSION}"
  rm -rf "$install_dir"
  mkdir -p "$install_dir"
  tar -xzf "$nvim_tmp/nvim.tar.gz" --strip-components=1 -C "$install_dir"
  ln -sf "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"

  rm -rf "$nvim_tmp"
  trap - EXIT
fi

# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
if have claude; then
  log "Claude Code already installed ($(claude --version)), skipping"
else
  log "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi

# ---------------------------------------------------------------------------
# Anthropic API key slot
# ---------------------------------------------------------------------------
anthropic_env="$HOME/.anthropic.env"
if [ -f "$anthropic_env" ]; then
  log "$anthropic_env already exists, leaving it alone"
else
  log "Creating $anthropic_env (edit it to add your real key)"
  cat > "$anthropic_env" <<'EOF'
# Anthropic API key - get one at https://console.anthropic.com/settings/keys
# This file is sourced from ~/.bashrc. Keep it out of any git repo.
export ANTHROPIC_API_KEY="sk-ant-..."
EOF
  chmod 600 "$anthropic_env"
fi

# ---------------------------------------------------------------------------
# Managed dotfile blocks - idempotent, marker-delimited, never touches
# anything outside the markers.
# ---------------------------------------------------------------------------
write_managed_block() {
  local file="$1" content="$2"
  local start="# >>> wsl_setup managed >>>"
  local end="# <<< wsl_setup managed <<<"

  touch "$file"

  if grep -qF "$start" "$file"; then
    local tmp
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" '
      $0 == start { skip = 1; next }
      $0 == end   { skip = 0; next }
      !skip       { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
  fi

  {
    echo "$start"
    printf '%s\n' "$content"
    echo "$end"
  } >> "$file"
}

log "Updating $HOME/.bashrc"
write_managed_block "$HOME/.bashrc" '# Added by wsl_setup/scripts/setup.sh - safe to re-run, edit outside the markers.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"
[ -f "$HOME/.anthropic.env" ] && source "$HOME/.anthropic.env"
export EDITOR=nvim
export VISUAL=nvim
command -v uv >/dev/null 2>&1 && eval "$(uv generate-shell-completion bash)"'

log "Updating $HOME/.bash_aliases"
write_managed_block "$HOME/.bash_aliases" '# Added by wsl_setup/scripts/setup.sh - safe to re-run, edit outside the markers.

# Listing
alias ll="ls -alF"
alias la="ls -A"
alias ..="cd .."

# Use Neovim everywhere vim is typed
alias vim="nvim"
alias vi="nvim"

# tm [name]: create-or-attach a named tmux session (default: main).
# Lets you reconnect to the same session after a dropped WSL/SSH connection.
tm() {
  tmux new-session -A -s "${1:-main}"
}

# Dotfile shortcuts
alias reload="source ~/.bashrc"
alias bashrc="nvim ~/.bashrc && source ~/.bashrc"
alias aliases="nvim ~/.bash_aliases && source ~/.bashrc"'

log "Done."
cat <<EOF

Next steps:
  1. Run: source ~/.bashrc   (or open a new shell)
  2. Edit ~/.anthropic.env and paste your real Anthropic API key.
  3. Run: claude   to confirm Claude Code picks up ANTHROPIC_API_KEY.
EOF
