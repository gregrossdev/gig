#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

# --- Test helpers ---

assert() {
    desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "  PASS: $desc"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  FAIL: $desc"
    fi
}

assert_not() {
    desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  FAIL: $desc"
    else
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "  PASS: $desc"
    fi
}

# --- Setup temp HOME ---

TEMP_HOME="$(mktemp -d)"
export HOME="$TEMP_HOME"
mkdir -p "$TEMP_HOME/.claude"
echo '{}' > "$TEMP_HOME/.claude/settings.json"

cleanup() {
    rm -rf "$TEMP_HOME"
}
trap cleanup EXIT

SKILLS="init gather implement govern status milestone research handoff"
TEMPLATES="STATE.md PLAN.md DECISIONS.md ISSUES.md ARCHITECTURE.md ROADMAP.md GIT-STRATEGY.md ARTICLE.md"

echo ""
echo "=== gig e2e tests ==="
echo "Temp HOME: $TEMP_HOME"
echo ""

# --- Test 1: --help ---

echo "[1] --help flag"
assert "help exits 0" sh "$SCRIPT_DIR/install.sh" --help

# --- Test 2: Copy install ---

echo "[2] Copy install"
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1

for skill in $SKILLS; do
    assert "skill $skill exists" test -f "$TEMP_HOME/.claude/skills/gig/$skill/SKILL.md"
done

for tmpl in $TEMPLATES; do
    assert "template $tmpl exists" test -f "$TEMP_HOME/.claude/templates/gig/$tmpl"
done

assert "skills dir is not a symlink" test ! -L "$TEMP_HOME/.claude/skills/gig"
assert "hook govern-context-check.sh exists" test -f "$TEMP_HOME/.claude/hooks/gig/govern-context-check.sh"
assert "hook block-git-add.sh exists" test -f "$TEMP_HOME/.claude/hooks/gig/block-git-add.sh"
assert "hook load-gig-state.sh exists" test -f "$TEMP_HOME/.claude/hooks/gig/load-gig-state.sh"
assert "hook check-readme.sh exists" test -f "$TEMP_HOME/.claude/hooks/gig/check-readme.sh"
assert "hook govern-context-check.sh is executable" test -x "$TEMP_HOME/.claude/hooks/gig/govern-context-check.sh"
assert "hook block-git-add.sh is executable" test -x "$TEMP_HOME/.claude/hooks/gig/block-git-add.sh"
assert "hook load-gig-state.sh is executable" test -x "$TEMP_HOME/.claude/hooks/gig/load-gig-state.sh"
assert "hook check-readme.sh is executable" test -x "$TEMP_HOME/.claude/hooks/gig/check-readme.sh"
assert "govern-context-check.sh syntax valid" bash -n "$TEMP_HOME/.claude/hooks/gig/govern-context-check.sh"
assert "block-git-add.sh syntax valid" bash -n "$TEMP_HOME/.claude/hooks/gig/block-git-add.sh"
assert "load-gig-state.sh syntax valid" bash -n "$TEMP_HOME/.claude/hooks/gig/load-gig-state.sh"
assert "check-readme.sh syntax valid" bash -n "$TEMP_HOME/.claude/hooks/gig/check-readme.sh"

# --- Test 3: Symlink install ---

echo "[3] Symlink install"
echo "n" | sh "$SCRIPT_DIR/install.sh" --symlink > /dev/null 2>&1

assert "skills is a symlink" test -L "$TEMP_HOME/.claude/skills/gig"
assert "templates is a symlink" test -L "$TEMP_HOME/.claude/templates/gig"
assert "skills symlink target is repo" test "$(readlink "$TEMP_HOME/.claude/skills/gig")" = "$SCRIPT_DIR/skills"
assert "templates symlink target is repo" test "$(readlink "$TEMP_HOME/.claude/templates/gig")" = "$SCRIPT_DIR/templates"
assert "hooks is a symlink" test -L "$TEMP_HOME/.claude/hooks/gig"
assert "hooks symlink target is repo" test "$(readlink "$TEMP_HOME/.claude/hooks/gig")" = "$SCRIPT_DIR/hooks"

# --- Test 4: Default install detects symlinks ---

echo "[4] Symlink detection"
sh "$SCRIPT_DIR/install.sh" < /dev/null > "$TEMP_HOME/detect_output.txt" 2>&1 || true
assert "warns about symlinks" grep -q "installed via symlinks" "$TEMP_HOME/detect_output.txt"

# --- Test 5: Uninstall ---

echo "[5] Uninstall"
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1

assert_not "skills dir removed" test -e "$TEMP_HOME/.claude/skills/gig"
assert_not "templates dir removed" test -e "$TEMP_HOME/.claude/templates/gig"
assert_not "hooks dir removed" test -e "$TEMP_HOME/.claude/hooks/gig"

# --- Test 6: Hook settings.json registration ---

