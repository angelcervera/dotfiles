#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

omz_dir="${DF_OMZ_DIR:-$HOME/.oh-my-zsh}"

if [[ -d "$omz_dir" ]]; then
  log INFO "Oh My Zsh already installed at: $omz_dir"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  log ERROR 'curl is required to install Oh My Zsh'
  exit 1
fi

log INFO 'Installing Oh My Zsh (unattended)'
RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [[ ! -d "$omz_dir" ]]; then
  log ERROR 'Oh My Zsh install did not create expected directory'
  exit 1
fi

log INFO 'Oh My Zsh installation completed'
