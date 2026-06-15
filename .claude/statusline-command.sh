#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

parts=""

[ -n "$cwd" ] && parts="$cwd"

[ -n "$model" ] && parts="$parts | $model"

[ -n "$effort" ] && parts="$parts | effort:$effort"

if [ -n "$used" ]; then
  remaining=$(echo "$used" | awk '{printf "%.0f", 100 - $1}')
  parts="$parts | ctx:${remaining}% left"
fi

printf '%s' "$parts"
