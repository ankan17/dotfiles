---
name: create-gitlab-mr
description: Creates a GitLab Merge Request from the current branch using GitLab APIs. Automatically determines target branch (dev → main → master), rebases on it, uses project MR templates if available, verifies and attempts to fulfil checklist items, asks for Jira ticket number, and handles repo-to-project mapping. Use when the user asks to create an MR, raise a merge request, push and create MR, or open a GitLab MR.
---

# Create GitLab Merge Request

Creates an MR from the current branch to the appropriate target branch using GitLab APIs.

> **IMPORTANT — Read before executing:**
> - You MUST follow **every step below in order**. Do NOT skip or reorder steps.
> - You MUST rebase on the target branch before pushing (Step 4).
> - You MUST verify checklist items and attempt to fulfil any that are not yet done (Step 7).
> - You MUST ask the user for a Jira ticket number (Step 9) — this is interactive and blocking.
> - You MUST use the MR description template (Step 6) or a project template (Step 5) — never a one-line description.
> - Do NOT delegate this workflow to a subagent with a freeform prompt. Execute each step yourself.

## Preferences (follow these conventions)

### MR title

- **With Jira ticket**: `<TICKET> Short description in title case` — e.g. `HP-29886 Generic webhook subscription check and retryable config API`. Do not prefix with `feat:` or `fix:` when a Jira ticket is present.
- **Without Jira ticket**: `Short description of changes` (title case, or keep commit-style like `feat: short description` if that is the project norm).

### Checklist items that do not apply (N/A)

When a checklist item is **not applicable** to the changes, do **not** leave it unchecked. Instead:

1. Mark it as done: `[x]`
2. Strikethrough the item text and append the N/A reason: `~item text~ N/A, because <reason>`

**Examples:**

- `- [x] ~Postman collection has been updated, if relevant~ N/A, as no new APIs added or existing APIs modified`
- `- [x] ~Notion documentation for workflow config has been updated, if relevant~ N/A, because no workflow config change is present`
- `- [x] ~Whitelisting/blacklisting updated for kubera logger, if relevant~ N/A, because no API request-response changes are present`
- `- [x] ~Use of indexes have been considered and the documentation has been updated~ N/A, because no DB changes are present`
- `- [x] ~Release notes have been created/updated as part of the release~ N/A, because it is an internal change`

Use clear, concise reasons so reviewers see why the item was skipped.

## Prerequisites

- `GITLAB_TOKEN` environment variable with API access (read_api, write_repository scopes)
- Git remote configured pointing to GitLab

## Workflow

### Step 1: Gather Repository Information

```bash
# Get current branch
git branch --show-current

# Get remote URL
git remote get-url origin

# Check working tree status
git status -sb
```

### Step 2: Extract GitLab Project Path

Parse the remote URL to get the project path:

| Remote Format | Example | Project Path |
|---------------|---------|--------------|
| SSH | `git@gitlab.com:group/project.git` | `group/project` |
| HTTPS | `https://gitlab.com/group/project.git` | `group/project` |

Remove `.git` suffix if present.

### Step 3: Determine Target Branch

Check which target branch exists (in order of preference):

```bash
# Check for dev branch
git ls-remote --heads origin dev

# If not found, check main
git ls-remote --heads origin main

# If not found, fallback to master
git ls-remote --heads origin master
```

Use the first branch that exists.

### Step 4: Rebase on Target Branch (MANDATORY)

Before pushing, ensure the feature branch is up to date with the remote target branch:

```bash
git fetch origin <target_branch>
git rebase origin/<target_branch>
```

- If the rebase succeeds cleanly, proceed to Step 5.
- If there are conflicts, **stop and inform the user**. List the conflicting files and ask the user to resolve them before continuing. Do NOT force-push or skip the rebase.

### Step 5: Analyze Changes for MR Description

```bash
# Get commits on this branch vs target
git log origin/<target>..HEAD --oneline

# Get diff summary
git diff origin/<target>..HEAD --stat
```