echo "[6] Hook settings.json registration"
echo '{}' > "$TEMP_HOME/.claude/settings.json"
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1

# All three event types registered
assert "settings.json has UserPromptSubmit" jq -e '.hooks.UserPromptSubmit' "$TEMP_HOME/.claude/settings.json"
assert "settings.json has PreToolUse" jq -e '.hooks.PreToolUse' "$TEMP_HOME/.claude/settings.json"
assert "settings.json has SessionStart" jq -e '.hooks.SessionStart' "$TEMP_HOME/.claude/settings.json"

# Correct matchers
assert "UserPromptSubmit has gig:govern matcher" jq -e '.hooks.UserPromptSubmit[0].matcher == "gig:govern"' "$TEMP_HOME/.claude/settings.json"
assert "PreToolUse has Bash matcher" jq -e '.hooks.PreToolUse[0].matcher == "Bash"' "$TEMP_HOME/.claude/settings.json"

# Correct commands
assert "govern-context-check registered" jq -e '[.hooks.UserPromptSubmit[] | .hooks[]? | .command] | any(test("govern-context-check.sh$"))' "$TEMP_HOME/.claude/settings.json"
assert "check-readme registered" jq -e '[.hooks.UserPromptSubmit[] | .hooks[]? | .command] | any(test("check-readme.sh$"))' "$TEMP_HOME/.claude/settings.json"
assert "block-git-add registered" jq -e '[.hooks.PreToolUse[0].hooks[0].command] | any(test("block-git-add.sh$"))' "$TEMP_HOME/.claude/settings.json"
assert "load-gig-state registered" jq -e '[.hooks.SessionStart[0].hooks[0].command] | any(test("load-gig-state.sh$"))' "$TEMP_HOME/.claude/settings.json"

# Test idempotency — second install should not duplicate
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1
TOTAL_HOOKS=$(jq '[.hooks[] | length] | add' "$TEMP_HOME/.claude/settings.json")
assert "no duplicate hook entries on reinstall" test "$TOTAL_HOOKS" -eq 4

# Test uninstall removes all gig hooks from settings.json
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1
assert "settings.json hooks cleaned after uninstall" jq -e '.hooks == {} or .hooks == null' "$TEMP_HOME/.claude/settings.json"

# Test install preserves existing non-gig hooks
echo '{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":[{"type":"command","command":"/usr/bin/other"}]}]}}' > "$TEMP_HOME/.claude/settings.json"
mkdir -p "$TEMP_HOME/.claude"
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1
assert "preserves existing hooks" jq -e '.hooks.PreToolUse | length == 2' "$TEMP_HOME/.claude/settings.json"
assert "existing hook still present" jq -e '.hooks.PreToolUse[] | select(.matcher == "Write")' "$TEMP_HOME/.claude/settings.json"

# Uninstall should only remove gig hooks
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1
assert "uninstall preserves non-gig hooks" jq -e '.hooks.PreToolUse[] | select(.matcher == "Write")' "$TEMP_HOME/.claude/settings.json"
assert_not "uninstall removes gig hooks" jq -e '[.hooks.PreToolUse // [] | .[] | .hooks[]? | .command] | any(test("block-git-add"))' "$TEMP_HOME/.claude/settings.json"

# --- Test 7: --no-hooks flag ---

echo "[7] --no-hooks flag"
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1
echo '{}' > "$TEMP_HOME/.claude/settings.json"
echo "n" | sh "$SCRIPT_DIR/install.sh" --no-hooks > /dev/null 2>&1

assert "skills installed with --no-hooks" test -d "$TEMP_HOME/.claude/skills/gig"
assert "templates installed with --no-hooks" test -d "$TEMP_HOME/.claude/templates/gig"
assert_not "hooks dir skipped with --no-hooks" test -e "$TEMP_HOME/.claude/hooks/gig"
assert "settings.json has no hooks" jq -e '.hooks == null or .hooks == {} or (.hooks | length == 0)' "$TEMP_HOME/.claude/settings.json"

# Also test --symlink --no-hooks
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1
echo '{}' > "$TEMP_HOME/.claude/settings.json"
echo "n" | sh "$SCRIPT_DIR/install.sh" --symlink --no-hooks > /dev/null 2>&1

assert "skills symlinked with --no-hooks" test -L "$TEMP_HOME/.claude/skills/gig"
assert_not "hooks symlink skipped with --no-hooks" test -e "$TEMP_HOME/.claude/hooks/gig"

# Cleanup for next test
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1

# --- Test 8: Plugin manifest ---

