#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

if [[ ! -f "$repo_root/bootstrap.sh" || ! -d "$repo_root/zsh" || ! -d "$repo_root/alacritty" ]]; then
  log ERROR "Refusing to run from unexpected location: $repo_root"
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  log ERROR 'stow is required but not installed'
  exit 1
fi

if [[ "${DF_SKIP_STOW:-0}" == "1" ]]; then
  log WARN 'Skipping stow because DF_SKIP_STOW=1'
  exit 0
fi

mkdir -p "$HOME/.config"

declare -a cmd=(stow --dir "$repo_root" --target "$HOME")
declare -a packages=(zsh alacritty)

if [[ "${DF_STOW_DRY_RUN:-0}" == "1" ]]; then
  cmd+=(--simulate --verbose=2)
fi

cmd+=(--restow "${packages[@]}")

log INFO "Running: ${cmd[*]}"
"${cmd[@]}"

log INFO 'Stow apply completed'
