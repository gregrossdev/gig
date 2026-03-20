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
TEMPLATES="STATE.md PLAN.md DECISIONS.md ISSUES.md GOVERNANCE.md ARCHITECTURE.md ROADMAP.md GIT-STRATEGY.md ARTICLE.md"

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

# --- Test 11: GOVERNANCE.md template and skill references ---

echo "[11] GOVERNANCE.md template and govern skill"
assert "GOVERNANCE.md template exists in repo" test -f "$SCRIPT_DIR/templates/GOVERNANCE.md"
assert "init skill references GOVERNANCE.md" grep -q "GOVERNANCE.md" "$SCRIPT_DIR/skills/init/SKILL.md"
assert "govern skill writes GOVERNANCE.md" grep -q '\.gig/GOVERNANCE\.md' "$SCRIPT_DIR/skills/govern/SKILL.md"
assert "govern skill archives GOVERNANCE.md" grep -q 'GOVERNANCE\.md.*frozen snapshot' "$SCRIPT_DIR/skills/govern/SKILL.md"
assert "govern skill clears GOVERNANCE.md" grep -q 'Reset.*GOVERNANCE\.md.*template state' "$SCRIPT_DIR/skills/govern/SKILL.md"

# Verify install copies GOVERNANCE.md
echo '{}' > "$TEMP_HOME/.claude/settings.json"
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1
assert "GOVERNANCE.md installed to templates" test -f "$TEMP_HOME/.claude/templates/gig/GOVERNANCE.md"

# --- Test 12: Hook behavioral tests ---

echo "[12] Hook behavioral tests"

# Ensure hooks are installed for behavioral tests
echo '{}' > "$TEMP_HOME/.claude/settings.json"
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1
HOOK_DIR="$TEMP_HOME/.claude/hooks/gig"

# -- block-git-add.sh --

# Deny cases
assert "block-git-add denies 'git add -A'" \
  sh -c "echo '{\"tool_input\":{\"command\":\"git add -A\"}}' | bash '$HOOK_DIR/block-git-add.sh' | grep -q '\"permissionDecision\"'"

assert "block-git-add denies 'git add --all'" \
  sh -c "echo '{\"tool_input\":{\"command\":\"git add --all\"}}' | bash '$HOOK_DIR/block-git-add.sh' | grep -q '\"permissionDecision\"'"

assert "block-git-add denies 'git add .'" \
  sh -c "echo '{\"tool_input\":{\"command\":\"git add .\"}}' | bash '$HOOK_DIR/block-git-add.sh' | grep -q '\"permissionDecision\"'"

assert "block-git-add denies chained 'git add -A && git commit'" \
  sh -c "echo '{\"tool_input\":{\"command\":\"git add -A && git commit -m test\"}}' | bash '$HOOK_DIR/block-git-add.sh' | grep -q '\"permissionDecision\"'"

# Allow cases (should produce no output)
assert "block-git-add allows 'git add specific-file.txt'" \
  sh -c "OUTPUT=\$(echo '{\"tool_input\":{\"command\":\"git add specific-file.txt\"}}' | bash '$HOOK_DIR/block-git-add.sh'); [ -z \"\$OUTPUT\" ]"

assert "block-git-add allows 'git add .gitignore'" \
  sh -c "OUTPUT=\$(echo '{\"tool_input\":{\"command\":\"git add .gitignore\"}}' | bash '$HOOK_DIR/block-git-add.sh'); [ -z \"\$OUTPUT\" ]"

# -- load-gig-state.sh --

# Present case: temp dir with .gig/STATE.md
LOAD_DIR="$(mktemp -d)"
mkdir -p "$LOAD_DIR/.gig"
echo "| **Version** | 0.1.0 |" > "$LOAD_DIR/.gig/STATE.md"

assert "load-gig-state outputs context when STATE.md present" \
  sh -c "echo '{\"cwd\":\"$LOAD_DIR\"}' | bash '$HOOK_DIR/load-gig-state.sh' | grep -q 'GIG STATE auto-loaded'"

assert "load-gig-state includes state content" \
  sh -c "echo '{\"cwd\":\"$LOAD_DIR\"}' | bash '$HOOK_DIR/load-gig-state.sh' | grep -q '0.1.0'"

# Absent case: nonexistent path
assert "load-gig-state silent when no STATE.md" \
  sh -c "OUTPUT=\$(echo '{\"cwd\":\"/nonexistent/path\"}' | bash '$HOOK_DIR/load-gig-state.sh'); [ -z \"\$OUTPUT\" ]"

