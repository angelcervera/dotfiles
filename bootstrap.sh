#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [minimal|full]

Profiles:
  minimal    Base shell and essential tools
  full       Minimal + full CLI tools + mise (default)

Optional env flags:
  DF_NO_SUDO=1      Skip privileged package installation
  DF_SKIP_STOW=1    Skip stow apply step
  DF_SKIP_VERIFY=1  Skip verification step
EOF
}

profile="${1:-full}"
case "$profile" in
  minimal|full) ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    log ERROR "Invalid profile: $profile"
    usage
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$script_dir"
scripts_dir="$repo_root/workstation/scripts"

if [[ ! -d "$scripts_dir" ]]; then
  log ERROR "Missing scripts directory: $scripts_dir"
  exit 1
fi

run_step() {
  local label="$1"
  local script="$2"
  shift 2

  if [[ ! -x "$script" ]]; then
    log ERROR "Script is missing or not executable: $script"
    exit 1
  fi

  log INFO "$label"
  "$script" "$@"
}

link_mise_config() {
  local src="$repo_root/workstation/mise/.mise.toml"
  local config_root="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  local dest="$config_root/config.toml"

  if [[ ! -f "$src" ]]; then
    log ERROR "Missing mise config source: $src"
    return 1
  fi

  mkdir -p "$config_root"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      log INFO "mise config link already in place: $dest"
      return 0
    fi
    log WARN "mise config symlink points elsewhere: $dest -> $current"
    log WARN "Leaving existing symlink untouched"
    return 0
  fi

  if [[ -e "$dest" ]]; then
    log WARN "Existing file at $dest; leaving untouched"
    log WARN "Manually replace with symlink to $src if desired"
    return 0
  fi

  ln -s "$src" "$dest"
  log INFO "Linked mise config: $dest -> $src"
}

install_mise_tools() {
  local mise_bin=""

  if command -v mise >/dev/null 2>&1; then
    mise_bin="$(command -v mise)"
  elif [[ -x "$HOME/.local/bin/mise" ]]; then
    mise_bin="$HOME/.local/bin/mise"
  fi

  if [[ -z "$mise_bin" ]]; then
    log WARN "mise not found on PATH after install step; skipping 'mise install'"
    return 0
  fi

  log INFO "Installing tool versions via mise"
  "$mise_bin" install
}

log INFO "Bootstrap profile: $profile"
log INFO "Repository root: $repo_root"

run_step "Installing OS dependencies" "$scripts_dir/install-deps.sh" "$profile"
run_step "Installing Oh My Zsh" "$scripts_dir/install-omz.sh"
run_step "Installing Oh My Zsh plugins" "$scripts_dir/install-omz-plugins.sh"

if [[ "$profile" == "full" ]]; then
  run_step "Installing mise" "$scripts_dir/install-mise.sh"
  link_mise_config
  install_mise_tools
fi

if [[ "${DF_SKIP_STOW:-0}" == "1" ]]; then
  log WARN "Skipping stow step because DF_SKIP_STOW=1"
else
  run_step "Applying stow package" "$scripts_dir/stow.sh"
fi

if [[ "${DF_SKIP_VERIFY:-0}" == "1" ]]; then
  log WARN "Skipping verification because DF_SKIP_VERIFY=1"
else
  run_step "Running verification checks" "$scripts_dir/verify.sh" "$profile"
fi

log INFO "Bootstrap completed successfully"
