#!/bin/bash
# Symlink dotfiles to home directory
# Usage: cd ~/dotfiles && ./setup.sh

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# zshrc
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc

# VS Code
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_DIR"
ln -sf "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/settings.json"
ln -sf "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"

# Cursor
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
mkdir -p "$CURSOR_DIR"
ln -sf "$DOTFILES_DIR/cursor/settings.json" "$CURSOR_DIR/settings.json"
ln -sf "$DOTFILES_DIR/cursor/keybindings.json" "$CURSOR_DIR/keybindings.json"

# Claude Code config
mkdir -p ~/.claude/skills
ln -sf "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json

for skill in "$DOTFILES_DIR"/claude/skills/*/; do
  skill_name="$(basename "$skill")"
  ln -sf "$skill" ~/.claude/skills/"$skill_name"
done

# Cursor extensions
if command -v cursor &> /dev/null && [ -f "$DOTFILES_DIR/cursor/extensions.txt" ]; then
  echo "Installing Cursor extensions..."
  while read -r ext; do
    cursor --install-extension "$ext" --force
  done < "$DOTFILES_DIR/cursor/extensions.txt"
fi

echo "Dotfiles symlinked from $DOTFILES_DIR"
echo "NOTE: Create ~/.secrets with your tokens (GITLAB_TOKEN, JIRA_TOKEN, JIRA_USER, SLACK_TOKEN)"
