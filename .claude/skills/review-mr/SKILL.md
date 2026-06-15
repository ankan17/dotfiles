---
name: review-mr
description: Review a merge request (MR) or pull request (PR) for code quality, then interactively post review comments to GitLab. Use when the user asks to review an MR, PR, merge request, pull request, review code changes in a branch, or pastes a GitLab/GitHub MR/PR URL for review. Also triggers when the user says "review this", "check this MR", "look at this merge request", or similar.
argument-hint: "<MR/PR URL>"
---

# Review Merge Request

Review an MR's code changes, then walk the user through each finding so they can post, modify, or skip comments on the MR.

## Step 1: Parse the MR

Run `python3 ~/.claude/lib/gitlab_mr.py parse_url "$ARGUMENTS"` to extract `host`, `project_id`, `project_path`, and `mr_iid`.

Then fetch MR metadata:
```
python3 ~/.claude/lib/gitlab_mr.py mr_info <HOST> <PROJECT_ID> <MR_IID>
```

Tell the user: "Reviewing MR !<IID>: <title>"

## Step 2: Fetch the diff

```
python3 ~/.claude/lib/gitlab_mr.py mr_diff <HOST> <PROJECT_ID> <MR_IID>
```

Save the `diff_refs` (you'll need `base_sha`, `head_sha`, `start_sha` for posting inline comments later).

## Step 3: Load review guidelines

Check if a `REVIEW.md` exists in the current working directory. If it does, read it — it defines severity levels, what to flag, what to ignore, and comment format. Follow those rules during the review.

If no `REVIEW.md` exists, use these defaults:
- **blocker**: bugs, security issues, data loss, broken API contracts
- **warning**: performance issues, error handling gaps, test gaps, readability
- **nit**: minor naming, idiomatic alternatives, clarity improvements

## Step 4: Review the code

Check for a project-level code-reviewer subagent at `.claude/agents/code-reviewer.md` in the current repo. If found, invoke it via the Agent tool with the MR diff. If not found, check `~/.claude/agents/code-reviewer.md`. If neither exists, review the diff yourself following the guidelines from Step 3.

When invoking the code-reviewer subagent, pass:
- The full diff content from Step 2
- The instruction to follow `REVIEW.md` if present
- Request output as a structured list of findings with: severity, file path, line number, description, and suggested fix

Parse the subagent's output into a list of review comments.

## Step 5: Interactive comment review

Present each finding to the user one at a time, numbered. For each:

```
── Comment 1/N ──
**blocker**: `server/userlink/userlink.service.ts:42` — Missing null check on userLinkDetails

The function accesses `userLinkDetails.url` without checking if `userLinkDetails` is null,
which will throw a TypeError if the user doesn't have a link entry.

Suggested fix:
  if (!userLinkDetails) {
    throw new BadRequestException('User link not found');
  }

[P]ost · [M]odify · [S]kip ─────
```

Wait for the user's response:

- **Post (p)**: Append the trailer and post the comment to the MR
- **Modify (m)**: Ask the user for their edited version, then show it back for confirmation before posting
- **Skip (s)**: Move to the next comment without posting

If the user responds with anything else (like editing the comment text directly), treat it as a modification.

## Step 6: Post comments

For each comment the user approves, append this trailer to the body:

```
\n\n_Reviewed by Claude (Opus 4.6)_
```

Post inline comments using:
```
python3 ~/.claude/lib/gitlab_mr.py post_discussion <HOST> <PROJECT_ID> <MR_IID> "<BODY>" <NEW_PATH> <NEW_LINE> <OLD_PATH> <OLD_LINE> <BASE_SHA> <HEAD_SHA> <START_SHA>
```

Use `_` as a placeholder for position args that don't apply (e.g., `_` for `old_line` on added lines).

For comments that aren't tied to a specific line, post as a general discussion (omit position args).

## Step 7: Summary

After processing all comments, show a summary:

```
Review complete:
  Posted: 3 comments (1 blocker, 2 warnings)
  Skipped: 2
  Modified: 1

MR: <web_url>
```

## Rules

- Only review code in the MR diff — do not flag issues in unchanged code
- If a pre-existing issue is made worse by the MR, flag it
- Do not generate more than 15 comments — prioritize blockers > warnings > nits
- Be concise — developers read many reviews
- If the diff is clean, tell the user "No issues found — LGTM" and ask if they want to post an approval comment
