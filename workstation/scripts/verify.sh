#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

profile="${1:-full}"
case "$profile" in
  minimal|full) ;;
  *)
    log ERROR "Invalid profile: $profile"
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tools_verify_script="$script_dir/verify-tools.sh"

pass_count=0
fail_count=0

check_ok() {
  local message="$1"
  pass_count=$((pass_count + 1))
  printf '[OK] %s\n' "$message"
}

check_fail() {
  local message="$1"
  fail_count=$((fail_count + 1))
  printf '[FAIL] %s\n' "$message"
}

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    check_ok "command found: $cmd"
  else
    check_fail "command missing: $cmd"
  fi
}

check_path_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    check_ok "$label exists: $path"
  else
    check_fail "$label missing: $path"
  fi
}

check_path_symlink() {
  local path="$1"
  local label="$2"
  if [[ -L "$path" ]]; then
    check_ok "$label is symlink: $path"
  else
    check_fail "$label is not a symlink: $path"
  fi
}

check_path_stow_managed() {
  local path="$1"
  local label="$2"
  local current="$path"

  while [[ "$current" != "$HOME" && "$current" != "/" ]]; do
    if [[ -L "$current" ]]; then
      check_ok "$label is stow-managed via symlink: $current"
      return 0
    fi
    current="$(dirname "$current")"
  done

  check_fail "$label is not stow-managed by symlink: $path"
}

printf 'Verification profile: %s\n' "$profile"

if [[ -x "$tools_verify_script" ]]; then
  if "$tools_verify_script" "$profile"; then
    check_ok 'verify-tools.sh passed'
  else
    check_fail 'verify-tools.sh failed'
  fi
else
  check_fail "Missing tool verification script: $tools_verify_script"
fi

check_cmd zsh
check_path_exists "$HOME/.zshrc" '.zshrc'
check_path_stow_managed "$HOME/.zshrc" '.zshrc'
check_path_exists "$HOME/.config/alacritty/alacritty.toml" 'Alacritty config'
check_path_stow_managed "$HOME/.config/alacritty/alacritty.toml" 'Alacritty config'
check_path_exists "$HOME/.ai/mcp/mcp.json" 'JetBrains MCP config'
check_path_stow_managed "$HOME/.ai/mcp/mcp.json" 'JetBrains MCP config'

check_path_exists "$HOME/.oh-my-zsh" 'Oh My Zsh directory'
check_path_stow_managed "$HOME/.oh-my-zsh/custom/plugins/git-wt" 'git-wt plugin path'

if [[ -f "$HOME/.oh-my-zsh/custom/plugins/git-wt/git-wt.plugin.zsh" ]]; then
  if zsh -c 'source "$HOME/.oh-my-zsh/custom/plugins/git-wt/git-wt.plugin.zsh" >/dev/null 2>&1 && typeset -f gwt >/dev/null'; then
    check_ok 'gwt function resolves in zsh'
  else
    check_fail 'gwt function failed to resolve in zsh'
  fi
else
  check_fail 'git-wt plugin file missing'
fi

minimal_bins=(git zsh stow curl)
full_bins=(fzf rg jq tmux nvim gh mise)

for bin in "${minimal_bins[@]}"; do
  check_cmd "$bin"
done

if [[ "$profile" == "full" ]]; then
  for bin in "${full_bins[@]}"; do
    check_cmd "$bin"
  done
fi

printf 'Checks passed: %d\n' "$pass_count"
printf 'Checks failed: %d\n' "$fail_count"

if [[ "$fail_count" -gt 0 ]]; then
  log ERROR 'Verification failed. Review failures above.'
  exit 1
fi

log INFO 'Verification succeeded'
