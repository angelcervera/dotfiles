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
repo_root="$(cd "$script_dir/../.." && pwd)"

normalize_line() {
  local line="$1"
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s' "$line"
}

read_packages_file() {
  local file="$1"
  local raw line

  [[ -f "$file" ]] || return 0

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    line="$(normalize_line "$raw")"
    [[ -n "$line" ]] && printf '%s\n' "$line"
  done < "$file"
}

detect_os() {
  local kernel
  kernel="$(uname -s)"

  if [[ "$kernel" == "Darwin" ]]; then
    printf 'macos'
    return 0
  fi

  if [[ "$kernel" != "Linux" ]]; then
    log ERROR "Unsupported kernel: $kernel"
    return 1
  fi

  if [[ ! -f /etc/os-release ]]; then
    log ERROR 'Cannot detect Linux distro: missing /etc/os-release'
    return 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  local id_like="${ID_LIKE:-}"
  local id="${ID:-}"

  if [[ "$id" == "ubuntu" || "$id" == "debian" || "$id_like" == *debian* || "$id_like" == *ubuntu* ]]; then
    printf 'ubuntu'
    return 0
  fi

  log ERROR "Unsupported Linux distro: ID=${id:-unknown}, ID_LIKE=${id_like:-unknown}"
  return 1
}

declare -a all_packages=()
declare -A seen=()

collect_packages() {
  local os_name="$1"
  local file pkg

  for file in "$repo_root/workstation/packages/common.txt" "$repo_root/workstation/packages/$os_name.txt"; do
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      if [[ -z "${seen[$pkg]:-}" ]]; then
        seen["$pkg"]=1
        all_packages+=("$pkg")
      fi
    done < <(read_packages_file "$file")
  done
}

filter_for_profile() {
  local selected=()
  local pkg

  if [[ "$profile" == "full" ]]; then
    selected=("${all_packages[@]}")
  else
    declare -A minimal_allowed=(
      [git]=1
      [curl]=1
      [stow]=1
      [zsh]=1
    )

    for pkg in "${all_packages[@]}"; do
      if [[ -n "${minimal_allowed[$pkg]:-}" ]]; then
        selected+=("$pkg")
      fi
    done
  fi

  if [[ "${#selected[@]}" -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${selected[@]}"
}

install_with_apt() {
  local -a packages=("$@")
  local -a root_cmd=()
  local pkg

  if [[ ! -x /usr/bin/apt-get && -z "$(command -v apt-get 2>/dev/null || true)" ]]; then
    log ERROR 'apt-get is required on Ubuntu/Debian'
    return 1
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    root_cmd=()
  elif [[ "${DF_NO_SUDO:-0}" == "1" ]]; then
    log WARN 'DF_NO_SUDO=1 set; skipping apt-get installation'
    return 0
  elif command -v sudo >/dev/null 2>&1; then
    root_cmd=(sudo)
  else
    log ERROR 'sudo is required for apt-get installation (or run as root)'
    return 1
  fi

  log INFO 'Running apt-get update'
  if ! "${root_cmd[@]}" apt-get update; then
    log ERROR 'apt-get update failed'
    return 1
  fi

  for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      log INFO "Already installed: $pkg"
      continue
    fi

    log INFO "Installing package: $pkg"
    if ! "${root_cmd[@]}" apt-get install -y "$pkg"; then
      log WARN "Package not installed (unavailable or failed): $pkg"
    fi
  done
}

install_with_brew() {
  local -a packages=("$@")
  local pkg

  if ! command -v brew >/dev/null 2>&1; then
    log ERROR 'Homebrew is required on macOS but is not installed.'
    log ERROR 'Install Homebrew first: https://brew.sh/'
    return 1
  fi

  if [[ "${DF_NO_BREW_UPDATE:-0}" != "1" ]]; then
    log INFO 'Running brew update'
    if ! brew update; then
      log WARN 'brew update failed; continuing with existing metadata'
    fi
  fi

  for pkg in "${packages[@]}"; do
    if brew list --versions "$pkg" >/dev/null 2>&1; then
      log INFO "Already installed: $pkg"
      continue
    fi

    log INFO "Installing package: $pkg"
    if ! brew install "$pkg"; then
      log WARN "Package not installed (unavailable or failed): $pkg"
    fi
  done
}

os_name="$(detect_os)"
collect_packages "$os_name"

mapfile -t selected_packages < <(filter_for_profile)

if [[ "${#selected_packages[@]}" -eq 0 ]]; then
  log WARN 'No packages selected for installation'
  exit 0
fi

log INFO "Selected profile: $profile"
log INFO "Detected OS flavor: $os_name"
log INFO "Selected packages: ${selected_packages[*]}"

case "$os_name" in
  ubuntu)
    install_with_apt "${selected_packages[@]}"
    ;;
  macos)
    install_with_brew "${selected_packages[@]}"
    ;;
  *)
    log ERROR "Unsupported OS flavor: $os_name"
    exit 1
    ;;
esac

log INFO 'Dependency installation step completed'
