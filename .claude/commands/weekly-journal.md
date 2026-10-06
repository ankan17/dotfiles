---
description: Append this past week's progress (all repos + all Claude Code activity) to the Weekly Journal in the vault
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

Update the **Weekly Journal** for the **past 7 days**. All file mutations go through Write/Edit; Bash is read-only here.

## Configuration

Read these environment variables with `printenv` (they live in the untracked `~/.aliases`). If `JOURNAL_VAULT` or `JOURNAL_PROJECT_DIRS` is unset, stop and ask the user for the value.

- `JOURNAL_VAULT`: Obsidian vault root. The journal is `$JOURNAL_VAULT/wiki/meta/Weekly Journal.md`; vault conventions are in `$JOURNAL_VAULT/CLAUDE.md`.
- `JOURNAL_PROJECT_DIRS`: colon-separated roots to scan for git repos (each root and its children up to two levels deep).
- `JOURNAL_CLAUDE_DIRS`: colon-separated Claude Code config dirs whose `projects/` hold session transcripts. Defaults to `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.

**Project overrides:** a repo is a *named project* when a `JOURNAL.md` exists in the repo root or any parent directory below its `JOURNAL_PROJECT_DIRS` root. Read every such file before gathering; it names the project's journal section and can override the author, add repos, and add gather/write rules for that project. Everything else falls under **Other work**.

## Gather (read-only)

1. **Repos**: for each git repo, `git log --all` since 7 days ago for the author in that repo's `git config user.email` (or the author a `JOURNAL.md` names); dedupe commit subjects and group by day. For named projects, identify the dominant feature(s) and notable commits.
2. **Claude Code activity**: across every `projects/*` dir under each `JOURNAL_CLAUDE_DIRS` entry, count `*.jsonl` files modified in the last 7 days; group by project; note peak day and totals. Project dir names encode the working directory path, so attribute each to a named project when that path falls under its `JOURNAL.md` directory. For sessions not in a named project, infer each session's topic cheaply from its FIRST user message only (`jq` the first `type=="user"` line; do NOT read whole transcripts, they are large) and summarize by theme.
3. **Codex activity**: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` and `~/.codex/archived_sessions/*.jsonl`, dated by the file name. The first line (`type=="session_meta"`) has `payload.cwd` for project attribution and `payload.originator`; the first `type=="event_msg"` line with `payload.type=="user_message"` has the opening prompt in `payload.message`. Sessions whose originator is `Claude Code` are Codex runs delegated from Claude Code: count them as "Codex helper runs", separate from standalone Codex sessions.
4. **Cursor activity**: query `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` read-only with `sqlite3 "file:<path>?immutable=1"` (it is several GB; never copy it, always filter in SQL). Each chat is a `cursorDiskKV` row keyed `composerData:<id>` with `createdAt` (epoch ms), `name`, and `trackedGitRepos[].repoPath` for project attribution. The opening prompt is the `text` of the first `bubbleId:<id>:%` row with `type` 1. Skip chats with no messages.

Count Claude Code, Codex and Cursor separately in the Volume line, and fold their themes into the matching project or **Other work** subsection.

## Write

5. Prepend a new `## Week of <Mon DD>–<Mon DD>, <YYYY>` section directly under the intro (newest week on top), with one subsection per named project that had activity (what shipped, key commits, themes), an **Other work** subsection (other repos + other Claude Code themes + counts), and a closing **Volume** line (commit + session totals, peak day).
6. **Idempotency:** if the most recent existing week section already overlaps this 7-day window, refine/merge into it rather than adding a duplicate.
7. Write declaratively; don't invent detail beyond what commits / first-prompts support.
8. If a new tool/entity surfaced, add a brief `wiki/entities/` page and link it.
9. Update `wiki/index.md` if needed, prepend a `## [YYYY-MM-DD] save | weekly journal` entry to the TOP of `wiki/log.md`, and refresh the "Last Updated" + "Recent Changes" of `wiki/hot.md`.
10. If there were zero commits and zero sessions in the window, still add a short "quiet week" entry.

Follow the vault conventions in `$JOURNAL_VAULT/CLAUDE.md` (YAML frontmatter, wikilinks, keep it concise).
