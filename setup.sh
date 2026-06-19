#!/bin/bash
# Interactive dotfiles setup — installs tools and symlinks configs.
# Usage: cd ~/dotfiles && ./setup.sh
# Pass --all to skip prompts and install/configure everything.

# Note: no `set -e` — a single tool's install failing should not abort the
# whole run. Multi-step installs are guarded individually with subshells below.

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
warn() { printf "  \033[0;33m!\033[0m %s\n" "$1"; }
fail() { printf "  \033[0;31m✗\033[0m %s\n" "$1"; }
skip() { printf "  \033[0;33m⊘\033[0m %s\n" "Skipped"; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Dotfiles Setup Script        ║"
echo "╚══════════════════════════════════════╝"

# ============================================================
# PHASE 1: Tool Installation
# ============================================================

echo ""
echo "── Phase 1: Tool Installation ─────────"

# --- Homebrew (https://brew.sh/) ---
if ! command -v brew &> /dev/null; then
  if ask "Install Homebrew?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
    info "Homebrew installed"
  else
    skip
  fi
else
  info "Homebrew already installed"
fi

# --- iTerm2 (https://iterm2.com/downloads.html) ---
if [ ! -d "/Applications/iTerm.app" ]; then
  if ask "Install iTerm2?"; then
    curl -fsSL https://iterm2.com/downloads/stable/latest -o /tmp/iTerm2.zip
    unzip -qo /tmp/iTerm2.zip -d /Applications
    rm -f /tmp/iTerm2.zip
    info "iTerm2 installed"
  else
    skip
  fi
else
  info "iTerm2 already installed"
fi

# --- Oh My Zsh (https://ohmyz.sh/) ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if ask "Install Oh My Zsh?"; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    info "Oh My Zsh installed"
  else
    skip
  fi
else
  info "Oh My Zsh already installed"
fi

# --- Oh My Zsh custom plugins ---
if [ -d "$HOME/.oh-my-zsh" ]; then
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    if ask "Install zsh-autosuggestions plugin?"; then
      git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
      info "zsh-autosuggestions installed"
    else
      skip
    fi
  else
    info "zsh-autosuggestions already installed"
  fi

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    if ask "Install zsh-syntax-highlighting plugin?"; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
      info "zsh-syntax-highlighting installed"
    else
      skip
    fi
  else
    info "zsh-syntax-highlighting already installed"
  fi
fi

# --- Powerline fonts (required by the oxide theme's git-branch glyph) ---
if ! ls "$HOME/Library/Fonts" 2>/dev/null | grep -qi "Powerline"; then
  if ask "Install Powerline fonts? (needed for the oxide prompt theme)"; then
    if (
      set -e
      git clone --depth 1 https://github.com/powerline/fonts.git /tmp/powerline-fonts
      # Filter matches the on-disk filenames (FuraMono-*.otf); the installed
      # font's family name is "Fira Mono for Powerline".
      /tmp/powerline-fonts/install.sh "FuraMono"
    ); then
      info "Powerline fonts installed (Fira Mono for Powerline)"
      warn "Set your terminal font to 'Fira Mono for Powerline' (iTerm2 prefs already do this)"
    else
      fail "Powerline fonts install failed — continuing"
    fi
    rm -rf /tmp/powerline-fonts
  else
    skip
  fi
else
  info "Powerline fonts already installed"
fi

# --- Bun (https://bun.sh/) ---
if ! command -v bun &> /dev/null; then
  if ask "Install Bun?"; then
    curl -fsSL https://bun.sh/install | bash
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true
    info "Bun installed"
  else
    skip
  fi
else
  info "Bun already installed"
fi

# --- nvm + Node 24 (https://github.com/nvm-sh/nvm) ---
if [ ! -d "$HOME/.nvm" ]; then
  if ask "Install nvm + Node 24?"; then
    if (
      set -e
      # PROFILE=/dev/null: don't let the installer edit .zshrc (it's symlinked
      # from this repo; the sourcing block lives in .zshrc directly).
      PROFILE=/dev/null bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh)"
      export NVM_DIR="$HOME/.nvm"
      \. "$NVM_DIR/nvm.sh"
      nvm install 24
      nvm alias default 24
    ); then
      info "nvm + Node 24 installed"
    else
      fail "nvm + Node 24 install failed — continuing"
    fi
  else
    skip
  fi
else
  info "nvm already installed"
  if (
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm ls 24 &> /dev/null
  ); then
    info "Node 24 already installed"
  elif ask "Install Node 24 via nvm?"; then
    if (
      set -e
      export NVM_DIR="$HOME/.nvm"
      \. "$NVM_DIR/nvm.sh"
      nvm install 24
      nvm alias default 24
    ); then
      info "Node 24 installed"
    else
      fail "Node 24 install failed — continuing"
    fi
  else
    skip
  fi
fi

# --- VS Code (https://code.visualstudio.com/) ---
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
  if ask "Install VS Code?"; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
      VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64"
    else
      VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
    fi
    curl -fsSL "$VSCODE_URL" -o /tmp/VSCode.zip
    unzip -qo /tmp/VSCode.zip -d /Applications
    rm -f /tmp/VSCode.zip
    info "VS Code installed"
  else
    skip
  fi
else
  info "VS Code already installed"
fi