### Step 6: Check for Project MR Templates

Before generating the description, check if the project has MR templates:

```bash
# Check for MR templates
ls .gitlab/merge_request_templates/*.md 2>/dev/null
```

**Template selection logic:**
- If templates exist and only one → use that template
- If multiple templates exist → ask user which template to use
- If no templates exist → use the default template (see Step 7)

When using a project template, read its contents and fill in the sections based on the analyzed changes.

### Step 7: Generate MR Description and Verify Checklist (MANDATORY)

#### 7a: Draft the MR description

**If no project template exists**, use this default template exactly:

```markdown
## Description

What are you changing? Why are you changing it?

## Test Plan

How to manually test the changes? What all should be considered while testing?

## QA Risk

If something goes wrong, what's the worst that could happen? Classify it as Low, Medium, or High.

## Additional Checklist Items

- [ ] Double-check your branch is based on `dev` and targets `dev`
- [ ] CHANGELOG entry has been created
- [ ] Code is well-commented, linted and follows project conventions
- [ ] Automated tests have been added for the changes (we are going for 100% coverage!)
- [ ] Postman collection has been updated, if relevant
- [ ] README has been updated, if relevant
- [ ] Notion documentation for workflow config has been updated, if relevant
- [ ] Whitelisting/blacklisting updated for kubera logger, if relevant
- [ ] Use of indexes have been considered and the documention has been updated
- [ ] Release notes have been created/updated as part of the release
```

Fill in the Description, Test Plan, and QA Risk sections based on the analyzed changes. Keep every checklist item — do not remove any.

#### 7b: Verify and attempt to fulfil each checklist item (MANDATORY — DO NOT SKIP)

Go through **every checklist item** and determine its status:

- **Done**: Mark `[x]` and keep the item text as-is.
- **Not applicable**: Mark `[x]` and use strikethrough + N/A reason: `~item text~ N/A, because <reason>` (see Preferences above). Do not leave N/A items unchecked.
- **Not done (applicable)**: Leave `[ ]` only when the item applies but has not been fulfilled; attempt to fulfil it first (e.g. add CHANGELOG, fix lint, update README).

Only after verification (and any changes made), update the checklist in the MR description.

| Checklist Item | How to verify | Action if not done |
|---|---|---|
| Branch is based on `dev` and targets `dev` | Check target branch from Step 3 and that rebase in Step 4 succeeded | Already handled by Steps 3–4. Mark `[x]` if target is `dev`. |
| CHANGELOG entry has been created | Check if `CHANGELOG.md` (or similar) exists and has an entry for this branch/version | **Add a CHANGELOG entry** summarising the changes. Follow the existing format in the file. If no CHANGELOG file exists, skip (leave `[ ]`). |
| Code is well-commented, linted and follows project conventions | Run the project's lint command (e.g. `npm run lint`, `npm run lint:test`) | **Fix any lint errors** introduced by the current changes. Mark `[x]` only if lint passes. |
| Automated tests have been added | Check if spec/test files were added or modified in the diff | If no tests were added and the changes are testable, inform the user. Do not auto-generate tests unless asked. |
| Postman collection has been updated | Check if any API routes were added/changed in the diff | If no new/modified APIs → mark `[x]` with `~...~ N/A, as no new APIs added or existing APIs modified`. If relevant, remind the user to update Postman; leave `[ ]` until they do. |
| README has been updated | Check if the diff warrants a README change (new env vars, new setup steps) | **Update the README** if new env vars or setup steps were introduced. Otherwise mark `[x]` with N/A reason if not relevant. |
| Notion documentation updated | Check if workflow config or similar changed in the diff | If no workflow config change → mark `[x]` with `~...~ N/A, because no workflow config change is present`. |
| Whitelisting/blacklisting updated for kubera logger | Check if new API routes or request/response fields were added | If no API request/response changes → mark `[x]` with `~...~ N/A, because no API request-response changes are present`. |
| Indexes considered and documented | Check if new DB queries or schema changes exist in the diff | If no DB changes → mark `[x]` with `~...~ N/A, because no DB changes are present`. |
| Release notes created/updated | Check if a release notes file exists and if this is a release-facing change | If internal-only or no release notes file → mark `[x]` with `~...~ N/A, because it is an internal change` (or similar). If file exists and relevant, add an entry. |

**After making any changes** (CHANGELOG, lint fixes, README updates, etc.):

```bash
git add -A
git commit -m "chore: pre-MR checklist fixes"
```

Then update the checklist marks in the MR description to reflect the final state.

### Step 8: Push Branch

```bash
git push -u origin HEAD
```

If the push is rejected (e.g. after rebase changed history), use:

```bash
git push --force-with-lease origin HEAD
```

### Step 9: Ask for Jira Ticket Number (MANDATORY — DO NOT SKIP)

**You MUST ask the user** for a Jira ticket number before proceeding to Step 10. Do not assume or skip this step.

Use the AskQuestion tool or a direct message to ask:

> Do you have a Jira ticket number for this MR? (e.g., HP-1234)

Wait for the user's response before continuing.

**MR title format** (see Preferences above):
- User provides ticket number → `<TICKET> Short description in title case` (e.g. `HP-29886 Generic webhook subscription check and retryable config API`). Do not add `feat:` or `fix:` when Jira is present.
- User says none / skip → `Short description of changes` (title case)

### Step 10: Create MR via GitLab API

```bash
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "source_branch": "<current_branch>",
    "target_branch": "<target_branch>",
    "title": "<MR title>",
    "description": "<generated description>",
    "remove_source_branch": true
  }' \
  "https://gitlab.com/api/v4/projects/<url_encoded_project_path>/merge_requests"
```

**Important**: URL-encode the project path (e.g., `group/project` → `group%2Fproject`).

### Step 11: Output Result

On success, display:
- MR URL (from response `web_url`)
- MR IID (from response `iid`)
- Target branch used

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid/missing token | Check `GITLAB_TOKEN` is set and valid |
| 404 Not Found | Project path incorrect | Verify remote URL parsing |
| 409 Conflict | MR already exists | Show existing MR URL |
| Rebase conflict | Diverged from target | List conflicts, ask user to resolve |
| Push rejected | Remote has newer commits | Use `--force-with-lease` after rebase |

## GitLab Host Detection

For self-hosted GitLab instances, extract the host from the remote URL:

- `git@gitlab.hyperverge.co:group/project.git` → `https://gitlab.hyperverge.co`
- `https://gitlab.company.com/group/project.git` → `https://gitlab.company.com`

## Example Usage

**User request**: "Create an MR for my changes"

**Agent actions**:
1. Run `git branch --show-current` → `feat/add-user-auth`
2. Run `git remote get-url origin` → `git@gitlab.hyperverge.co:vkyc/streaming-server.git`
3. Extract: host=`gitlab.hyperverge.co`, project=`vkyc/streaming-server`
4. Check branches: `dev` exists → target=`dev`
5. Rebase: `git fetch origin dev && git rebase origin/dev` → clean
6. Analyze changes with `git log` and `git diff`
7. Check for templates: `ls .gitlab/merge_request_templates/*.md` → found `Default.md`
8. Read template, fill in description, verify checklist:
   - CHANGELOG.md exists → add entry → `[x]`
   - `npm run lint:test` → passes → `[x]`
   - Tests added in diff → `[x]`
   - No new API routes → Postman N/A → `[x] ~Postman collection...~ N/A, as no new APIs added or existing APIs modified`
   - New env var added → update README → `[x]`
   - Commit checklist fixes: `git commit -m "chore: pre-MR checklist fixes"`
9. Push: `git push -u origin HEAD`
10. Ask user: "Do you have a Jira ticket number?" → user provides `HP-1234`
11. Generate title: `HP-1234 Add user authentication` (no `feat:` prefix; title case per Preferences)
12. Create MR via API
13. Return MR URL to user
