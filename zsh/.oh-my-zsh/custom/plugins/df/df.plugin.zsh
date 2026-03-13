_df_find_root() {
  local candidate dir

  if [[ -n "${DOTFILES_DIR:-}" ]]; then
    candidate="$DOTFILES_DIR"
    if [[ -f "$candidate/bootstrap.sh" && -d "$candidate/zsh" ]]; then
      print -r -- "$candidate"
      return 0
    fi
  fi

  candidate="$HOME/dotfiles"
  if [[ -f "$candidate/bootstrap.sh" && -d "$candidate/zsh" ]]; then
    print -r -- "$candidate"
    return 0
  fi

  dir="$PWD"
  while true; do
    if [[ -f "$dir/bootstrap.sh" && -d "$dir/zsh" ]]; then
      print -r -- "$dir"
      return 0
    fi

    if [[ "$dir" == "/" ]]; then
      break
    fi

    dir="${dir:h}"
  done

  return 1
}

_df_root_or_die() {
  local root
  if ! root="$(_df_find_root)"; then
    print -u2 -- 'df: unable to locate dotfiles repository'
    print -u2 -- 'df: set DOTFILES_DIR or use ~/dotfiles'
    return 1
  fi
  print -r -- "$root"
}

dfcd() {
  local root
  root="$(_df_root_or_die)" || return 1
  builtin cd "$root"
}

dfstow() {
  local root script
  root="$(_df_root_or_die)" || return 1
  script="$root/workstation/scripts/stow.sh"

  if [[ -x "$script" ]]; then
    "$script"
    return $?
  fi

  if ! command -v stow >/dev/null 2>&1; then
    print -u2 -- 'df: stow is not installed'
    return 1
  fi

  stow --dir "$root" --target "$HOME" -R zsh alacritty
}

dfup() {
  local root
  root="$(_df_root_or_die)" || return 1

  (
    cd "$root"
    git pull --ff-only
  ) || return 1

  dfstow
}

dfdoctor() {
  local root verify_script
  root="$(_df_root_or_die)" || return 1
  verify_script="$root/workstation/scripts/verify.sh"

  if [[ ! -x "$verify_script" ]]; then
    print -u2 -- "df: missing verify script: $verify_script"
    return 1
  fi

  "$verify_script" "$@"
}

dfhelp() {
  cat <<'EOF'
Dotfiles helper commands:
  dfcd        cd to dotfiles repository root
  dfstow      restow zsh and alacritty packages
  dfup        git pull --ff-only and restow stow packages
  dfdoctor    run workstation verification checks
  dfhelp      show this help
EOF
}
