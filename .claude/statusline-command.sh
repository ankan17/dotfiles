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
  parts="$parts | ctx:${used}% used"
fi

printf '%s' "$parts"
