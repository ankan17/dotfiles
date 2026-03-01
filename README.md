# Dotfiles

Personal configuration files and tools, managed with symlinks.

## Setup

```bash
git clone git@github.com:ankan17/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

Then create `~/.secrets` with your tokens (not tracked):

```bash
export GITLAB_TOKEN="..."
export JIRA_USER="..."
export JIRA_TOKEN="..."
export SLACK_TOKEN="..."
```

## Contents

### Shell
- `.zshrc` — Oh My Zsh config (oxide theme, git/docker/autosuggestions/syntax-highlighting plugins)

### VS Code (`vscode/`)
- `settings.json` — theme (Cobalt2), font (JetBrains Mono), editor preferences
- `keybindings.json` — custom keybindings (alt+p for prettify JSON)

### Cursor (`cursor/`)
- `settings.json` — theme (Cobalt2), font, editor and Cursor-specific preferences
- `keybindings.json` — custom keybindings (alt+p for prettify JSON, cmd+i for composer agent)
- `extensions.txt` — installed extensions list (auto-installed by `setup.sh`)

### Claude Code (`claude/`)
- `settings.json` — global Claude Code settings (enabled plugins)
- `skills/create-gitlab-mr` — custom skill for creating GitLab merge requests
- `skills/create-jira` — custom skill for creating Jira tickets
- `skills/review-mr` — custom skill for reviewing merge requests

