---
description: Add every missing week of progress (all repos + Claude Code, Codex and Cursor activity) to the Weekly Journal in the vault
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

Bring the **Weekly Journal** up to date. All file mutations go through Write/Edit; Bash is read-only here.

## Configuration

Read these environment variables with `printenv` (they live in the untracked `~/.aliases`). If `JOURNAL_VAULT` or `JOURNAL_PROJECT_DIRS` is unset, stop and ask the user for the value.

- `JOURNAL_VAULT`: Obsidian vault root. The journal is `$JOURNAL_VAULT/wiki/meta/Weekly Journal.md`; vault conventions are in `$JOURNAL_VAULT/CLAUDE.md`.
- `JOURNAL_PROJECT_DIRS`: colon-separated roots to scan for git repos (each root and its children up to two levels deep).
- `JOURNAL_CLAUDE_DIRS`: colon-separated Claude Code config dirs whose `projects/` hold session transcripts. Defaults to `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.

**Project overrides:** a repo is a *named project* when a `JOURNAL.md` exists in the repo root or any parent directory below its `JOURNAL_PROJECT_DIRS` root. Read every such file before gathering; it names the project's journal section and can override the author, add repos, and add gather/write rules for that project. Everything else falls under **Other work**.

## Weeks

- A week runs **Tuesday 00:00 to the following Tuesday 00:00, local time**, and is labelled by its Tuesday and Monday dates: `July 14–20, 2026`, or `July 28 – August 3, 2026` across a month boundary.
- Only complete weeks are written. Today's week is still in progress and is never written.
- Find the newest `## Week of` heading in the journal. Process **every complete week after it, oldest first, one week at a time**: finish gathering and writing one week before starting the next. If the journal has no weeks, process only the most recent complete week. If none are missing, say so and stop.
- Every source uses the same window. Convert UTC timestamps to local time before comparing.

## Gather (read-only, per week)

1. **Repos**: for each git repo, `git log --all --since=<Tue 00:00> --until=<next Tue 00:00>` for the author in that repo's `git config user.email` (or the author a `JOURNAL.md` names), then keep only commits whose **author date** is in the window (`--since` filters by committer date). Dedupe by hash across worktrees and clones of the same repo; when rebased stacks repeat a subject under several hashes, report the distinct-subject count too. Group by day. For named projects, identify the dominant feature(s), notable commits and merged PRs.
2. **Claude Code**: across every `projects/*` dir under each `JOURNAL_CLAUDE_DIRS` entry, date each `*.jsonl` session by the `timestamp` of its first line that has one (file mtime changes when a session is resumed, so never use it). Project dir names encode the working directory path, so attribute each session to a named project when that path falls under its `JOURNAL.md` directory. For sessions not in a named project, infer the topic from the FIRST user message only (`jq` the first `type=="user"` line; never read whole transcripts, they are large) and summarize by theme. Sessions that only ran `/weekly-journal`, `/model`, `/clear` or similar are bookkeeping: count them in Volume only.
3. **Codex**: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` and `~/.codex/archived_sessions/*.jsonl`. The first line (`type=="session_meta"`) has `payload.timestamp` (UTC; date by it in local time), `payload.cwd` for project attribution and `payload.originator`; the first `type=="event_msg"` line with `payload.type=="user_message"` has the opening prompt in `payload.message`. Count sessions whose originator is `Claude Code` as "Codex helper runs", separate from standalone sessions; automatic approval-review subagent runs are not work.
4. **Cursor**: query `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` read-only with `sqlite3 "file:<path>?immutable=1"` (it is several GB; never copy it, always filter in SQL). Each chat is a `cursorDiskKV` row keyed `composerData:<id>` with `createdAt` (epoch ms), `name`, and `trackedGitRepos[].repoPath` for project attribution. The opening prompt is the `text` of the first `bubbleId:<id>:%` row with `type` 1. Skip chats with no messages. Chats whose id appears in another chat's `subComposerIds` or `subagentComposerIds` are subagent traces: report their count, not as separate chats.
5. **Retention**: older transcripts get deleted. When a source has nothing on disk as old as the window, write "not retained" for it in Volume rather than zero, and say "partial" when retention starts inside the window.

## Write (per week)

6. Prepend a `## Week of <label> - <theme>` section directly above the newest week (below the intro), with one `###` subsection per named project that had activity (what shipped, key commits, themes), a `### Other work` subsection (other repos and other session themes with counts), and a closing `**Volume:**` line (commits with distinct subjects, per-source session counts for Claude Code, Codex standalone, Codex helper runs and Cursor, and the peak day). Fold session themes into the matching project or Other work subsection. Match the structure, depth and tone of the newest existing entry.
7. **Idempotency:** if a section for this week already exists, merge into it rather than adding a duplicate.
8. Write declaratively; don't invent detail beyond what commits and opening prompts support. Keep client names generic ("a client").
9. Set the journal frontmatter `updated:` to the week's Monday. If a new tool/entity surfaced, add a brief `wiki/entities/` page and link it.
10. Update `wiki/index.md` if needed, prepend a `## [YYYY-MM-DD] save | weekly journal (<label>)` entry to the TOP of `wiki/log.md` (today's date), and refresh the "Last Updated" + "Recent Changes" of `wiki/hot.md`.
11. If a week had zero commits and zero sessions, still add a short "quiet week" entry.

Follow the vault conventions in `$JOURNAL_VAULT/CLAUDE.md` (YAML frontmatter, wikilinks, keep it concise).
