---
name: create-jira
description: This skill should be used when the user asks to "create a JIRA ticket", "file a JIRA issue", "open a JIRA bug", "create a story in JIRA", "make a JIRA epic", "log a task in JIRA", mentions creating issues in the HP project, or wants to submit requirements, bugs, or feature requests to JIRA.
tools: Bash
---

# Create JIRA Ticket

Create well-structured JIRA tickets via the Atlassian REST API v3 for the HyperVerge JIRA instance.

## Philosophy

Ticket descriptions focus on **WHAT** and **WHY**, never on implementation details. Write requirements as clear prose that any engineer can understand. Include a high-level approach only when it genuinely adds value and keeps it directional (no code, no specific libraries, no architecture diagrams). The goal is a ticket that communicates intent and acceptance criteria, not a design document.

## Pre-flight Check

Before doing anything else, verify that the required environment variables are set:

```bash
if [ -z "$JIRA_USER" ] || [ -z "$JIRA_TOKEN" ]; then
  echo "ERROR: JIRA_USER and JIRA_TOKEN environment variables must be set."
  echo "  export JIRA_USER='your-email@hyperverge.co'"
  echo "  export JIRA_TOKEN='your-atlassian-api-token'"
  echo "Generate a token at: https://id.atlassian.com/manage-profile/security/api-tokens"
  exit 1
fi
echo "Pre-flight check passed. JIRA credentials are configured."
```

Run this check first. If it fails, inform the user and stop.

## Information Gathering

Collect the following fields. If invoked with arguments (e.g., `/create-jira Fix login timeout on slow networks`), use them as the starting point for the summary and infer other fields from context.

### Required Fields

- **Summary**: Concise ticket title (1 line). If not provided, draft one from context and confirm.
- **Issue Type**: One of `Epic`, `Story`, `Bug`, `Task`, `Sub-task`. Infer from context if not explicitly specified (e.g., "bug" language -> Bug, feature request -> Story, maintenance work -> Task).
- **Change Impact**: `High`, `Medium`, or `Low`. Ask the user if not obvious from context.

### Optional Fields

- **Assignee**: A team member name. Use the lookup map below to resolve to a JIRA account ID. If not provided, ask the user to pick from the list. Default to `Ankan` if the user says "me" or "myself".
- **Sprint**: A sprint name (e.g., "Feb 25 - Mar 10"). Use the sprint resolution logic below to find the sprint ID. If not provided, ask the user.
- **Labels**: Zero or more from: `Feature-Request`, `Bugfix`, `Tech-Debt`, `Infra`, `Security`, `Performance`, `UX`, `Documentation`. Infer sensible defaults from context.
- **Parent Issue Key**: Required only when issue type is `Sub-task` (e.g., `HP-1234`).

### Team Member Lookup Map

Use this map to resolve assignee names to JIRA account IDs. Match by first name (case-insensitive).

| Name | Account ID |
|---|---|
| Ankan | `5f0f0f4f502ce1001d198bfc` |
| Vivek | `63da000fbf837c6893d75ed7` |
| Tushar | `712020:4453952b-a3bb-4362-807b-b8cb5806f146` |
| Gyanvardhan | `712020:73912695-9179-4d26-b55e-0a7cf3f7cd4c` |
| Saajan | `712020:44cac033-2c5f-4004-9fd8-27a3b1de4a33` |
| Garvit | `712020:acb1b301-326d-4161-803f-0479dbc0c862` |

### Sprint Resolution

To resolve a sprint name to a sprint ID, query the JIRA agile API:

```bash
AUTH=$(echo -n "$JIRA_USER:$JIRA_TOKEN" | base64)
curl --silent --request GET \
  --url 'https://hyperverge.atlassian.net/rest/agile/1.0/board/15/sprint?state=active,future&maxResults=20' \
  --header "Authorization: Basic $AUTH" \
  --header 'Accept: application/json'
```

Match the user-provided sprint name against the `name` field (partial match is fine, e.g., "Feb 25" matches "VKYC: Feb 25 - Mar 10"). Use the `id` field as the sprint ID.

### Fixed Fields (never ask about these)

- **Project Key**: Always `HP`
- **Component**: Always `Video KYC`

## Description Templates (Atlassian Document Format)

Build the description as an ADF JSON document. The structure depends on the issue type.

### For Stories / Tasks / Epics

Sections (each as a level-2 heading followed by content):

