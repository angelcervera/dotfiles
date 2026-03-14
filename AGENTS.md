# Repo Agent Notes

This repository manages dotfiles with GNU Stow and bootstraps a reproducible developer workstation for Ubuntu/Debian and macOS.

## Scope and safety

- Never modify the user's live files in `$HOME` unless explicitly requested.
- Prefer updating only tracked files in this repository.
- Use dry-runs before any Stow operation that would affect `$HOME`.
- Do not use `stow --adopt` unless the user explicitly asks for it.

## Canonical scripts

- `./bootstrap.sh [minimal|full]`
  - Main entrypoint for dependency install, Oh My Zsh setup, `mise`, Stow, and verification.
- `workstation/scripts/stow.sh`
  - Applies `stow --restow` for the tracked packages.
- `workstation/scripts/verify.sh [minimal|full]`
  - Full workstation verification, including Stow expectations and shell integration.
- `workstation/scripts/verify-tools.sh [minimal|full]`
  - Checks required CLI tools, optional current-shell extras, and key plugin directories.

## Expected workflow for agent updates

When changing package lists, runtime versions, shell config, or bootstrap behavior:

1. Update the relevant tracked files.
2. Keep Ubuntu/Debian and macOS support in mind; avoid Linux-only assumptions unless guarded.
3. If tool expectations change, update `workstation/scripts/verify-tools.sh`.
4. If bootstrap behavior changes, ensure `bootstrap.sh` and `workstation/scripts/verify.sh` stay aligned.
5. Update `README.md` when behavior, required tools, or verification steps change.
6. Run validation commands locally in the repo before finishing.

## Validation commands

- Syntax:
  - `bash -n bootstrap.sh`
  - `bash -n workstation/scripts/*.sh`
  - `zsh -n zsh/.zshrc`
  - `zsh -n zsh/.config/zsh/*.zsh`
  - `zsh -n zsh/.oh-my-zsh/custom/**/*.zsh`
- Tests:
  - `bash tests/test-bootstrap-smoke.sh`
  - `bash tests/test-gwt.sh`
- Verification:
  - `workstation/scripts/verify-tools.sh minimal`
  - `workstation/scripts/verify-tools.sh full`
  - `workstation/scripts/verify.sh minimal`
  - `workstation/scripts/verify.sh full`
- Safe Stow preview:
  - `stow --dir "$PWD" --target "$HOME" -n -v -R zsh alacritty jetbrains-ai`

## Tool expectations

- Base tools: `git`, `curl`, `stow`, `zsh`
- Full profile CLI tools: `fzf`, `rg`, `jq`, `tmux`, `nvim`, `gh`, `bat|batcat`, `direnv`, `mise`
- `mise` toolchain: `go`, `node`, `bun`, `rustc`
- Optional current-shell extras: `nvm`, `pnpm`, `codex`, `opencode`, `lms`, `eza`

## Stow packages

- `zsh/`
- `alacritty/`
- `jetbrains-ai/`

`workstation/` is implementation detail and must not be stowed.
