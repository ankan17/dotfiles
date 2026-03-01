# GitLab MR Creation Examples

## Example 1: Simple Feature MR

**User**: "Create an MR for my changes"

**Agent workflow**:

```bash
# Step 1: Get branch info
git branch --show-current
# Output: feat/add-user-validation

git remote get-url origin
# Output: git@gitlab.hyperverge.co:vkyc/streaming-server.git

# Step 2: Check target branch
git ls-remote --heads origin dev
# Output: abc123 refs/heads/dev (exists!)

# Step 3: Analyze changes
git log origin/dev..HEAD --oneline
# Output:
# a1b2c3d Add email validation
# e4f5g6h Add phone validation helper

git diff origin/dev..HEAD --stat
# Output:
# src/validators/email.ts  | 45 ++++++++++++++
# src/validators/phone.ts  | 32 ++++++++++
# tests/validators.spec.ts | 78 ++++++++++++++++++++++++
# 3 files changed, 155 insertions(+)
```

**Generated MR**:

- **Title**: `feat: Add email and phone validation`
- **Target**: `dev`
- **Description**:

```markdown
## Description

Adding input validation for email and phone fields. This includes:
- Email validation with RFC 5322 compliant regex
- Phone validation supporting international formats

This change improves data quality by catching invalid inputs before they reach the database.

## Test Plan

1. Run unit tests: `npm test -- --grep "validators"`
2. Manual testing:
   - Try valid emails (user@example.com) → should pass
   - Try invalid emails (user@) → should fail
   - Try valid phones (+1-555-123-4567) → should pass
   - Try invalid phones (abc) → should fail

## QA Risk

Low. Changes are additive and covered by unit tests. Rollback is straightforward if issues arise.

## Additional Checklist Items

- [x] Double-check your branch is based on `dev` and targets `dev`
- [ ] CHANGELOG entry has been created
- [x] Code is well-commented, linted and follows project conventions
- [x] Automated tests have been added for the changes (we are going for 100% coverage!)
- [ ] Postman collection has been updated, if relevant
- [ ] README has been updated, if relevant
- [ ] Notion documentation for workflow config has been updated, if relevant
- [ ] Whitelisting/blacklisting updated for kubera logger, if relevant
- [ ] Use of indexes have been considered and the documention has been updated
- [ ] Release notes have been created/updated as part of the release
```

---

## Example 2: Bug Fix MR

**User**: "Push and create MR"

**Agent workflow**:

```bash
# Push first if needed
git push -u origin HEAD

# Then follow standard workflow...
```

**Generated MR**:

- **Title**: `fix: Resolve race condition in session cleanup`
- **Target**: `dev`

---

## Example 3: Fallback to main branch

When `dev` doesn't exist:

```bash
git ls-remote --heads origin dev
# (no output - doesn't exist)

git ls-remote --heads origin main
# Output: def456 refs/heads/main

# Target branch will be: main
```

---

## API Response Examples

**Success**:
```json
{
  "id": 12345,
  "iid": 42,
  "title": "feat: Add user validation",
  "web_url": "https://gitlab.hyperverge.co/vkyc/streaming-server/-/merge_requests/42",
  "state": "opened"
}
```

**MR Already Exists**:
```json
{
  "message": ["Another open merge request already exists for this source branch: !41"]
}
```

**Unauthorized**:
```json
{
  "message": "401 Unauthorized"
}
```
