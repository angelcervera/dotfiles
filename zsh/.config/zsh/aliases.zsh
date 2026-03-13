if command -v eza >/dev/null 2>&1; then
  alias la='eza -lah --icons --group-directories-first --git'
else
  alias la='ls -lah'
fi

alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull --ff-only'
alias gco='git checkout'