echo "[8] Plugin manifest"
assert "plugin.json exists" test -f "$SCRIPT_DIR/.claude-plugin/plugin.json"
assert "plugin.json is valid JSON" python3 -m json.tool "$SCRIPT_DIR/.claude-plugin/plugin.json"
assert "plugin name is gig" grep -q '"name": "gig"' "$SCRIPT_DIR/.claude-plugin/plugin.json"
assert "plugin.json has hooks field" jq -e '.hooks' "$SCRIPT_DIR/.claude-plugin/plugin.json"
assert "plugin.json has homepage" jq -e '.homepage' "$SCRIPT_DIR/.claude-plugin/plugin.json"

# --- Test 9: Plugin hooks.json ---

echo "[9] Plugin hooks.json"
assert "hooks.json exists" test -f "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json is valid JSON" python3 -m json.tool "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json has UserPromptSubmit" jq -e '.UserPromptSubmit' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json has PreToolUse" jq -e '.PreToolUse' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json has SessionStart" jq -e '.SessionStart' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json uses CLAUDE_PLUGIN_ROOT" grep -q 'CLAUDE_PLUGIN_ROOT' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json declares govern-context-check" jq -e '[.. | .command? // empty] | any(test("govern-context-check"))' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json declares block-git-add" jq -e '[.. | .command? // empty] | any(test("block-git-add"))' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json declares load-gig-state" jq -e '[.. | .command? // empty] | any(test("load-gig-state"))' "$SCRIPT_DIR/hooks/hooks.json"
assert "hooks.json declares check-readme" jq -e '[.. | .command? // empty] | any(test("check-readme"))' "$SCRIPT_DIR/hooks/hooks.json"

# --- Test 10: migrate.sh ---

echo "[10] migrate.sh"

# Setup: create old-style .gig/ in a temp directory
MIGRATE_DIR="$(mktemp -d)"
mkdir "$MIGRATE_DIR/.gig"

cat > "$MIGRATE_DIR/.gig/STATE.md" << 'MIGEOF'
| **Phase** | 1 — Test |
| Version | Phase | Batch Title | Type | Status | Timestamp |
MIGEOF

cat > "$MIGRATE_DIR/.gig/ISSUES.md" << 'MIGEOF'
> Tracked during governance. Resolved issues are archived with their phase.
> Deferred issues persist here and carry forward to future phases.
  DEFERRED  — Severity allows deferral to a future phase
**Phase:** {phase number where discovered}
MIGEOF

cat > "$MIGRATE_DIR/.gig/ROADMAP.md" << 'MIGEOF'
## Phases

## Upcoming Phases
<!-- Pre-planned phases for the current milestone. -->
MIGEOF

cat > "$MIGRATE_DIR/.gig/ARCHITECTURE.md" << 'MIGEOF'
- **Phase-based versioning** — MINOR = phase number
milestone/phase hierarchy
MIGEOF

# Test: migrate old-style files
(cd "$MIGRATE_DIR" && sh "$SCRIPT_DIR/migrate.sh") > /dev/null 2>&1
assert "STATE.md field renamed" grep -q 'Iteration' "$MIGRATE_DIR/.gig/STATE.md"
assert "STATE.md column renamed" grep -q '| Iteration |' "$MIGRATE_DIR/.gig/STATE.md"
assert "ISSUES.md updated" grep -q 'iteration' "$MIGRATE_DIR/.gig/ISSUES.md"
assert "ROADMAP.md sections renamed" grep -q '## Iterations' "$MIGRATE_DIR/.gig/ROADMAP.md"
assert "ROADMAP.md upcoming renamed" grep -q '## Upcoming Iterations' "$MIGRATE_DIR/.gig/ROADMAP.md"
assert "ARCHITECTURE.md updated" grep -q 'Iteration-based versioning' "$MIGRATE_DIR/.gig/ARCHITECTURE.md"

# Test: idempotency — second run should report no changes
assert "idempotent — no changes on re-run" sh -c "cd '$MIGRATE_DIR' && sh '$SCRIPT_DIR/migrate.sh' 2>&1 | grep -q 'No changes needed'"

# Test: missing .gig/ — should exit 1
NO_GIG_DIR="$(mktemp -d)"
assert_not "exits 1 without .gig/" sh -c "cd '$NO_GIG_DIR' && sh '$SCRIPT_DIR/migrate.sh' > /dev/null 2>&1"
rm -rf "$NO_GIG_DIR"

# Test: partial files — only STATE.md present
PARTIAL_DIR="$(mktemp -d)"
mkdir "$PARTIAL_DIR/.gig"
cat > "$PARTIAL_DIR/.gig/STATE.md" << 'MIGEOF'
| **Phase** | 1 — Test |
MIGEOF
(cd "$PARTIAL_DIR" && sh "$SCRIPT_DIR/migrate.sh") > /dev/null 2>&1
assert "partial — STATE.md still migrated" grep -q 'Iteration' "$PARTIAL_DIR/.gig/STATE.md"
rm -rf "$PARTIAL_DIR"

rm -rf "$MIGRATE_DIR"

# --- Summary ---

echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "=== Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed ==="
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