1. **Background / Context** - Why this work is needed, business motivation, relevant history.
2. **Problem Statement** - What problem or gap this addresses. Be specific.
3. **Requirements** - Bulleted list describing what needs to be built or changed. Each bullet should be a clear, descriptive requirement covering functional and non-functional aspects. Do NOT use checkboxes.
4. **High-level Approach** *(optional)* - Brief directional guidance on solution approach, only if it adds value. No implementation details, no code, no specific file names.
5. **Scope** - What is in scope and what is explicitly out of scope for this ticket.
6. **Acceptance Criteria** - Bullet list of verifiable conditions that must be true for the ticket to be considered done.

### For Bugs

Sections (each as a level-2 heading followed by content):

1. **Background / Context** - Where and when the bug was observed, affected users/flows.
2. **Steps to Reproduce** - Numbered step-by-step instructions to reproduce the issue. Use an ordered list.
3. **Expected Behavior** - What should happen.
4. **Actual Behavior** - What actually happens. Include error messages if available.
5. **Impact** - Severity, affected users, workaround availability.
6. **Scope** - What is in scope for this fix and what is explicitly out of scope.
7. **Acceptance Criteria** - Bullet list of conditions for the fix to be considered complete.

### ADF Structure Reference

Use these ADF node types:

- `heading` (level 2) for section titles
- `paragraph` for prose content
- `orderedList` > `listItem` > `paragraph` for Steps to Reproduce
- `bulletList` > `listItem` > `paragraph` for Requirements, Acceptance Criteria, and other bullet lists

Example ADF heading node:
```json
{
  "type": "heading",
  "attrs": { "level": 2 },
  "content": [{ "type": "text", "text": "Background / Context" }]
}
```

Example ADF paragraph node:
```json
{
  "type": "paragraph",
  "content": [{ "type": "text", "text": "Your paragraph text here." }]
}
```

Example ADF bullet list node:
```json
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "Criterion one" }]
        }
      ]
    }
  ]
}
```

Example ADF ordered list node:
```json
{
  "type": "orderedList",
  "attrs": { "order": 1 },
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "Step one" }]
        }
      ]
    }
  ]
}
```

## Building the API Payload

Construct the full JSON payload with this structure:

```json
{
  "fields": {
    "project": { "key": "HP" },
    "summary": "<SUMMARY>",
    "issuetype": { "name": "<ISSUE_TYPE>" },
    "components": [{ "name": "Video KYC" }],
    "description": {
      "type": "doc",
      "version": 1,
      "content": [ ...ADF_NODES... ]
    },
    "labels": ["<LABEL1>", "<LABEL2>"],
    "customfield_10168": [{ "value": "<CHANGE_IMPACT>" }],
    "assignee": { "accountId": "<ACCOUNT_ID_FROM_LOOKUP_MAP>" },
    "customfield_10020": <SPRINT_ID>
  }
}
```

If the issue type is `Sub-task`, add `"parent": { "key": "<PARENT_KEY>" }` to the `fields` object.

If labels array is empty, omit the `labels` field entirely.

## Submitting the Ticket

Write the payload to a temp file and use curl to submit:

```bash
# Write payload to temp file
cat > /tmp/jira-payload.json << 'PAYLOAD_EOF'
<JSON_PAYLOAD_HERE>
PAYLOAD_EOF

# Submit to JIRA
AUTH=$(echo -n "$JIRA_USER:$JIRA_TOKEN" | base64)
RESPONSE=$(curl --silent --request POST \
  --url 'https://hyperverge.atlassian.net/rest/api/3/issue' \
  --header "Authorization: Basic $AUTH" \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data @/tmp/jira-payload.json)

echo "$RESPONSE"

# Clean up
rm -f /tmp/jira-payload.json
```

## Post-Creation

After a successful API response:

1. Parse the response JSON to extract the `key` field (e.g., `HP-1234`).
2. Construct the browse URL: `https://hyperverge.atlassian.net/browse/<KEY>`
3. Display to the user:
   - Ticket key and URL
   - Confirmation that the ticket was created successfully

If the API returns an error, display the full error response and help the user troubleshoot.

## Interaction Flow

**Always follow this flow:**

1. Run the pre-flight check.
2. Gather required information (from arguments, conversation context, or by asking).
3. Build the full ticket preview and display it to the user in a readable format:
   - **Summary**: ...
   - **Issue Type**: ...
   - **Assignee**: ...
   - **Sprint**: ...
   - **Change Impact**: ...
   - **Labels**: ...
   - **Description**: (render each section heading and content in markdown for readability)
4. **Ask for explicit confirmation** before submitting. The user must approve the ticket content.
5. On confirmation, build the ADF payload, write to temp file, and submit via API.
6. Display the result (ticket key + URL) or error details.

Never submit a ticket without user confirmation.
