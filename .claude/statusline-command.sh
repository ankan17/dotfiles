#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Context token display: "X.YK / ZM"
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

ctx_str=""
if [ -n "$total_input" ] && [ -n "$ctx_size" ]; then
  ctx_str=$(awk -v used="$total_input" -v total="$ctx_size" 'BEGIN {
    if (used >= 1000000) { printf "%.1fM", used/1000000 }
    else if (used >= 1000) { printf "%.1fK", used/1000 }
    else { printf "%d", used }
    printf " / "
    if (total >= 1000000) { printf "%.0fM", total/1000000 }
    else if (total >= 1000) { printf "%.0fK", total/1000 }
    else { printf "%d", total }
  }')
fi

# Rate limits (personal Pro/Max only): 5h/7d windows. Absent for enterprise.
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

rate_str=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  # Personal plan
  five_str=""
  week_str=""
  if [ -n "$five_pct" ]; then
    if [ -n "$five_resets" ]; then
      now=$(date +%s)
      remaining_secs=$((five_resets - now))
      if [ "$remaining_secs" -gt 0 ]; then
        mins=$((remaining_secs / 60))
        if [ "$mins" -ge 60 ]; then
          reset_label=$(awk -v m="$mins" 'BEGIN { printf "%.1fh", m/60 }')
        else
          reset_label="${mins}m"
        fi
        five_str="5h:$(printf '%.0f' "$five_pct")% (resets ${reset_label})"
      else
        five_str="5h:$(printf '%.0f' "$five_pct")%"
      fi
    else
      five_str="5h:$(printf '%.0f' "$five_pct")%"
    fi
  fi
  [ -n "$week_pct" ] && week_str="7d:$(printf '%.0f' "$week_pct")%"
  if [ -n "$five_str" ] && [ -n "$week_str" ]; then
    rate_str="$five_str | $week_str"
  elif [ -n "$five_str" ]; then
    rate_str="$five_str"
  else
    rate_str="$week_str"
  fi
fi

# Assemble left side
left=""
[ -n "$cwd" ] && left="$cwd"
[ -n "$model" ] && left="$left | $model"
[ -n "$effort" ] && left="$left | effort:$effort"
[ -n "$ctx_str" ] && left="$left | $ctx_str"

# Assemble output
if [ -n "$rate_str" ]; then
  printf '%s  |  %s' "$left" "$rate_str"
else
  printf '%s' "$left"
fi
