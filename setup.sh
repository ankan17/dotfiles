#!/bin/bash
# Interactive dotfiles setup — symlinks configs from this repo to their expected locations.
# Usage: cd ~/dotfiles && ./setup.sh
# Pass --all to skip prompts and install everything.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ALL=false
[[ "$1" == "--all" ]] && ALL=true

ask() {
  if $ALL; then return 0; fi
  printf "\n\033[1;34m%s\033[0m [Y/n] " "$1"
  read -r answer
  [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

info() { printf "  \033[0;32m✓\033[0m %s\n" "$1"; }
skip() { printf "  \033[0;33m⊘\033[0m %s\n" "Skipped"; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Dotfiles Setup Script        ║"
echo "╚══════════════════════════════════════╝"

# --- Zsh ---
if ask "Set up zsh config? (.zshrc with Oh My Zsh, plugins, aliases)"; then
  ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
  info "~/.zshrc -> $DOTFILES_DIR/.zshrc"
else
  skip
fi

# --- VS Code ---
if ask "Set up VS Code? (settings + keybindings)"; then
  VSCODE_DIR="$HOME/Library/Application Support/Code/User"
  mkdir -p "$VSCODE_DIR"
  ln -sf "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/settings.json"
  ln -sf "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"
  info "VS Code settings symlinked"
else
  skip
fi

# --- Cursor ---
if ask "Set up Cursor? (settings + keybindings)"; then
  CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
  mkdir -p "$CURSOR_DIR"
  ln -sf "$DOTFILES_DIR/cursor/settings.json" "$CURSOR_DIR/settings.json"
  ln -sf "$DOTFILES_DIR/cursor/keybindings.json" "$CURSOR_DIR/keybindings.json"
  info "Cursor settings symlinked"

  if ask "Install Cursor extensions from extensions.txt?"; then
    if command -v cursor &> /dev/null; then
      while read -r ext; do
        cursor --install-extension "$ext" --force 2>/dev/null && info "$ext" || printf "  \033[0;31m✗\033[0m %s\n" "$ext"
      done < "$DOTFILES_DIR/cursor/extensions.txt"
    else
      printf "  \033[0;31m✗\033[0m %s\n" "cursor command not found — install Cursor first"
    fi
  else
    skip
  fi
else
  skip
fi

# --- Claude Code ---
if ask "Set up Claude Code? (settings + custom skills)"; then
  mkdir -p ~/.claude/skills
  ln -sf "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
  info "Claude Code settings symlinked"

  for skill in "$DOTFILES_DIR"/claude/skills/*/; do
    skill_name="$(basename "$skill")"
    ln -sf "$skill" ~/.claude/skills/"$skill_name"
    info "Skill: $skill_name"
  done
else
  skip
fi

# --- Secrets reminder ---
echo ""
echo "────────────────────────────────────────"
if [ -f ~/.secrets ]; then
  info "~/.secrets exists"
else
  printf "  \033[0;33m!\033[0m %s\n" "Create ~/.secrets with your tokens:"
  echo "    export GITLAB_TOKEN=\"...\""
  echo "    export JIRA_USER=\"...\""
  echo "    export JIRA_TOKEN=\"...\""
  echo "    export SLACK_TOKEN=\"...\""
fi

echo ""
echo "Done!"
