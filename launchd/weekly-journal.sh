#!/bin/zsh
# Runs /weekly-journal headless (launchd: com.ankan.weekly-journal, Tuesdays 21:00).
# JOURNAL_* and JOURNAL_CLAUDE_CONFIG come from the untracked ~/.aliases.
set -u
export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
node_bin=($HOME/.nvm/versions/node/*/bin(N))  # plugin hooks need node
[ ${#node_bin} -gt 0 ] && PATH="${node_bin[-1]}:$PATH"
[ -f ~/.aliases ] && source ~/.aliases
export CLAUDE_CONFIG_DIR="${JOURNAL_CLAUDE_CONFIG:-$HOME/.claude}"

LOG="$HOME/Library/Logs/weekly-journal.log"
ALLOW=(
  Read Write Edit Glob Grep
  "Bash(git:*)" "Bash(cd:*)" "Bash(find:*)" "Bash(stat:*)" "Bash(ls:*)"
  "Bash(date:*)" "Bash(wc:*)" "Bash(sort:*)" "Bash(uniq:*)" "Bash(awk:*)"
  "Bash(sed:*)" "Bash(grep:*)" "Bash(rg:*)" "Bash(cat:*)" "Bash(head:*)"
  "Bash(tail:*)" "Bash(echo:*)" "Bash(jq:*)" "Bash(sqlite3:*)" "Bash(env:*)"
  "Bash(basename:*)" "Bash(dirname:*)" "Bash(cut:*)" "Bash(tr:*)" "Bash(xargs:*)"
)
DIRS=()
for d in ${(s/:/)JOURNAL_PROJECT_DIRS:-}; do DIRS+=(--add-dir "$d"); done

out=$(cd "${JOURNAL_VAULT:?JOURNAL_VAULT unset}" && claude -p "/weekly-journal" "${DIRS[@]}" --allowedTools "${ALLOW[@]}" 2>&1)
code=$?
{ echo "=== run: $(date '+%Y-%m-%d %H:%M:%S %Z') ==="; echo "$out"; echo "=== exit: $code ==="; } >> "$LOG"

# claude -p exits 0 on "Unknown command", so check the text too.
if [ $code -ne 0 ] || print -r -- "$out" | grep -qE '^(Unknown command|Failed to authenticate|Error)'; then
  osascript -e "display notification \"See $LOG\" with title \"weekly-journal failed\""
fi
