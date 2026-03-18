#!/bin/bash
# UserPromptSubmit hook: reminds to update README at governance time
# Fires on gig:govern — checks if non-doc files changed without a README update

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ]; then
  exit 0
fi

# Must be in a git repo with a feature branch
if ! git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)

# Only check on feature branches (not main)
case "$BRANCH" in
  main|master) exit 0 ;;
esac

# Check if main branch exists (needed for diff)
if ! git -C "$CWD" rev-parse main >/dev/null 2>&1; then
  exit 0
fi

# Get changed files on this branch vs main
CHANGED=$(git -C "$CWD" diff main..HEAD --name-only 2>/dev/null)

if [ -z "$CHANGED" ]; then
  exit 0
fi

# Check if README.md was updated
if echo "$CHANGED" | grep -q "^README.md$"; then
  exit 0
fi

# Check if any non-doc files changed (skip .gig/, docs/, *.md-only changes)
NON_DOC=$(echo "$CHANGED" | grep -vE '(^\.gig/|^docs/|\.md$)')

if [ -z "$NON_DOC" ]; then
  exit 0
fi

echo "{\"additionalContext\": \"[README CHECK] Non-doc files changed this iteration but README.md was not updated. Consider updating if user-facing features changed.\"}"
