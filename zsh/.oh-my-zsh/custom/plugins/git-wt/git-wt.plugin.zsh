gwt() {
  local branch wt_path path_display sanitized line created_from

  if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
    print -u2 -- 'Usage: gwt <branch> [path]'
    return 2
  fi

  branch="$1"
  wt_path="${2:-}"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 -- 'gwt: not inside a git work tree'
    return 1
  fi

  if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
    print -u2 -- "gwt: invalid branch name: $branch"
    return 1
  fi

  while IFS= read -r line; do
    if [[ "$line" == "branch refs/heads/$branch" ]]; then
      print -u2 -- "gwt: branch '$branch' already has a worktree"
      print -u2 -- 'gwt: inspect with: git worktree list'
      return 1
    fi
  done < <(git worktree list --porcelain)

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    created_from='existing local branch'
  else
    if git remote get-url origin >/dev/null 2>&1; then
      if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        git branch --track "$branch" "origin/$branch"
        created_from='tracking origin branch'
      else
        git branch "$branch" HEAD
        created_from='HEAD (origin branch not found)'
      fi
    else
      git branch "$branch" HEAD
      created_from='HEAD (origin remote not found)'
    fi
  fi

  if [[ -z "$wt_path" ]]; then
    sanitized="${branch//\//-}"
    wt_path="../wt-$sanitized"
  fi

  if [[ -e "$wt_path" ]]; then
    if [[ ! -d "$wt_path" ]]; then
      print -u2 -- "gwt: path exists and is not a directory: $wt_path"
      return 1
    fi

    setopt local_options null_glob
    local -a entries
    entries=("$wt_path"/* "$wt_path"/.[!.]* "$wt_path"/..?*)
    if (( ${#entries[@]} > 0 )); then
      print -u2 -- "gwt: path exists and is not empty: $wt_path"
      return 1
    fi
  fi

  if ! git worktree add "$wt_path" "$branch"; then
    print -u2 -- 'gwt: failed to create worktree'
    return 1
  fi

  if [[ -d "$wt_path" ]]; then
    path_display="$(cd "$wt_path" && pwd)"
  else
    path_display="$wt_path"
  fi

  print -- 'gwt: worktree created'
  print -- "  branch: $branch"
  print -- "  source: $created_from"
  print -- "  path:   $path_display"
}
