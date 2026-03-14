#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[SMOKE] %s\n' "$*"
}

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if [[ ! -x "$repo_root/bootstrap.sh" ]]; then
  fail "bootstrap.sh is missing or not executable: $repo_root/bootstrap.sh"
fi

tmp_home="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_home"
}
trap cleanup EXIT

log "Using temporary HOME: $tmp_home"

export HOME="$tmp_home"
export DF_NO_SUDO=1
export DF_SKIP_STOW=1
export DF_SKIP_VERIFY=1

mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"

log 'Running bootstrap minimal (non-destructive smoke mode)'
"$repo_root/bootstrap.sh" minimal

if ! command -v stow >/dev/null 2>&1; then
  fail 'stow command is required for smoke dry-run checks'
fi

mkdir -p "$HOME/.config"

log 'Validating expected stow dry-run output'
dryrun_output="$(stow --dir "$repo_root" --target "$HOME" --simulate --verbose=2 --restow zsh alacritty jetbrains-ai 2>&1 || true)"

[[ "$dryrun_output" == *'.zshrc'* ]] || fail 'stow dry-run did not mention .zshrc'
[[ "$dryrun_output" == *'.config/zsh'* ]] || fail 'stow dry-run did not mention zsh config path'
[[ "$dryrun_output" == *'.config/alacritty'* ]] || fail 'stow dry-run did not mention alacritty config path'
[[ "$dryrun_output" == *'.ai'* ]] || fail 'stow dry-run did not mention JetBrains AI path'

log 'test-bootstrap-smoke passed'
