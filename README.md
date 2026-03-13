# Dotfiles + Reproducible Workstation Bootstrap

This repository manages shell dotfiles with GNU Stow and bootstraps a reproducible developer workstation on Ubuntu/Debian (primary) and macOS (secondary).

## What this repo does

- Uses `stow` to symlink `zsh/` and `alacritty/` packages into `$HOME`.
- Installs and configures Oh My Zsh and selected plugins.
- Installs curated CLI tooling by OS.
- Installs `mise` and links a global config for pinned tool versions.
- Provides verification and smoke/integration tests.

## Repository layout

- `zsh/` - stow package with `.zshrc`, aliases/functions, and custom OMZ plugins.
- `alacritty/` - stow package with `~/.config/alacritty/alacritty.toml`.
- `workstation/` - bootstrap implementation details (not stowed).
- `tests/` - shell tests for `gwt` and bootstrap smoke behavior.

## Prerequisites

- `bash`, `git`, and `curl` available.
- Linux: Ubuntu/Debian with `apt-get`.
- macOS: Homebrew installed (`install-deps.sh` fails with instructions if missing).

## Install

Clone and bootstrap:

```bash
git clone <your-repo-url> "$HOME/dotfiles"
cd "$HOME/dotfiles"
./bootstrap.sh full
```

Profiles:

- `minimal` - base shell and essential tooling.
- `full` (default) - minimal + full CLI set + `mise`.

Examples:

```bash
./bootstrap.sh minimal
./bootstrap.sh full
```

## Manual verification before stow

If you want to inspect everything before symlinks are applied:

```bash
DF_SKIP_STOW=1 ./bootstrap.sh full
```

Then preview stow actions safely:

```bash
stow --dir "$PWD" --target "$HOME" -n -v -R zsh alacritty
```

Finally apply:

```bash
workstation/scripts/stow.sh
```

## Update workflow

- Use OMZ plugin `dfup` (does `git pull --ff-only` + restow stow packages).
- Or manually:

```bash
git pull --ff-only
workstation/scripts/stow.sh
```

## Uninstall

Remove stowed links for this package:

```bash
stow --dir "$HOME/dotfiles" --target "$HOME" -D zsh alacritty
```

## Tool versions (`mise`)

- Edit versions in `workstation/mise/.mise.toml`.
- Bootstrap links it to `${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml` for `full` profile.
- Reinstall tools after updates:

```bash
mise install
```

## JetBrains MCP config

- Project-local JetBrains AI Assistant MCP config lives at `.ai/mcp/mcp.json`.
- It mirrors the MCP servers configured in OpenCode: `context7`, `playwright`, `github`, and `chrome-devtools`.
- The remote entries keep the same env-based placeholders from OpenCode:
  - `CONTEXT7_API_KEY`
  - `GITHUB_PAT_TOKEN`
- If your JetBrains build does not expand `{env:...}` placeholders automatically, replace those values manually in the IDE MCP settings UI.

## Troubleshooting

- Symlink conflicts
  - Run dry-run first: `stow --dir "$PWD" --target "$HOME" -n -v -R zsh alacritty`.
  - If conflicts exist, move conflicting files manually and re-run.
  - Avoid `--adopt` unless you explicitly want to move target files into the package.

- Oh My Zsh plugin load order
  - Ensure `.zshrc` plugin list includes `git-wt`, `df`, `zsh-autosuggestions`, and `zsh-syntax-highlighting`.
  - Syntax highlighting should remain late in the list.

- Worktree path conflicts (`gwt`)
  - If target path exists and is non-empty, choose another path.
  - If branch already has a worktree, inspect with `git worktree list`.

- mise activation issues
  - Confirm `mise` exists: `command -v mise` or `~/.local/bin/mise`.
  - Open a new shell after bootstrap.
  - Verify activation line in `~/.zshrc` (managed by stow package).

## Useful environment flags

- `DF_NO_SUDO=1` - skip privileged package install steps (for smoke tests).
- `DF_SKIP_STOW=1` - skip the stow apply step.
- `DF_SKIP_VERIFY=1` - skip verification phase.
- `DF_OMZ_DIR=/path` - override Oh My Zsh location for bootstrap scripts.
