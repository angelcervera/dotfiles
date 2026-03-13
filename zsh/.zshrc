path_prepend() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0

  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac
}

path_append() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0

  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$PATH:$dir" ;;
  esac
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "/usr/local/bin"

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 5
HIST_STAMPS="yyyy-mm-dd"

plugins=(
  git
  gitfast
  web-search
  copyfile
  copypath
  gh
  aliases
  git-wt
  zsh-autosuggestions
  df
  zsh-syntax-highlighting
)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [[ -n "$SSH_CONNECTION" ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

path_append "/usr/local/go/bin"

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  source "$NVM_DIR/bash_completion"
fi

export PNPM_HOME="$HOME/.local/share/pnpm"
path_prepend "$PNPM_HOME"

path_prepend "$HOME/.local/share/JetBrains/Toolbox/scripts"
path_append "$HOME/.lmstudio/bin"

export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
if [[ -s "$BUN_INSTALL/_bun" ]]; then
  source "$BUN_INSTALL/_bun"
fi

if command -v codex >/dev/null 2>&1; then
  eval "$(codex completion zsh)"
fi

if command -v opencode >/dev/null 2>&1; then
  _opencode_yargs_completions() {
    local reply
    local si=$IFS
    IFS=$'\n' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" opencode --get-yargs-completions "${words[@]}"))
    IFS=$si
    if [[ ${#reply} -gt 0 ]]; then
      _describe 'values' reply
    else
      _default
    fi
  }

  if [[ "${zsh_eval_context[-1]}" == "loadautofunc" ]]; then
    _opencode_yargs_completions "$@"
  else
    compdef _opencode_yargs_completions opencode
  fi
fi

if command -v go >/dev/null 2>&1; then
  path_append "$(go env GOPATH)/bin"
fi

if [[ -f "$HOME/.config/zsh/aliases.zsh" ]]; then
  source "$HOME/.config/zsh/aliases.zsh"
fi

if [[ -f "$HOME/.config/zsh/functions.zsh" ]]; then
  source "$HOME/.config/zsh/functions.zsh"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi
