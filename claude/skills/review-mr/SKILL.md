---
name: review-mr
description: Review a merge request (MR) or pull request (PR) for code quality. Use when the user asks to review an MR, PR, merge request, pull request, or code changes in a branch.
argument-hint: "[MR/PR URL or number]"
---

# Merge Request Code Quality Review

Review the merge request specified by `$ARGUMENTS`.

## Step 1: Gather MR Context

- If a URL or number is provided, use `gh pr diff $ARGUMENTS` and `gh pr view $ARGUMENTS` to fetch the diff and metadata.
- If no argument is provided, use `gh pr list` to show open PRs and ask which one to review.
- Identify all changed files and the scope of the changes.

## Step 2: Understand the Changes

- Read the full diff carefully.
- Read the surrounding code in modified files for context (not just the diff lines).
- Understand the intent: what problem does this MR solve?

## Step 3: Code Quality Analysis

Evaluate the changes across these dimensions:

### Correctness & Bugs
- Logic errors, off-by-one mistakes, wrong conditions
- Null/undefined dereferences, unhandled edge cases
- Race conditions or concurrency issues
- Incorrect API usage or contract violations

### Security
- Injection risks (SQL, XSS, command injection)
- Improper input validation or sanitization
- Hardcoded secrets, credentials, or tokens
- Insecure cryptographic or auth patterns
- Exposure of sensitive data in logs or responses

### Performance
- Unnecessary loops, redundant computations
- N+1 query patterns or missing indexes
- Memory leaks or unbounded growth
- Missing caching opportunities for hot paths

### Error Handling
- Swallowed exceptions or silent failures
- Missing error propagation or incorrect status codes
- Insufficient logging for debugging failures
- Missing retries or timeouts for external calls

### Design & Maintainability
- Adherence to existing codebase patterns and conventions
- Appropriate abstractions (not over- or under-engineered)
- Clear naming and code readability
- Single Responsibility: does each function/class do one thing?
- DRY violations (duplicated logic that should be shared)

### Testing
- Are new code paths covered by tests?
- Are edge cases and error paths tested?
- Do tests actually assert meaningful behavior (not just "no crash")?
- Are there missing integration or regression tests?

## Step 4: Produce the Review

Output the review in this format:

```
## MR Review: <title>

### Summary
<1-2 sentence summary of what the MR does and its overall quality>

### Critical Issues
<Issues that MUST be fixed before merge — bugs, security flaws, data loss risks>
- **[File:Line]** Description of issue and suggested fix

### Suggestions
<Non-blocking improvements — better patterns, readability, performance>
- **[File:Line]** Description and recommendation

### Nitpicks
<Minor style or preference items>
- **[File:Line]** Note

### What Looks Good
<Positive callouts — well-written code, good test coverage, clean design>

### Verdict
🟢 **Approve** — Good to merge (possibly with minor suggestions)
🟡 **Approve with comments** — Merge after addressing suggestions
🔴 **Request changes** — Critical issues must be resolved first
```

## Guidelines
- Be specific: always reference the exact file and line.
- Be constructive: suggest fixes, not just problems.
- Be proportional: don't nitpick trivially on a large feature MR; focus on what matters.
- Respect existing conventions: don't suggest rewriting the codebase style in an MR review.
- If the MR is clean, say so — don't manufacture issues.
