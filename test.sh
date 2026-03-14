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

# --- Test 3: CLAUDE.md append ---

echo "[3] CLAUDE.md append"
# Uninstall first, then reinstall with y
rm -rf "$TEMP_HOME/.claude/skills/gig" "$TEMP_HOME/.claude/templates/gig"
echo "y" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1

assert "CLAUDE.md has start marker" grep -q "# --- gig workflow rules ---" "$TEMP_HOME/.claude/CLAUDE.md"
assert "CLAUDE.md has end marker" grep -q "# --- end gig workflow rules ---" "$TEMP_HOME/.claude/CLAUDE.md"
assert "CLAUDE.md has gig content" grep -q "gig:init" "$TEMP_HOME/.claude/CLAUDE.md"

# --- Test 4: Symlink install ---

echo "[4] Symlink install"
echo "n" | sh "$SCRIPT_DIR/install.sh" --symlink > /dev/null 2>&1

assert "skills is a symlink" test -L "$TEMP_HOME/.claude/skills/gig"
assert "templates is a symlink" test -L "$TEMP_HOME/.claude/templates/gig"
assert "skills symlink target is repo" test "$(readlink "$TEMP_HOME/.claude/skills/gig")" = "$SCRIPT_DIR/skills"
assert "templates symlink target is repo" test "$(readlink "$TEMP_HOME/.claude/templates/gig")" = "$SCRIPT_DIR/templates"

# --- Test 5: Default install detects symlinks ---

echo "[5] Symlink detection"
OUTPUT="$(echo "n" | sh "$SCRIPT_DIR/install.sh" 2>&1 || true)"
assert "warns about symlinks" echo "$OUTPUT" | grep -q "installed via symlinks"

# --- Test 6: Uninstall ---

echo "[6] Uninstall"
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1

assert_not "skills dir removed" test -e "$TEMP_HOME/.claude/skills/gig"
assert_not "templates dir removed" test -e "$TEMP_HOME/.claude/templates/gig"
assert_not "CLAUDE.md markers removed" grep -q "# --- gig workflow rules ---" "$TEMP_HOME/.claude/CLAUDE.md"

# --- Test 7: Plugin manifest ---

echo "[7] Plugin manifest"
assert "plugin.json exists" test -f "$SCRIPT_DIR/.claude-plugin/plugin.json"
assert "plugin.json is valid JSON" python3 -m json.tool "$SCRIPT_DIR/.claude-plugin/plugin.json"
assert "plugin name is gig" grep -q '"name": "gig"' "$SCRIPT_DIR/.claude-plugin/plugin.json"

# --- Summary ---

echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "=== Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed ==="
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
