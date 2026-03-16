#!/bin/bash
# Hook: fires on UserPromptSubmit matching gig:govern
# Reads transcript file size to estimate context usage,
# injects a warning into Claude's context if near threshold.

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Transcript JSONL size in bytes
FILE_SIZE=$(wc -c < "$TRANSCRIPT" | tr -d ' ')

# Calibrated: ~7.3 bytes per token, 1M token window
# 30% of 1M tokens ≈ 300K tokens ≈ ~2.19MB of transcript
THRESHOLD=2190000

PERCENT=$((FILE_SIZE * 100 / 7300000))

if [ "$PERCENT" -ge 25 ]; then
  echo "{\"additionalContext\": \"[CONTEXT CHECK] ~${PERCENT}% context used. Suggest /clear after governance completes.\"}"
else
  echo "{\"additionalContext\": \"[CONTEXT CHECK] ~${PERCENT}% context used. No /clear needed yet.\"}"
fi
