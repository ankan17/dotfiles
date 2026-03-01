#!/bin/bash
# Creates a GitLab MR from current branch
# Usage: ./create-mr.sh "<title>" "<description>"
# Requires: GITLAB_TOKEN environment variable

set -e

TITLE="$1"
DESCRIPTION="$2"

if [ -z "$GITLAB_TOKEN" ]; then
  echo "Error: GITLAB_TOKEN environment variable not set"
  exit 1
fi

if [ -z "$TITLE" ]; then
  echo "Error: MR title required"
  echo "Usage: $0 \"<title>\" \"<description>\""
  exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "Error: Not on a branch (detached HEAD?)"
  exit 1
fi

# Get remote URL
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -z "$REMOTE_URL" ]; then
  echo "Error: No 'origin' remote found"
  exit 1
fi

# Parse GitLab host and project path
if [[ "$REMOTE_URL" =~ ^git@([^:]+):(.+)\.git$ ]]; then
  GITLAB_HOST="${BASH_REMATCH[1]}"
  PROJECT_PATH="${BASH_REMATCH[2]}"
elif [[ "$REMOTE_URL" =~ ^git@([^:]+):(.+)$ ]]; then
  GITLAB_HOST="${BASH_REMATCH[1]}"
  PROJECT_PATH="${BASH_REMATCH[2]}"
elif [[ "$REMOTE_URL" =~ ^https?://([^/]+)/(.+)\.git$ ]]; then
  GITLAB_HOST="${BASH_REMATCH[1]}"
  PROJECT_PATH="${BASH_REMATCH[2]}"
elif [[ "$REMOTE_URL" =~ ^https?://([^/]+)/(.+)$ ]]; then
  GITLAB_HOST="${BASH_REMATCH[1]}"
  PROJECT_PATH="${BASH_REMATCH[2]}"
else
  echo "Error: Could not parse remote URL: $REMOTE_URL"
  exit 1
fi

# URL encode the project path
ENCODED_PROJECT=$(echo "$PROJECT_PATH" | sed 's/\//%2F/g')

# Determine target branch (dev > main > master)
TARGET_BRANCH=""
for branch in dev main master; do
  if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
    TARGET_BRANCH="$branch"
    break
  fi
done

if [ -z "$TARGET_BRANCH" ]; then
  echo "Error: No target branch found (tried: dev, main, master)"
  exit 1
fi

echo "Creating MR..."
echo "  Source: $CURRENT_BRANCH"
echo "  Target: $TARGET_BRANCH"
echo "  Project: $PROJECT_PATH"
echo "  Host: $GITLAB_HOST"

# Create MR via API
RESPONSE=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data @- \
  "https://$GITLAB_HOST/api/v4/projects/$ENCODED_PROJECT/merge_requests" << EOF
{
  "source_branch": "$CURRENT_BRANCH",
  "target_branch": "$TARGET_BRANCH",
  "title": "$TITLE",
  "description": $(echo "$DESCRIPTION" | jq -Rs .),
  "remove_source_branch": true
}
EOF
)

# Check for errors
if echo "$RESPONSE" | jq -e '.message' > /dev/null 2>&1; then
  ERROR=$(echo "$RESPONSE" | jq -r '.message')
  
  # Check if MR already exists
  if [[ "$ERROR" == *"already exists"* ]] || [[ "$ERROR" == *"Another open merge request"* ]]; then
    echo "MR already exists for this branch"
    # Try to get existing MR
    EXISTING=$(curl -s \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      "https://$GITLAB_HOST/api/v4/projects/$ENCODED_PROJECT/merge_requests?source_branch=$CURRENT_BRANCH&state=opened")
    
    if [ -n "$EXISTING" ] && [ "$EXISTING" != "[]" ]; then
      echo "Existing MR: $(echo "$EXISTING" | jq -r '.[0].web_url')"
    fi
    exit 0
  fi
  
  echo "Error creating MR: $ERROR"
  exit 1
fi

# Success - extract MR details
MR_URL=$(echo "$RESPONSE" | jq -r '.web_url')
MR_IID=$(echo "$RESPONSE" | jq -r '.iid')

echo ""
echo "MR created successfully!"
echo "  IID: !$MR_IID"
echo "  URL: $MR_URL"