rm -rf "$LOAD_DIR"

# -- govern-context-check.sh --

# Small transcript file
TRANSCRIPT_DIR="$(mktemp -d)"
echo '{"type":"message"}' > "$TRANSCRIPT_DIR/transcript.jsonl"

assert "govern-context-check outputs context for transcript" \
  sh -c "echo '{\"transcript_path\":\"$TRANSCRIPT_DIR/transcript.jsonl\"}' | bash '$HOOK_DIR/govern-context-check.sh' | grep -q 'additionalContext'"

assert "govern-context-check shows low usage for small file" \
  sh -c "echo '{\"transcript_path\":\"$TRANSCRIPT_DIR/transcript.jsonl\"}' | bash '$HOOK_DIR/govern-context-check.sh' | grep -q 'CONTEXT CHECK'"

# Missing transcript_path
assert "govern-context-check silent when no transcript_path" \
  sh -c "OUTPUT=\$(echo '{}' | bash '$HOOK_DIR/govern-context-check.sh'); [ -z \"\$OUTPUT\" ]"

rm -rf "$TRANSCRIPT_DIR"

# -- check-readme.sh --

# Not a git repo
assert "check-readme silent when not in git repo" \
  sh -c "OUTPUT=\$(echo '{\"cwd\":\"/tmp\"}' | bash '$HOOK_DIR/check-readme.sh'); [ -z \"\$OUTPUT\" ]"

# On main branch
README_DIR="$(mktemp -d)"
git -C "$README_DIR" init -b main > /dev/null 2>&1
git -C "$README_DIR" -c user.name=test -c user.email=test@test commit --allow-empty -m "init" > /dev/null 2>&1

assert "check-readme silent on main branch" \
  sh -c "OUTPUT=\$(echo '{\"cwd\":\"$README_DIR\"}' | bash '$HOOK_DIR/check-readme.sh'); [ -z \"\$OUTPUT\" ]"

rm -rf "$README_DIR"

# --- Test 13: Skill frontmatter validation ---

echo "[13] Skill frontmatter validation"

for skill in $SKILLS; do
    SKILL_FILE="$SCRIPT_DIR/skills/$skill/SKILL.md"
    assert "$skill has name field" grep -q '^name:' "$SKILL_FILE"
    assert "$skill has description field" grep -q '^description:' "$SKILL_FILE"
    assert "$skill has user-invocable field" grep -q '^user-invocable:' "$SKILL_FILE"
    assert "$skill name matches gig:$skill" grep -q "^name: gig:$skill$" "$SKILL_FILE"
done

# --- Test 14: upgrade.sh ---

echo "[14] upgrade.sh"

# --help flag
assert "upgrade.sh --help exits 0" sh "$SCRIPT_DIR/upgrade.sh" --help

# Fails without .gig/ directory
NOGIG_DIR="$(mktemp -d)"
assert_not "upgrade.sh fails without .gig/" sh "$SCRIPT_DIR/upgrade.sh" "$NOGIG_DIR"

# Fails with nonexistent path
assert_not "upgrade.sh fails with nonexistent path" sh "$SCRIPT_DIR/upgrade.sh" "/tmp/nonexistent-$$/nope"

rm -rf "$NOGIG_DIR"

# Adds missing template files
UPGRADE_DIR="$(mktemp -d)"
mkdir -p "$UPGRADE_DIR/.gig"
echo "# State" > "$UPGRADE_DIR/.gig/STATE.md"

# Reinstall so templates are available
echo '{}' > "$TEMP_HOME/.claude/settings.json"
echo "n" | sh "$SCRIPT_DIR/install.sh" > /dev/null 2>&1

sh "$SCRIPT_DIR/upgrade.sh" "$UPGRADE_DIR" > /dev/null 2>&1
assert "upgrade adds PLAN.md" test -f "$UPGRADE_DIR/.gig/PLAN.md"
assert "upgrade adds DECISIONS.md" test -f "$UPGRADE_DIR/.gig/DECISIONS.md"
assert "upgrade adds ISSUES.md" test -f "$UPGRADE_DIR/.gig/ISSUES.md"
assert "upgrade adds GOVERNANCE.md" test -f "$UPGRADE_DIR/.gig/GOVERNANCE.md"
assert "upgrade adds ARCHITECTURE.md" test -f "$UPGRADE_DIR/.gig/ARCHITECTURE.md"
assert "upgrade adds ROADMAP.md" test -f "$UPGRADE_DIR/.gig/ROADMAP.md"
assert "upgrade adds GIT-STRATEGY.md" test -f "$UPGRADE_DIR/.gig/GIT-STRATEGY.md"
assert "upgrade adds ARTICLE.md" test -f "$UPGRADE_DIR/.gig/ARTICLE.md"
assert "upgrade creates iterations/ dir" test -d "$UPGRADE_DIR/.gig/iterations"
assert "upgrade preserves existing STATE.md" grep -q "# State" "$UPGRADE_DIR/.gig/STATE.md"

