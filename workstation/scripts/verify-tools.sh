#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

usage() {
  cat <<'EOF'
Usage: workstation/scripts/verify-tools.sh [minimal|full]

Checks tool availability for the current workstation profile.

Profiles:
  minimal    Base shell and essential tools
  full       Minimal + full CLI tools + configured extras (default)
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

pass_count=0
fail_count=0
warn_count=0

check_ok() {
  pass_count=$((pass_count + 1))
  printf '[OK] %s\n' "$1"
}

check_fail() {
  fail_count=$((fail_count + 1))
  printf '[FAIL] %s\n' "$1"
}

check_warn() {
  warn_count=$((warn_count + 1))
  printf '[WARN] %s\n' "$1"
}

check_cmd() {
  local cmd="$1"
  local label="${2:-$1}"

  if command -v "$cmd" >/dev/null 2>&1; then
    check_ok "$label: $(command -v "$cmd")"
  else
    check_fail "$label missing (expected command: $cmd)"
  fi
}

check_any_cmd() {
  local label="$1"
  shift
  local cmd

  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      check_ok "$label: $(command -v "$cmd")"
      return 0
    fi
  done

  check_fail "$label missing (expected one of: $*)"
}

check_optional_cmd() {
  local cmd="$1"
  local label="${2:-$1}"

  if command -v "$cmd" >/dev/null 2>&1; then
    check_ok "$label: $(command -v "$cmd")"
  else
    check_warn "$label not found (expected by current shell config)"
  fi
}

check_optional_any_cmd() {
  local label="$1"
  shift
  local cmd

  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      check_ok "$label: $(command -v "$cmd")"
      return 0
    fi
  done

  check_warn "$label not found (expected one of: $*)"
}

check_dir() {
  local dir="$1"
  local label="$2"

  if [[ -d "$dir" ]]; then
    check_ok "$label: $dir"
  else
    check_warn "$label missing: $dir"
  fi
}

check_file() {
  local file="$1"
  local label="$2"

  if [[ -f "$file" ]]; then
    check_ok "$label: $file"
  else
    check_warn "$label missing: $file"
  fi
}

kernel="$(uname -s)"
case "$kernel" in
  Linux) os_label='ubuntu/debian-compatible' ;;
  Darwin) os_label='macOS' ;;
  *) os_label="$kernel" ;;
esac

printf 'Tool verification profile: %s\n' "$profile"
printf 'Detected OS: %s\n' "$os_label"

printf '\n== Required base tools ==\n'
check_cmd git
check_cmd curl
check_cmd stow
check_cmd zsh

printf '\n== Shell framework and terminal config ==\n'
check_dir "$HOME/.oh-my-zsh" 'Oh My Zsh directory'
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 'OMZ autosuggestions plugin'
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 'OMZ syntax-highlighting plugin'
check_dir "$HOME/.oh-my-zsh/custom/plugins/git-wt" 'Custom git-wt plugin'
check_dir "$HOME/.oh-my-zsh/custom/plugins/df" 'Custom df plugin'

if [[ "$profile" == "full" ]]; then
  printf '\n== Required full-profile CLI tools ==\n'
  check_cmd fzf
  check_cmd rg 'ripgrep'
  check_cmd jq
  check_cmd tmux
  check_cmd nvim
  check_cmd gh 'GitHub CLI'
  check_any_cmd 'bat' bat batcat
  check_cmd direnv
  check_cmd mise

  printf '\n== Required mise-managed toolchain ==\n'
  check_cmd go
  check_cmd node
  check_cmd bun
  check_cmd rustc 'Rust compiler'

  printf '\n== Optional extras from current shell config ==\n'
  check_file "$HOME/.nvm/nvm.sh" 'nvm init script'
  check_optional_cmd pnpm
  check_optional_cmd codex
  check_optional_cmd opencode
  check_optional_cmd lms 'LM Studio CLI'
  check_optional_any_cmd 'eza' eza
  check_dir "$HOME/.local/share/JetBrains/Toolbox/scripts" 'JetBrains Toolbox scripts directory'
fi

printf '\nSummary: %d ok, %d warnings, %d failures\n' "$pass_count" "$warn_count" "$fail_count"

if [[ "$fail_count" -gt 0 ]]; then
  log ERROR 'Tool verification failed.'
  exit 1
fi

log INFO 'Tool verification passed.'
