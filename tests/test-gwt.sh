#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[TEST] %s\n' "$*"
}

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
plugin_file="$repo_root/zsh/.oh-my-zsh/custom/plugins/git-wt/git-wt.plugin.zsh"

if [[ ! -f "$plugin_file" ]]; then
  fail "Missing plugin file: $plugin_file"
fi

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

repo_dir="$tmp_root/repo"
mkdir -p "$repo_dir"

log "Initializing temporary git repository"
git -C "$repo_dir" init -q
git -C "$repo_dir" config user.name 'Test User'
git -C "$repo_dir" config user.email 'test@example.com'

printf 'bootstrap\n' > "$repo_dir/README.md"
git -C "$repo_dir" add README.md
git -C "$repo_dir" commit -q -m 'Initial commit'

cd "$repo_dir"

log "Running gwt feature/foo"
zsh -c '
  set -euo pipefail
  plugin_file="$1"
  repo_dir="$2"
  source "$plugin_file"
  cd "$repo_dir"
  gwt "feature/foo"
' -- "$plugin_file" "$repo_dir"

expected_wt="$tmp_root/wt-feature-foo"

git show-ref --verify --quiet refs/heads/feature/foo || fail 'Expected branch not found'
[[ -d "$expected_wt" ]] || fail "Expected worktree path missing: $expected_wt"

worktrees="$(git worktree list --porcelain)"
[[ "$worktrees" == *"$expected_wt"* ]] || fail 'git worktree list missing expected path'
[[ "$worktrees" == *'branch refs/heads/feature/foo'* ]] || fail 'git worktree list missing expected branch'

log 'test-gwt passed'