# Sets .gig-version
assert "upgrade sets .gig-version" test -f "$UPGRADE_DIR/.gig/.gig-version"
assert "upgrade .gig-version has content" test -s "$UPGRADE_DIR/.gig/.gig-version"

# Idempotency — second run reports no changes
assert "upgrade idempotent" sh -c "sh '$SCRIPT_DIR/upgrade.sh' '$UPGRADE_DIR' 2>&1 | grep -q 'No changes needed'"

# Dry-run — does not modify files
DRYRUN_DIR="$(mktemp -d)"
mkdir -p "$DRYRUN_DIR/.gig"
echo "# State" > "$DRYRUN_DIR/.gig/STATE.md"

sh "$SCRIPT_DIR/upgrade.sh" "$DRYRUN_DIR" --dry-run > "$TEMP_HOME/dryrun_output.txt" 2>&1
assert "dry-run says dry run" grep -q "dry run" "$TEMP_HOME/dryrun_output.txt"
assert "dry-run mentions missing files" grep -q "Would add missing file" "$TEMP_HOME/dryrun_output.txt"
assert_not "dry-run does not create PLAN.md" test -f "$DRYRUN_DIR/.gig/PLAN.md"
assert_not "dry-run does not create .gig-version" test -f "$DRYRUN_DIR/.gig/.gig-version"

rm -rf "$UPGRADE_DIR" "$DRYRUN_DIR"

# --- Test 15: Init upgrade integration ---

echo "[15] Init upgrade integration"
INIT_SKILL="$SCRIPT_DIR/skills/init/SKILL.md"
assert "init references upgrade.sh" grep -q 'upgrade\.sh' "$INIT_SKILL"
assert "init references .gig-version in Step 0" grep -q '\.gig-version' "$INIT_SKILL"
assert "init has dual-path upgrade (plugin)" grep -q 'CLAUDE_PLUGIN_ROOT.*upgrade\.sh' "$INIT_SKILL"
assert "init has dual-path upgrade (script)" grep -q '~/.claude/upgrade\.sh' "$INIT_SKILL"
assert_not "init no longer has top-level Phase migration marker" grep -q '^First, check for stale "phase"' "$INIT_SKILL"

# --- Test 16: Implement plugin awareness ---

echo "[16] Implement plugin awareness"
IMPL_SKILL="$SCRIPT_DIR/skills/implement/SKILL.md"
assert "implement references plugin.json" grep -q 'plugin\.json' "$IMPL_SKILL"
assert "implement has plugin version in Step 0" grep -q 'Plugin:.*{name}.*v{version}' "$IMPL_SKILL"
assert "implement has plugin version in checkpoint" grep -q 'Plugin:.*{name}.*v{version}.*manifest' "$IMPL_SKILL"
assert "implement skips silently when no plugin.json" grep -q 'does not exist, skip silently' "$IMPL_SKILL"

# --- Test 17: Plugin Version field in STATE.md template and skills ---

echo "[17] Plugin Version field"
assert "STATE.md template has Plugin Version field" grep -q 'Plugin Version' "$SCRIPT_DIR/templates/STATE.md"
assert "govern skill references Plugin Version" grep -q 'Plugin Version' "$SCRIPT_DIR/skills/govern/SKILL.md"
assert "implement skill references Plugin Version" grep -q 'Plugin Version' "$SCRIPT_DIR/skills/implement/SKILL.md"
assert "init skill references Plugin Version" grep -q 'Plugin Version' "$SCRIPT_DIR/skills/init/SKILL.md"

# --- Test 18: Govern plugin version instruction ---

echo "[18] Govern plugin version instruction"
GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"
assert "govern has 'Update plugin manifest' instruction" grep -q 'Update plugin manifest' "$GOVERN_SKILL"
assert "govern references plugin.json in archive section" grep -q 'plugin\.json' "$GOVERN_SKILL"
assert "govern has plugin version commit format" grep -q 'chore(v0.{N}.{last-P}): update plugin.json version' "$GOVERN_SKILL"

# --- Summary ---

echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "=== Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed ==="
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
