alias deepchat="codex -p deepchat"
alias devcoding="codex -p dev"
alias cpai='latest=$(ls -1t ~/.codex/sessions/**/*.jsonl(.N) 2>/dev/null | head -1); \
  if [ -z "$latest" ]; then echo "No Codex session logs found."; return 1; fi; \
  msg=$(jq -sr '\''reverse | map(select(.payload.role=="assistant" and .payload.type=="message") | [ .payload.content[]? | .text // empty ] | join("\n")) | .[0] // ""'\'' "$latest"); \
  if [ -z "$msg" ]; then echo "No assistant messages found in $latest."; return 1; fi; \
  printf "%s" "$msg" | xclip -selection clipboard && echo "Copied last reply to clipboard via xclip."'
