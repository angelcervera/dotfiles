#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

omz_dir="${DF_OMZ_DIR:-$HOME/.oh-my-zsh}"
custom_plugins_dir="${DF_OMZ_CUSTOM_DIR:-$omz_dir/custom/plugins}"

if [[ ! -d "$omz_dir" ]]; then
  log ERROR "Oh My Zsh directory not found: $omz_dir"
  log ERROR 'Run workstation/scripts/install-omz.sh first'
  exit 1
fi

mkdir -p "$custom_plugins_dir"

install_or_update_plugin() {
  local name="$1"
  local repo_url="$2"
  local plugin_dir="$custom_plugins_dir/$name"

  if [[ ! -d "$plugin_dir" ]]; then
    log INFO "Cloning plugin: $name"
    git clone --depth 1 "$repo_url" "$plugin_dir"
    return 0
  fi

  if [[ -d "$plugin_dir/.git" ]]; then
    log INFO "Updating plugin: $name"
    if ! git -C "$plugin_dir" pull --ff-only; then
      log WARN "Failed to update plugin: $name"
    fi
    return 0
  fi

  log WARN "Plugin directory exists but is not a git repo, skipping: $plugin_dir"
}

install_or_update_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_or_update_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

log INFO 'Oh My Zsh plugin installation completed'
