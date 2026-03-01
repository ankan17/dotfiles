# Dotfiles

Personal configuration files and tools, managed with symlinks. Editing config files in their usual locations (e.g. `~/.zshrc`, VS Code settings) automatically updates this repo since they're symlinked to it.

## Quick Start

```bash
git clone git@github.com:ankan17/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

The setup script is interactive — it will ask before setting up each component, so you can skip anything you don't need on a particular machine.

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
- **Theme:** [oxide](https://github.com/dikiaap/dotfiles)
- **Plugins:** git, docker, zsh-autosuggestions, zsh-syntax-highlighting
- **Aliases:**
  - `aws-login` — source AWS login script
  - `gs` — `git stash`
  - `sshc` — SSH into EC2 instances via helper script
  - `cursor` — launch Cursor from terminal
- **Runtime:** Bun (completions + PATH), Zscaler CA cert for Node
- **Secrets:** sourced from `~/.secrets` (not tracked)

**Symlink:** `~/.zshrc` -> `~/dotfiles/.zshrc`

**Prerequisites:** [Oh My Zsh](https://ohmyz.sh/), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

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

## How It Works

All config files live in this repo as the source of truth. The `setup.sh` script creates symlinks from the expected locations to this repo:

```
~/.zshrc                                          -> ~/dotfiles/.zshrc
~/Library/Application Support/Code/User/*.json    -> ~/dotfiles/vscode/*
~/Library/Application Support/Cursor/User/*.json  -> ~/dotfiles/cursor/*
~/.claude/settings.json                           -> ~/dotfiles/claude/settings.json
~/.claude/skills/*                                -> ~/dotfiles/claude/skills/*
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
