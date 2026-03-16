#!/bin/bash
# SessionStart hook: auto-loads .gig/STATE.md into Claude's context

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ]; then
  exit 0
fi

STATE_FILE="$CWD/.gig/STATE.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read and JSON-encode the state content using jq
CONTENT=$(cat "$STATE_FILE")
HEADER="[GIG STATE auto-loaded]"

jq -n --arg header "$HEADER" --arg content "$CONTENT" \
  '{additionalContext: ($header + "\n\n" + $content)}'

exit 0