# --- Cursor (https://cursor.com/) ---
if [ ! -d "/Applications/Cursor.app" ]; then
  if ask "Install Cursor?"; then
    ARCH=$(uname -m)
    [ "$ARCH" = "arm64" ] && CURSOR_PLATFORM="darwin-arm64" || CURSOR_PLATFORM="darwin-x64"
    if (
      set -e
      # Resolve the real download URL from Cursor's download API.
      CURSOR_URL=$(curl -fsSL "https://www.cursor.com/api/download?platform=$CURSOR_PLATFORM&releaseTrack=stable" \
        | sed -n 's/.*"downloadUrl":"\([^"]*\)".*/\1/p')
      [ -n "$CURSOR_URL" ]
      curl -fsSL "$CURSOR_URL" -o /tmp/Cursor.dmg
      hdiutil attach /tmp/Cursor.dmg -quiet -nobrowse -mountpoint /tmp/cursor-mount
      cp -R /tmp/cursor-mount/Cursor.app /Applications/
      hdiutil detach /tmp/cursor-mount -quiet
    ); then
      info "Cursor installed"
    else
      hdiutil detach /tmp/cursor-mount -quiet 2>/dev/null || true
      fail "Cursor install failed — continuing"
    fi
    rm -f /tmp/Cursor.dmg
  else
    skip
  fi
else
  info "Cursor already installed"
fi

# --- Claude Code (https://claude.ai/download) ---
if ! command -v claude &> /dev/null; then
  if ask "Install Claude Code?"; then
    curl -fsSL https://claude.ai/install.sh | bash
    info "Claude Code installed"
  else
    skip
  fi
else
  info "Claude Code already installed ($(claude --version 2>/dev/null))"
fi

# --- AWS CLI v2 (https://aws.amazon.com/cli/) ---
if ! command -v aws &> /dev/null; then
  if ask "Install AWS CLI v2? (requires sudo)"; then
    if (
      set -e
      curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o /tmp/AWSCLIV2.pkg
      sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
    ); then
      info "AWS CLI installed ($(aws --version 2>&1))"
    else
      fail "AWS CLI install failed — continuing"
    fi
    rm -f /tmp/AWSCLIV2.pkg
  else
    skip
  fi
else
  info "AWS CLI already installed ($(aws --version 2>&1 | cut -d' ' -f1))"
fi

# ============================================================
# PHASE 2: Configuration
# ============================================================

echo ""
echo "── Phase 2: Configuration ─────────────"

# --- Zsh ---
if ask "Set up zsh config? (.zshrc with Oh My Zsh, plugins, aliases)"; then
  ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
  info "~/.zshrc -> $DOTFILES_DIR/.zshrc"
else
  skip
fi

# --- iTerm2 ---
if ask "Set up iTerm2 preferences?"; then
  cp "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist" ~/Library/Preferences/com.googlecode.iterm2.plist
  info "iTerm2 preferences restored"
  warn "Restart iTerm2 to apply changes"
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
        cursor --install-extension "$ext" --force 2>/dev/null && info "$ext" || fail "$ext"
      done < "$DOTFILES_DIR/cursor/extensions.txt"
    else
      fail "cursor command not found — install Cursor first"
    fi
  else
    skip
  fi
else
  skip
fi

# --- Claude Code ---
if ask "Set up Claude Code? (settings + skills + commands)"; then
  mkdir -p ~/.claude/skills
  ln -sf "$DOTFILES_DIR/.claude/settings.json" ~/.claude/settings.json
  ln -sf "$DOTFILES_DIR/.claude/statusline-command.sh" ~/.claude/statusline-command.sh
  info "Claude Code settings symlinked"

  # Skills are symlinked individually so Claude-installed skills can coexist.
  for skill in "$DOTFILES_DIR"/.claude/skills/*/; do
    skill_name="$(basename "$skill")"
    ln -sfn "$skill" ~/.claude/skills/"$skill_name"
    info "Skill: $skill_name"
  done

  # Commands: symlink the whole dir so new commands sync automatically.
  ln -sfn "$DOTFILES_DIR/.claude/commands" ~/.claude/commands
  info "Commands symlinked"
else
  skip
fi

# --- Claude Code plugins (reinstalled from manifest, not committed) ---
if command -v claude &> /dev/null && [ -f "$DOTFILES_DIR/.claude/plugins.txt" ]; then
  if ask "Restore Claude Code plugins from plugins.txt?"; then
    while read -r kind arg; do
      [[ -z "$kind" || "$kind" == \#* ]] && continue
      case "$kind" in
        marketplace) claude plugin marketplace add "$arg" >/dev/null 2>&1 && info "marketplace: $arg" || warn "marketplace failed: $arg" ;;
        plugin)      claude plugin install "$arg"          >/dev/null 2>&1 && info "plugin: $arg"      || warn "plugin failed: $arg" ;;
      esac
    done < "$DOTFILES_DIR/.claude/plugins.txt"
    warn "Restart Claude Code to load newly installed plugins"
  else
    skip
  fi
fi

# ============================================================
# Post-Setup
# ============================================================

echo ""
echo "── Post-Setup ─────────────────────────"
if [ -f ~/.secrets ]; then
  info "~/.secrets exists"
else
  warn "Create ~/.secrets with your tokens:"
  echo "    export GITLAB_TOKEN=\"...\""
  echo "    export JIRA_USER=\"...\""
  echo "    export JIRA_TOKEN=\"...\""
  echo "    export SLACK_TOKEN=\"...\""
fi

echo ""
echo "Done!"
