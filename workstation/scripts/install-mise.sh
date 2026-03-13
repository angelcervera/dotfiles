#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

if command -v mise >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/mise" ]]; then
  log INFO 'mise is already installed'
  exit 0
fi

kernel="$(uname -s)"

if [[ "$kernel" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    log ERROR 'Homebrew is required to install mise on macOS'
    log ERROR 'Install Homebrew first: https://brew.sh/'
    exit 1
  fi

  log INFO 'Installing mise via Homebrew'
  brew install mise
elif [[ "$kernel" == "Linux" ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    log ERROR 'curl is required to install mise on Linux'
    exit 1
  fi

  log INFO 'Installing mise using official installer (mise.run)'
  curl https://mise.run | sh
else
  log ERROR "Unsupported operating system: $kernel"
  exit 1
fi

if command -v mise >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/mise" ]]; then
  log INFO 'mise installation completed'
else
  log WARN 'mise installation finished but binary was not found on PATH'
  log WARN 'Try reopening your shell or use ~/.local/bin/mise directly'
fi
