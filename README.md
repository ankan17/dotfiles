# Dotfiles

Personal configuration files and tools, managed with symlinks. Editing config files in their usual locations (e.g. `~/.zshrc`, VS Code settings) automatically updates this repo since they're symlinked to it.

## Quick Start

```bash
git clone git@github.com:ankan17/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

The setup script runs in two phases:

1. **Tool Installation** — installs missing tools via Homebrew (iTerm2, zsh, VS Code, Cursor, Claude Code, Bun) and sets up Oh My Zsh with plugins
2. **Configuration** — symlinks config files from this repo to their expected locations

Each step is interactive — it will ask before installing or configuring anything. Pass `--all` to skip prompts.

### Post-Setup

Create `~/.secrets` with your tokens (never tracked in git):

```bash
export GITLAB_TOKEN="..."
export JIRA_USER="..."
export JIRA_TOKEN="..."
export SLACK_TOKEN="..."
```

This file is sourced automatically by `.zshrc`.

## What's Included

### Shell (`.zshrc`)

Oh My Zsh configuration with:

- **Theme:** [oxide](https://github.com/dikiaap/dotfiles) (built-in OMZ theme)
- **Plugins:**
  - `git` — git aliases and completions (built-in)
  - `docker` — docker completions (built-in)
  - [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) — fish-like autosuggestions (cloned to `~/.oh-my-zsh/custom/plugins/`)
  - [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting) — syntax highlighting in the shell (cloned to `~/.oh-my-zsh/custom/plugins/`)
- **Aliases:**
  - `aws-login` — source AWS login script
  - `gs` — `git stash`
  - `sshc` — SSH into EC2 instances via helper script
  - `cursor` — launch Cursor from terminal
- **Runtime:** Bun (completions + PATH), Zscaler CA cert for Node
- **Secrets:** sourced from `~/.secrets` (not tracked)

**Symlink:** `~/.zshrc` -> `~/dotfiles/.zshrc`

### iTerm2 (`iterm2/`)

Full iTerm2 preferences including profiles, colors, fonts, and keybindings.

| File | Description |
|------|-------------|
| `com.googlecode.iterm2.plist` | Complete iTerm2 preferences (restored via copy, not symlink) |

Unlike other configs, iTerm2 preferences are **copied** (not symlinked) because iTerm2 rewrites its plist frequently. To save updated preferences back to the repo:

```bash
cp ~/Library/Preferences/com.googlecode.iterm2.plist ~/dotfiles/iterm2/
```

### VS Code (`vscode/`)

| File | Description |
|------|-------------|
| `settings.json` | Cobalt2 theme, Material Icon theme, JetBrains Mono font, tab size 2, render whitespace |
| `keybindings.json` | `alt+p` — prettify JSON |

**Symlinks:** `~/Library/Application Support/Code/User/{settings,keybindings}.json` -> `~/dotfiles/vscode/*`

### Cursor (`cursor/`)

| File | Description |
|------|-------------|
| `settings.json` | Cobalt2 theme, Material Icon theme, JetBrains Mono font, Prettier as JS formatter, Docker link scheme support |
| `keybindings.json` | `alt+p` — prettify JSON, `cmd+i` — composer agent mode |
| `extensions.txt` | Installed extensions list (auto-installed by `setup.sh`) |

**Extensions included:**
- **Theme/UI:** Cobalt2, Material Icon Theme, Custom CSS
- **Languages:** Python (+ Pylance, debugpy), ESLint, Prettier
- **Git:** GitLens, Live Share
- **Tools:** Docker, Bookmarks, Live Server, Makefile Tools, SonarLint, Markdown Preview Enhanced
- **AI:** Claude Code

**Symlinks:** `~/Library/Application Support/Cursor/User/{settings,keybindings}.json` -> `~/dotfiles/cursor/*`

To update the extensions list after installing/removing extensions:
```bash
cursor --list-extensions | sort > ~/dotfiles/cursor/extensions.txt
```

### Claude Code (`claude/`)

| File | Description |
|------|-------------|
| `settings.json` | Global settings (enabled plugins: Slack) |
| `skills/create-gitlab-mr/` | Custom `/create-gitlab-mr` slash command — creates GitLab MRs with auto-detected target branch, MR templates, and Jira linking |
| `skills/create-jira/` | Custom `/create-jira` slash command — creates Jira issues from Claude Code |
| `skills/review-mr/` | Custom `/review-mr` slash command — reviews merge requests for code quality |

**Symlinks:** `~/.claude/settings.json` -> `~/dotfiles/claude/settings.json`, `~/.claude/skills/*` -> `~/dotfiles/claude/skills/*`

## Tool Installation

The setup script can install these tools if they're missing:

| Tool | Install Method | Notes |
|------|---------------|-------|
| [Homebrew](https://brew.sh/) | Official installer | Required for other installs |
| [iTerm2](https://iterm2.com/) | `brew install --cask iterm2` | Terminal emulator |
| [zsh](https://www.zsh.org/) | `brew install zsh` | macOS ships with zsh, this ensures latest |
| [Oh My Zsh](https://ohmyz.sh/) | Official installer | Zsh framework for plugins and themes |
| [VS Code](https://code.visualstudio.com/) | `brew install --cask visual-studio-code` | Code editor |
| [Cursor](https://cursor.com/) | `brew install --cask cursor` | AI code editor |
| [Claude Code](https://claude.com/claude-code) | `npm install -g @anthropic-ai/claude-code` | CLI AI coding assistant |
| [Bun](https://bun.sh/) | Official installer | JS runtime and package manager |

## How It Works

All config files live in this repo as the source of truth. The `setup.sh` script creates symlinks from the expected locations to this repo:

```
~/.zshrc                                          -> ~/dotfiles/.zshrc
~/Library/Application Support/Code/User/*.json    -> ~/dotfiles/vscode/*
~/Library/Application Support/Cursor/User/*.json  -> ~/dotfiles/cursor/*
~/.claude/settings.json                           -> ~/dotfiles/claude/settings.json
~/.claude/skills/*                                -> ~/dotfiles/claude/skills/*
~/Library/Preferences/com.googlecode.iterm2.plist <- ~/dotfiles/iterm2/* (copied)
```

Any changes made through normal usage (e.g. changing a VS Code setting via the UI) are automatically reflected in the repo. Just commit and push to sync.

## Syncing Changes

```bash
cd ~/dotfiles
git add -A && git commit -m "description of change"
git push
```

On another machine:
```bash
cd ~/dotfiles && git pull
```

No re-linking needed — symlinks still point to the same files.

For iTerm2 (not symlinked), re-run the setup or copy manually:
```bash
cp ~/dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/
```
