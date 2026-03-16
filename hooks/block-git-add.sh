#!/bin/bash
# PreToolUse hook: blocks dangerous git add patterns
# Matches on Bash tool, inspects tool_input.command

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Match: git add -A, git add --all, git add . (standalone dot, not .gitignore etc.)
# Catches chained commands: git add -A && git commit, etc.
if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)git\s+add\s+(-A|--all|\.(\s|$|[;&|]))'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: 'git add -A/./--all' is not allowed. Use 'git add <filename>' instead."
  }
}
EOF
  exit 0
fi

# Allow everything else (no output needed)
exit 0
