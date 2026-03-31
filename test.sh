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

SKILLS="init spec learn design gather implement govern status milestone research triage"
TEMPLATES="STATE.md PLAN.md DECISIONS.md ISSUES.md GOVERNANCE.md ARCHITECTURE.md ROADMAP.md GIT-STRATEGY.md BACKLOG.md DEBT.md SPEC.md MVP.md"
PROJECT_TEMPLATES="ARTICLE.md README.md RESEARCH.md"

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

for tmpl in $PROJECT_TEMPLATES; do
    assert "project template $tmpl exists" test -f "$TEMP_HOME/.claude/templates/project/$tmpl"
done

for skill in $SKILLS; do
    assert "command $skill.md exists" test -f "$TEMP_HOME/.claude/commands/gig/$skill.md"
done

assert "skills dir is not a symlink" test ! -L "$TEMP_HOME/.claude/skills/gig"
assert "commands dir is not a symlink" test ! -L "$TEMP_HOME/.claude/commands/gig"
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
assert "commands is a symlink" test -L "$TEMP_HOME/.claude/commands/gig"
assert "commands symlink target is repo" test "$(readlink "$TEMP_HOME/.claude/commands/gig")" = "$SCRIPT_DIR/commands"

# --- Test 4: Default install detects symlinks ---

echo "[4] Symlink detection"
sh "$SCRIPT_DIR/install.sh" < /dev/null > "$TEMP_HOME/detect_output.txt" 2>&1 || true
assert "warns about symlinks" grep -q "installed via symlinks" "$TEMP_HOME/detect_output.txt"

# --- Test 5: Uninstall ---

echo "[5] Uninstall"
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null 2>&1

assert_not "skills dir removed" test -e "$TEMP_HOME/.claude/skills/gig"
assert_not "templates dir removed" test -e "$TEMP_HOME/.claude/templates/gig"
assert_not "project templates dir removed" test -e "$TEMP_HOME/.claude/templates/project"
assert_not "hooks dir removed" test -e "$TEMP_HOME/.claude/hooks/gig"
assert_not "commands dir removed" test -e "$TEMP_HOME/.claude/commands/gig"

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
assert "GOVERNANCE.md template exists in repo" test -f "$SCRIPT_DIR/templates/gig/GOVERNANCE.md"
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
assert "upgrade adds BACKLOG.md" test -f "$UPGRADE_DIR/.gig/BACKLOG.md"
assert "upgrade adds SPEC.md" test -f "$UPGRADE_DIR/.gig/SPEC.md"
assert_not "upgrade does not add ARTICLE.md to .gig/" test -f "$UPGRADE_DIR/.gig/ARTICLE.md"
assert "upgrade creates iterations/ dir" test -d "$UPGRADE_DIR/.gig/iterations"
assert "upgrade preserves existing STATE.md" grep -q "# State" "$UPGRADE_DIR/.gig/STATE.md"

# Sets .gig-version
assert "upgrade sets .gig-version" test -f "$UPGRADE_DIR/.gig/.gig-version"
assert "upgrade .gig-version has content" test -s "$UPGRADE_DIR/.gig/.gig-version"

# Idempotency — second run reports no changes
assert "upgrade idempotent" sh -c "sh '$SCRIPT_DIR/upgrade.sh' '$UPGRADE_DIR' 2>&1 | grep -q 'No changes needed'"

# FUTURE.md → BACKLOG.md rename
RENAME_DIR="$(mktemp -d)"
mkdir -p "$RENAME_DIR/.gig"
echo "# State" > "$RENAME_DIR/.gig/STATE.md"
printf '# Future Ideas\n\n- My backlog idea\n' > "$RENAME_DIR/.gig/FUTURE.md"

sh "$SCRIPT_DIR/upgrade.sh" "$RENAME_DIR" > /dev/null 2>&1
assert "upgrade renames FUTURE.md to BACKLOG.md" test -f "$RENAME_DIR/.gig/BACKLOG.md"
assert_not "upgrade removes old FUTURE.md" test -f "$RENAME_DIR/.gig/FUTURE.md"
assert "upgrade preserves backlog content" grep -q "My backlog idea" "$RENAME_DIR/.gig/BACKLOG.md"
assert "upgrade updates heading to Backlog" grep -q "^# Backlog$" "$RENAME_DIR/.gig/BACKLOG.md"

# Idempotent — rename doesn't re-trigger
assert "upgrade rename idempotent" sh -c "sh '$SCRIPT_DIR/upgrade.sh' '$RENAME_DIR' 2>&1 | grep -q 'No changes needed'"

rm -rf "$RENAME_DIR"

# Dry-run — does not modify files
DRYRUN_DIR="$(mktemp -d)"
mkdir -p "$DRYRUN_DIR/.gig"
echo "# State" > "$DRYRUN_DIR/.gig/STATE.md"

sh "$SCRIPT_DIR/upgrade.sh" "$DRYRUN_DIR" --dry-run > "$TEMP_HOME/dryrun_output.txt" 2>&1
assert "dry-run says dry run" grep -q "dry run" "$TEMP_HOME/dryrun_output.txt"
assert "dry-run mentions missing files" grep -q "Would add missing file" "$TEMP_HOME/dryrun_output.txt"
assert_not "dry-run does not create PLAN.md" test -f "$DRYRUN_DIR/.gig/PLAN.md"
assert_not "dry-run does not create .gig-version" test -f "$DRYRUN_DIR/.gig/.gig-version"

# Dry-run with FUTURE.md rename
DRYRUN_RENAME_DIR="$(mktemp -d)"
mkdir -p "$DRYRUN_RENAME_DIR/.gig"
echo "# State" > "$DRYRUN_RENAME_DIR/.gig/STATE.md"
echo "# Future Ideas" > "$DRYRUN_RENAME_DIR/.gig/FUTURE.md"
sh "$SCRIPT_DIR/upgrade.sh" "$DRYRUN_RENAME_DIR" --dry-run > "$TEMP_HOME/dryrun_rename_output.txt" 2>&1
assert "dry-run mentions FUTURE.md rename" grep -q "Would rename FUTURE.md" "$TEMP_HOME/dryrun_rename_output.txt"
assert_not "dry-run does not rename FUTURE.md" test -f "$DRYRUN_RENAME_DIR/.gig/BACKLOG.md"
rm -rf "$DRYRUN_RENAME_DIR"

rm -rf "$UPGRADE_DIR" "$DRYRUN_DIR"

# --- Test 15: Init upgrade integration ---

echo "[15] Init upgrade integration"
INIT_SKILL="$SCRIPT_DIR/skills/init/SKILL.md"
assert "init references upgrade.sh" grep -q 'upgrade\.sh' "$INIT_SKILL"
assert "init references .gig-version in Step 0" grep -q '\.gig-version' "$INIT_SKILL"
assert "init has dual-path upgrade (plugin)" grep -q 'CLAUDE_PLUGIN_ROOT.*upgrade\.sh' "$INIT_SKILL"
assert "init has dual-path upgrade (script)" grep -q '~/.claude/upgrade\.sh' "$INIT_SKILL"
assert_not "init no longer has top-level Phase migration marker" grep -q '^First, check for stale "phase"' "$INIT_SKILL"
assert "init has reinit keyword check" grep -q 'reinitialize.*or.*reinit' "$INIT_SKILL"
assert "init stops after upgrade" grep -q 'Upgraded .gig/.*STOP' "$INIT_SKILL"
assert "init has already-up-to-date path" grep -q 'Already up to date' "$INIT_SKILL"
assert_not "init no longer has AskUserQuestion reinit prompt" grep -q 'AskUserQuestion' "$INIT_SKILL"

# --- Test 16: Implement plugin awareness ---

echo "[16] Implement plugin awareness"
IMPL_SKILL="$SCRIPT_DIR/skills/implement/SKILL.md"
assert "implement references plugin.json" grep -q 'plugin\.json' "$IMPL_SKILL"
assert "implement has plugin version in Step 0" grep -q 'Plugin:.*{name}.*v{version}' "$IMPL_SKILL"
assert "implement has plugin version in header" grep -q 'Plugin:.*{name}.*v{version}' "$IMPL_SKILL"
assert "implement skips silently when no plugin.json" grep -q 'does not exist, skip silently' "$IMPL_SKILL"

# --- Test 17: Plugin Version field in STATE.md template and skills ---

echo "[17] Plugin Version field"
assert "STATE.md template has Plugin Version field" grep -q 'Plugin Version' "$SCRIPT_DIR/templates/gig/STATE.md"
assert "govern skill references Plugin Version" grep -q 'Plugin Version' "$SCRIPT_DIR/skills/govern/SKILL.md"
assert "implement skill references Plugin Version" grep -q 'Plugin Version' "$SCRIPT_DIR/skills/implement/SKILL.md"
assert "init skill references Plugin Version" grep -q 'Plugin Version' "$SCRIPT_DIR/skills/init/SKILL.md"

# --- Test 18: Iteration queue cap ---

echo "[18] Iteration queue cap"
assert "govern has 3-cap for queued iterations" grep -q 'next 3 chunks' "$SCRIPT_DIR/skills/govern/SKILL.md"
assert "govern has queue cap hard rule" grep -q 'Maximum 3 entries' "$SCRIPT_DIR/templates/gig/ROADMAP.md"
assert "ROADMAP template has 3-cap comment" grep -q 'Maximum 3 entries' "$SCRIPT_DIR/templates/gig/ROADMAP.md"

# --- Test 19: Implement auto-continue ---

echo "[19] Implement auto-continue"
assert "implement has auto-continue step" grep -q 'Auto-Continue' "$SCRIPT_DIR/skills/implement/SKILL.md"
assert "implement has brief status line" grep -q 'Continuing\.\.\.' "$SCRIPT_DIR/skills/implement/SKILL.md"
assert_not "implement no longer has 'next to proceed'" grep -q 'next.*to proceed' "$SCRIPT_DIR/skills/implement/SKILL.md"
assert "implement stops on failure" grep -q 'failed verification' "$SCRIPT_DIR/skills/implement/SKILL.md"
assert "implement has Do NOT stop instruction" grep -q 'Do NOT stop.*Do NOT prompt' "$SCRIPT_DIR/skills/implement/SKILL.md"

# --- Test 20: Gather plan mode ---

echo "[20] Gather plan mode"
GATHER_SKILL="$SCRIPT_DIR/skills/gather/SKILL.md"
assert "gather references EnterPlanMode" grep -q 'EnterPlanMode' "$GATHER_SKILL"
assert "gather references ExitPlanMode" grep -q 'ExitPlanMode' "$GATHER_SKILL"
assert_not "gather no longer has old Gate 2 STOP" grep -q 'STOP\. Do not implement\.' "$GATHER_SKILL"
assert "gather writes after plan approval" grep -q 'After Plan Approval.*Write State' "$GATHER_SKILL"

# --- Test 21: Gather decision batching UX ---

echo "[21] Gather decision batching UX"
assert "gather writes decisions after approval" grep -q 'After Gate 1 Approval.*Write Decisions' "$GATHER_SKILL"
assert "gather writes directly as ACTIVE" grep -q 'directly as.*ACTIVE' "$GATHER_SKILL"
assert_not "gather no longer has pre-approval write step" grep -q '^### Step 5 — Write Decisions' "$GATHER_SKILL"
assert "gather defers DECISIONS.md write" grep -q 'Do NOT write to DECISIONS.md yet' "$GATHER_SKILL"

# --- Test 21b: Gather spec awareness ---

echo "[21b] Gather spec awareness"
assert "gather reads SPEC.md" grep -q 'Read.*SPEC\.md' "$GATHER_SKILL"
assert "gather has REQ column in decision table" grep -q '| REQ |' "$GATHER_SKILL"
assert "gather warns if no spec" grep -q 'No spec found' "$GATHER_SKILL"
assert "gather traces decisions to requirements" grep -q 'trace to a requirement' "$GATHER_SKILL"

# --- Test 22: BACKLOG.md backlog ---

echo "[22] BACKLOG.md backlog"
assert "BACKLOG.md template exists" test -f "$SCRIPT_DIR/templates/gig/BACKLOG.md"
assert "init skill references BACKLOG.md" grep -q 'BACKLOG\.md' "$SCRIPT_DIR/skills/init/SKILL.md"
assert "govern skill references BACKLOG.md" grep -q 'BACKLOG\.md' "$SCRIPT_DIR/skills/govern/SKILL.md"
assert "status skill references Backlog" grep -q 'Backlog' "$SCRIPT_DIR/skills/status/SKILL.md"

# --- Test 23: Project templates ---

echo "[23] Project templates"
assert "project template ARTICLE.md exists" test -f "$SCRIPT_DIR/templates/project/ARTICLE.md"
assert "project template README.md exists" test -f "$SCRIPT_DIR/templates/project/README.md"
assert "project template RESEARCH.md exists" test -f "$SCRIPT_DIR/templates/project/RESEARCH.md"
assert "init skill has project templates step" grep -q 'Project Templates' "$SCRIPT_DIR/skills/init/SKILL.md"
assert "init skill references templates/gig/" grep -q 'templates/gig/' "$SCRIPT_DIR/skills/init/SKILL.md"
assert "init skill references templates/project/" grep -q 'templates/project/' "$SCRIPT_DIR/skills/init/SKILL.md"
assert_not "init .gig/ file list no longer includes ARTICLE.md" grep -q 'GIT-STRATEGY.md, ARTICLE.md' "$SCRIPT_DIR/skills/init/SKILL.md"
assert "init .gig/ file list includes SPEC.md" grep -q 'SPEC\.md' "$SCRIPT_DIR/skills/init/SKILL.md"

# --- Test 24: Govern plugin version instruction ---

echo "[24] Govern plugin version instruction"
GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"
assert "govern has 'Update plugin manifest' instruction" grep -q 'Update plugin manifest' "$GOVERN_SKILL"
assert "govern references plugin.json in archive section" grep -q 'plugin\.json' "$GOVERN_SKILL"
assert "govern has plugin version commit format" grep -q 'chore(v0.{N}.{last-P}): update plugin.json version' "$GOVERN_SKILL"

# --- Test 25: Govern .gig-version exclusion ---

echo "[25] Govern .gig-version exclusion"
assert "govern does not reference .gig-version" test "$(grep -c '\.gig-version' "$GOVERN_SKILL")" = "0"

# --- Test 26: Init template preview UX ---

echo "[26] Init template preview UX"
INIT_SKILL="$SCRIPT_DIR/skills/init/SKILL.md"
assert "init has template preview table" grep -q '| # | Template | Type |' "$INIT_SKILL"
assert "init has numbered selection UX" grep -q 'number' "$INIT_SKILL"
assert "init has skip-existing message" grep -q 'already exists in project root' "$INIT_SKILL"
assert "init has copied message" grep -q 'Copied {file} to project root' "$INIT_SKILL"


# --- Test 28: Triage skill ---

echo "[28] Triage skill"
TRIAGE_SKILL="$SCRIPT_DIR/skills/triage/SKILL.md"
assert "triage references ROADMAP.md" grep -q 'ROADMAP\.md' "$TRIAGE_SKILL"
assert "triage references BACKLOG.md" grep -q 'BACKLOG\.md' "$TRIAGE_SKILL"
assert "triage has codebase research step" grep -q 'Research the Codebase' "$TRIAGE_SKILL"
assert "triage has quality research focus" grep -q 'Quality & Coverage' "$TRIAGE_SKILL"
assert "triage has consistency research focus" grep -q 'Consistency & Docs' "$TRIAGE_SKILL"
assert "triage has features research focus" grep -q 'Features & Architecture' "$TRIAGE_SKILL"
assert "triage has Evidence field in cards" grep -q 'Evidence' "$TRIAGE_SKILL"
assert "triage has Value in output" grep -q 'Value' "$TRIAGE_SKILL"
assert "triage has Risk in output" grep -q 'Risk' "$TRIAGE_SKILL"
assert "triage compares against existing queue" grep -q 'Current Queue Assessment' "$TRIAGE_SKILL"
assert "triage surfaces backlog separately" grep -q 'In the Backlog' "$TRIAGE_SKILL"
assert "triage has recommendation step" grep -q 'Recommend' "$TRIAGE_SKILL"
assert "triage has parallel subagent research" grep -q 'parallel' "$TRIAGE_SKILL"

# --- Test 29: Command stub validation ---

echo "[29] Command stub validation"

for skill in $SKILLS; do
    CMD_FILE="$SCRIPT_DIR/commands/$skill.md"
    assert "command $skill has name field" grep -q "^name: gig:$skill$" "$CMD_FILE"
    assert "command $skill has description field" grep -q "^description:" "$CMD_FILE"
    assert "command $skill references skill" grep -q "@~/.claude/skills/gig/$skill/SKILL.md" "$CMD_FILE"
done

# [30] Govern quick verify and approval table enforcement
echo "[30] Govern quick verify and approval table enforcement"

GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"
GATHER_SKILL="$SCRIPT_DIR/skills/gather/SKILL.md"

assert_not "govern Step 2 does not auto-skip" grep -q "skip automatically" "$GOVERN_SKILL"
assert "govern Step 2 appends to Verify Later on skip" grep -q 'Verify Later' "$GOVERN_SKILL"
assert "STATE.md template has Verify Later section" grep -q '## Verify Later' "$SCRIPT_DIR/templates/gig/STATE.md"
assert "status skill surfaces Verify Later count" grep -q 'Verify Later' "$SCRIPT_DIR/skills/status/SKILL.md"
assert "govern Step 2 always presents checklist" grep -q "Always present this checklist" "$GOVERN_SKILL"
assert "govern approval gate has table enforcement" grep -q "Do not abbreviate, inline, or omit" "$GOVERN_SKILL"
assert "gather Gate 1 has table enforcement" grep -q "Do not abbreviate, inline, or collapse into prose" "$GATHER_SKILL"
assert "gather Gate 2 has table enforcement" grep -q "Do not abbreviate or collapse into prose" "$GATHER_SKILL"

# [31] Govern suggestion research
echo "[31] Govern suggestion research"

assert "govern Step 10 has In the Backlog section" grep -q 'In the Backlog' "$GOVERN_SKILL"
assert "govern Step 10 auto-queues from spec" grep -q 'Auto-Queued from Spec' "$GOVERN_SKILL"
assert "govern Step 10 checks NOT COVERED requirements" grep -q 'NOT COVERED' "$GOVERN_SKILL"
assert "govern Step 10 groups by parent story" grep -q 'Group uncovered requirements by parent story' "$GOVERN_SKILL"
assert "govern Step 10 surfaces issues alongside spec queue" grep -q 'insert a fix iteration before the spec queue' "$GOVERN_SKILL"
assert "govern Path B directs to new spec" grep -q 'Spec Complete' "$GOVERN_SKILL"
assert "govern Path C handles no spec" grep -q 'No Spec' "$GOVERN_SKILL"
assert "govern Path C suggests baseline" grep -q 'gig:spec baseline' "$GOVERN_SKILL"

# [31b] Govern spec coverage
echo "[31b] Govern spec coverage"

assert "govern reads SPEC.md" grep -q 'SPEC\.md' "$GOVERN_SKILL"
assert "govern report has Spec Coverage section" grep -q 'Spec Coverage' "$GOVERN_SKILL"
assert "govern has REQ coverage table" grep -q '| REQ | Description | Addressed By | Status |' "$GOVERN_SKILL"
assert "govern handles no spec gracefully" grep -q 'No spec.*coverage not tracked' "$GOVERN_SKILL"
assert "govern updates SPEC.md after archive" grep -q 'Update.*SPEC\.md' "$GOVERN_SKILL"
assert "govern marks requirements COVERED" grep -q 'Status.*to.*COVERED' "$GOVERN_SKILL"
assert "govern records iteration in SPEC.md" grep -q 'Iteration.*v0' "$GOVERN_SKILL"

# [32] Spec skill
echo "[32] Spec skill"

SPEC_SKILL="$SCRIPT_DIR/skills/spec/SKILL.md"
assert "spec skill has elicitation step" grep -q 'Elicitation' "$SPEC_SKILL"
assert "spec skill has lock gate" grep -q 'Lock Gate' "$SPEC_SKILL"
assert "spec skill references SPEC.md" grep -q 'SPEC\.md' "$SPEC_SKILL"
assert "spec skill has SPECING status" grep -q 'SPECING' "$SPEC_SKILL"
assert "spec skill has SPECCED status" grep -q 'SPECCED' "$SPEC_SKILL"
assert "spec skill has user story format" grep -q 'As a \[who\]' "$SPEC_SKILL"
assert "spec skill has requirement IDs" grep -q 'REQ-001' "$SPEC_SKILL"
assert "SPEC.md template exists" test -f "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "SPEC.md template has Stories section" grep -q '## Stories' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "SPEC.md template has Requirements section" grep -q '## Requirements' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "spec skill has existing project analysis" grep -q 'Explore subagent' "$SPEC_SKILL"
assert "spec skill proposes directions" grep -q 'Suggested Directions' "$SPEC_SKILL"
assert "spec skill has project assessment" grep -q 'Your Project Now' "$SPEC_SKILL"
assert "spec skill has baseline from iterations" grep -q 'Baseline from Iterations' "$SPEC_SKILL"
assert "spec skill reads archived iterations" grep -q 'gig/iterations/' "$SPEC_SKILL"
assert "spec skill has DELIVERED status" grep -q 'DELIVERED' "$SPEC_SKILL"
assert "spec skill has NOT COVERED for new work" grep -q 'NOT COVERED' "$SPEC_SKILL"
assert "SPEC.md template has Status column in requirements" grep -q '| Status | Iteration |' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "SPEC.md template has Status column in stories" grep -q '| Status |' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "SPEC.md template documents requirement statuses" grep -q 'Requirement statuses' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "milestone archives SPEC.md" grep -q 'SPEC.*archive' "$SCRIPT_DIR/skills/milestone/SKILL.md"

# [33] Design skill
echo "[33] Design skill"

DESIGN_SKILL="$SCRIPT_DIR/skills/design/SKILL.md"
assert "design skill has name field" grep -q '^name: gig:design$' "$DESIGN_SKILL"
assert "design skill has description field" grep -q '^description:' "$DESIGN_SKILL"
assert "design skill has user-invocable field" grep -q '^user-invocable: true' "$DESIGN_SKILL"
assert "design skill has guard check" grep -q 'Guard Check' "$DESIGN_SKILL"
assert "design skill has approval gate" grep -q 'Approval Gate' "$DESIGN_SKILL"
assert "design skill has DESIGNING status" grep -q 'DESIGNING' "$DESIGN_SKILL"
assert "design skill has DESIGNED status" grep -q 'DESIGNED' "$DESIGN_SKILL"
assert "design skill references SPEC.md" grep -q 'SPEC\.md' "$DESIGN_SKILL"
assert "design skill references DESIGN.md" grep -q 'DESIGN\.md' "$DESIGN_SKILL"
assert "design skill references ARCHITECTURE.md" grep -q 'ARCHITECTURE\.md' "$DESIGN_SKILL"
assert "design skill references Figma" grep -q 'Figma\|figma' "$DESIGN_SKILL"
assert "design skill has design summary table" grep -q 'Screen/Flow' "$DESIGN_SKILL"
assert "design command references skill" grep -q '@~/.claude/skills/gig/design/SKILL.md' "$SCRIPT_DIR/commands/design.md"
assert "design command has Figma tools" grep -q 'mcp__figma__generate_figma_design' "$SCRIPT_DIR/commands/design.md"

# [34] Design-gather integration
echo "[34] Design-gather integration"

GATHER_SKILL="$SCRIPT_DIR/skills/gather/SKILL.md"
assert "gather reads DESIGN.md" grep -q 'DESIGN\.md' "$GATHER_SKILL"
assert "gather has Mermaid diagram step" grep -q 'System Diagrams' "$GATHER_SKILL"
assert "gather references .gig/design/ directory" grep -q '\.gig/design/' "$GATHER_SKILL"
assert "gather has .mmd file references" grep -q '\.mmd' "$GATHER_SKILL"
assert "gather design is optional" grep -q 'Design is optional' "$GATHER_SKILL"
assert "gather references Figma in decisions" grep -q 'Figma' "$GATHER_SKILL"

# [35] Design in docs
echo "[35] Design in docs"

assert "RULES.md has design in workflow header" grep -q 'Design.*Gather' "$SCRIPT_DIR/docs/RULES.md"
assert "RULES.md lists gig:design skill" grep -q 'gig:design' "$SCRIPT_DIR/docs/RULES.md"
assert "RULES.md has design natural language command" grep -q '| .design.' "$SCRIPT_DIR/docs/RULES.md"
assert "GETTING-STARTED.md mentions gig:design" grep -q 'gig:design' "$SCRIPT_DIR/docs/GETTING-STARTED.md"
assert "GETTING-STARTED.md has DESIGN.md in file table" grep -q 'DESIGN\.md' "$SCRIPT_DIR/docs/GETTING-STARTED.md"

# [36] Status handles design states
echo "[36] Status handles design states"

STATUS_SKILL="$SCRIPT_DIR/skills/status/SKILL.md"
assert "status has DESIGNING suggestion" grep -q 'DESIGNING' "$STATUS_SKILL"
assert "status has DESIGNED suggestion" grep -q 'DESIGNED' "$STATUS_SKILL"
assert "status SPECCED mentions design option" grep -q 'gig:design' "$STATUS_SKILL"

# [37] SPEC.md template versioning
echo "[37] SPEC.md template versioning"

assert "SPEC.md template has version header" grep -q 'Spec v1.0' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "SPEC.md template has Amendments section" grep -q '## Amendments' "$SCRIPT_DIR/templates/gig/SPEC.md"
assert "SPEC.md template has AMD format comment" grep -q 'AMD-{N}' "$SCRIPT_DIR/templates/gig/SPEC.md"

# [38] ARCHITECTURE.md audit log
echo "[38] ARCHITECTURE.md audit log"

assert "ARCHITECTURE.md template has Audit Log section" grep -q '## Audit Log' "$SCRIPT_DIR/templates/gig/ARCHITECTURE.md"
assert "ARCHITECTURE.md template has gather comment" grep -q 'Gather appends' "$SCRIPT_DIR/templates/gig/ARCHITECTURE.md"

# [39] DEBT.md template
echo "[39] DEBT.md template"

assert "DEBT.md template exists" test -f "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has header" grep -q '# Technical Debt' "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has DEBT-{N} format" grep -q 'DEBT-{N}' "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has OPEN status" grep -q 'OPEN' "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has TRACKED status" grep -q 'TRACKED' "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has RESOLVED status" grep -q 'RESOLVED' "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has Severity field" grep -q 'Severity' "$SCRIPT_DIR/templates/gig/DEBT.md"
assert "DEBT.md template has Area field" grep -q 'Area' "$SCRIPT_DIR/templates/gig/DEBT.md"

# [40] Init scaffolds DEBT.md
echo "[40] Init scaffolds DEBT.md"

INIT_SKILL="$SCRIPT_DIR/skills/init/SKILL.md"
assert "init file list includes DEBT.md" grep -q 'DEBT.md' "$INIT_SKILL"

# [41] Gather amendments + architecture
echo "[41] Gather amendments + architecture"

GATHER_SKILL="$SCRIPT_DIR/skills/gather/SKILL.md"
assert "gather reads DEBT.md" grep -q 'DEBT\.md' "$GATHER_SKILL"
assert "gather has audit log step" grep -q 'Audit Log' "$GATHER_SKILL"
assert "gather has architecture assessment" grep -q 'architecture assessment' "$GATHER_SKILL"
assert "gather has spec version reference" grep -q 'Spec.*v{X.Y}' "$GATHER_SKILL"
assert "gather has Type field" grep -q 'Type.*feature.*refactor' "$GATHER_SKILL"
assert "gather surfaces debt for refactors" grep -q 'refactor.*scope' "$GATHER_SKILL"

# [42] Implement amend interrupt
echo "[42] Implement amend interrupt"

IMPLEMENT_SKILL="$SCRIPT_DIR/skills/implement/SKILL.md"
assert "implement has amend interrupt" grep -q 'amend.*REQ' "$IMPLEMENT_SKILL"
assert "implement has Tier 3 reference" grep -q 'Tier 3' "$IMPLEMENT_SKILL"
assert "implement has Patch batch option" grep -q 'Patch batch' "$IMPLEMENT_SKILL"
assert "implement has Re-gather option" grep -q 'Re-gather' "$IMPLEMENT_SKILL"
assert "implement has Story-level re-eval" grep -q 'Story-level' "$IMPLEMENT_SKILL"
assert "implement has impact analysis" grep -q 'impact analysis' "$IMPLEMENT_SKILL"

# [43] Govern architecture health
echo "[43] Govern architecture health"

GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"
assert "govern reads DEBT.md" grep -q 'DEBT\.md' "$GOVERN_SKILL"
assert "govern has Step 5b" grep -q 'Step 5b' "$GOVERN_SKILL"
assert "govern has Architecture Health Check" grep -q 'Architecture Health' "$GOVERN_SKILL"
assert "govern flags amendment candidates" grep -q 'amend REQ' "$GOVERN_SKILL"
assert "govern has Technical Debt report section" grep -q 'Technical Debt' "$GOVERN_SKILL"
assert "govern has debt-driven refactor check" grep -q 'Debt-Driven Refactor' "$GOVERN_SKILL"
assert "govern has type-aware validation" grep -q 'Type.*refactor' "$GOVERN_SKILL"
assert "govern archives resolved debt" grep -q 'RESOLVED.*DEBT' "$GOVERN_SKILL"

# [44] Status amend + debt
echo "[44] Status amend + debt"

STATUS_SKILL="$SCRIPT_DIR/skills/status/SKILL.md"
assert "status routes amend command" grep -q 'amend.*REQ' "$STATUS_SKILL"
assert "status has Tier 2 amendment" grep -q 'Tier 2' "$STATUS_SKILL"
assert "status routes debt command" grep -q '"debt"' "$STATUS_SKILL"
assert "status displays debt count" grep -q 'Debt:' "$STATUS_SKILL"
assert "status checks GATHERING for amend" grep -q 'GATHERING' "$STATUS_SKILL"
assert "status checks IMPLEMENTING for amend" grep -q 'IMPLEMENTING' "$STATUS_SKILL"

# [45] Docs updates
echo "[45] Docs updates"

assert "RULES.md has debt command" grep -q '| .debt.' "$SCRIPT_DIR/docs/RULES.md"
assert "RULES.md has amend REQ" grep -q 'amend.*REQ' "$SCRIPT_DIR/docs/RULES.md"
assert "GETTING-STARTED.md has DEBT.md" grep -q 'DEBT\.md' "$SCRIPT_DIR/docs/GETTING-STARTED.md"
assert "GETTING-STARTED.md has debt command" grep -q 'debt' "$SCRIPT_DIR/docs/GETTING-STARTED.md"
assert "GETTING-STARTED.md has amend command" grep -q 'amend' "$SCRIPT_DIR/docs/GETTING-STARTED.md"

# [46] Context hygiene
echo "[46] Context hygiene"

GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"
GATHER_SKILL="$SCRIPT_DIR/skills/gather/SKILL.md"
SPEC_SKILL="$SCRIPT_DIR/skills/spec/SKILL.md"

# REQ-001: Govern trims batch history
assert "govern trims batch history to 20 rows" grep -q 'last 20 rows' "$GOVERN_SKILL"

# REQ-003: Govern trims audit log
assert "govern trims audit log to 5 entries" grep -q 'last 5 entries' "$GOVERN_SKILL"

# REQ-004: Govern archives design/
assert "govern archives design directory" grep -q 'design.*iterations' "$GOVERN_SKILL"

# REQ-005: Gather updates living diagrams (revised from clear behavior)
assert "gather treats diagrams as living artifacts" grep -q 'living diagrams' "$GATHER_SKILL"
assert "gather evolves diagrams across iterations" grep -q 'evolve across iterations' "$GATHER_SKILL"

# REQ-006: Spec auto-archives completed specs
assert "spec archives completed specs" grep -q 'SPEC-completed' "$SPEC_SKILL"
assert "spec archives to iterations dir" grep -q '.gig/iterations/SPEC' "$SPEC_SKILL"

# REQ-007: Spec warns on partial overwrite
assert "spec warns on uncovered requirements" grep -q 'uncovered requirements' "$SPEC_SKILL"
assert "spec has partial archive option" grep -q 'SPEC-partial' "$SPEC_SKILL"
assert "spec auto-archives without prompt when complete" grep -q 'Auto-archive' "$SPEC_SKILL"

# [47] Diagram templates and init-to-spec flow
echo "[47] Diagram templates and init-to-spec flow"

INIT_SKILL="$SCRIPT_DIR/skills/init/SKILL.md"

# Diagram template directories exist
assert "diagram dir article exists" test -d "$SCRIPT_DIR/templates/diagrams/article"
assert "diagram dir readme exists" test -d "$SCRIPT_DIR/templates/diagrams/readme"
assert "diagram dir research exists" test -d "$SCRIPT_DIR/templates/diagrams/research"
assert "diagram dir webapp exists" test -d "$SCRIPT_DIR/templates/diagrams/webapp"
assert "diagram dir api exists" test -d "$SCRIPT_DIR/templates/diagrams/api"
assert "diagram dir cli exists" test -d "$SCRIPT_DIR/templates/diagrams/cli"
assert "diagram dir library exists" test -d "$SCRIPT_DIR/templates/diagrams/library"

# Correct file counts per type
assert "article has 1 diagram" test "$(find "$SCRIPT_DIR/templates/diagrams/article" -name '*.mmd' | wc -l | tr -d ' ')" = "1"
assert "readme has 1 diagram" test "$(find "$SCRIPT_DIR/templates/diagrams/readme" -name '*.mmd' | wc -l | tr -d ' ')" = "1"
assert "research has 2 diagrams" test "$(find "$SCRIPT_DIR/templates/diagrams/research" -name '*.mmd' | wc -l | tr -d ' ')" = "2"
assert "webapp has 4 diagrams" test "$(find "$SCRIPT_DIR/templates/diagrams/webapp" -name '*.mmd' | wc -l | tr -d ' ')" = "4"
assert "api has 4 diagrams" test "$(find "$SCRIPT_DIR/templates/diagrams/api" -name '*.mmd' | wc -l | tr -d ' ')" = "4"
assert "cli has 3 diagrams" test "$(find "$SCRIPT_DIR/templates/diagrams/cli" -name '*.mmd' | wc -l | tr -d ' ')" = "3"
assert "library has 2 diagrams" test "$(find "$SCRIPT_DIR/templates/diagrams/library" -name '*.mmd' | wc -l | tr -d ' ')" = "2"

# .mmd files have valid Mermaid comment header
assert "webapp architecture starts with %%" head -1 "$SCRIPT_DIR/templates/diagrams/webapp/architecture.mmd" | grep -q '%%'
assert "cli architecture starts with %%" head -1 "$SCRIPT_DIR/templates/diagrams/cli/architecture.mmd" | grep -q '%%'

# Init skill — 7 template types
assert "init has Web App type" grep -q 'Web App' "$INIT_SKILL"
assert "init has API type" grep -q '| API |' "$INIT_SKILL"
assert "init has CLI type" grep -q '| CLI |' "$INIT_SKILL"
assert "init has Library type" grep -q '| Library |' "$INIT_SKILL"

# Init skill — diagram scaffolding
assert "init has diagram scaffolding step" grep -q 'Scaffold Diagrams' "$INIT_SKILL"
assert "init scaffolds to .gig/design/" grep -q '.gig/design/' "$INIT_SKILL"

# Init skill — flows into spec (not gather)
assert "init references spec elicitation" grep -q 'spec elicitation' "$INIT_SKILL"
assert "init no longer suggests run gather as ending" grep -q 'will begin automatically' "$INIT_SKILL"

# Gather — living diagrams
assert "gather has diagram change report" grep -q 'Updated:' "$GATHER_SKILL"

# Govern — no delete
assert "govern preserves design originals" grep -q 'Do NOT delete' "$GOVERN_SKILL"

# install.sh — diagram handling
assert "install.sh handles diagram templates" grep -q 'templates/diagrams' "$SCRIPT_DIR/install.sh"
assert "install.sh uninstalls diagram templates" grep -q 'templates/diagrams' "$SCRIPT_DIR/install.sh"

# [48] Docs sync and gather research tuning
echo "[48] Docs sync and gather research tuning"

ARCH_FILE="$SCRIPT_DIR/.gig/ARCHITECTURE.md"
BACKLOG_FILE="$SCRIPT_DIR/.gig/BACKLOG.md"
GETTING_STARTED="$SCRIPT_DIR/docs/GETTING-STARTED.md"
README_FILE="$SCRIPT_DIR/README.md"

# REQ-001: ARCHITECTURE.md structure
assert "architecture has templates/diagrams/" grep -q 'diagrams/' "$ARCH_FILE"
assert "architecture has SPEC.md in templates" grep -q 'SPEC.md' "$ARCH_FILE"
assert "architecture has DEBT.md in templates" grep -q 'DEBT.md' "$ARCH_FILE"
assert "architecture has spec skill" grep -q 'spec/SKILL.md' "$ARCH_FILE"
assert "architecture has design skill" grep -q 'design/SKILL.md' "$ARCH_FILE"

# REQ-002: ARCHITECTURE.md patterns
assert "architecture has spec-driven pattern" grep -q 'Spec-driven development' "$ARCH_FILE"
assert "architecture has living diagrams pattern" grep -q 'Living diagrams' "$ARCH_FILE"

# REQ-005/006: BACKLOG.md pruned
assert "backlog header exists" grep -q '# Backlog' "$BACKLOG_FILE"
assert "backlog items resolved" grep -q 'All items resolved' "$BACKLOG_FILE"

# REQ-003: GETTING-STARTED.md
assert "getting-started mentions project types" grep -q 'Web App' "$GETTING_STARTED"
assert "getting-started mentions diagram presets" grep -q 'diagram presets' "$GETTING_STARTED"

# REQ-004: README.md
assert "readme has DEBT.md in listing" grep -q 'DEBT.md' "$README_FILE"
assert "readme has gig:design command" grep -q 'gig:design' "$README_FILE"

# REQ-007-010: Gather lightweight path
assert "gather has docs/config detection" grep -q 'Docs/Config Detection' "$GATHER_SKILL"
assert "gather has lightweight keyword" grep -q 'lightweight' "$GATHER_SKILL"
assert "gather Step 3 has Exception carve-out" grep -q 'Exception' "$GATHER_SKILL"

# [49] RULES.md drift guard
echo "[49] RULES.md drift guard"

RULES_FILE="$SCRIPT_DIR/docs/RULES.md"
STATUS_SKILL="$SCRIPT_DIR/skills/status/SKILL.md"

# REQ-005: Workflow order — skills exist for each workflow step
assert "rules has Init in workflow" grep -q 'Init' "$RULES_FILE"
assert "rules has Spec in workflow" grep -q 'Spec' "$RULES_FILE"
assert "rules has Gather in workflow" grep -q 'Gather' "$RULES_FILE"
assert "rules has Implement in workflow" grep -q 'Implement' "$RULES_FILE"
assert "rules has Govern in workflow" grep -q 'Govern' "$RULES_FILE"
assert "init skill dir exists" test -d "$SCRIPT_DIR/skills/init"
assert "spec skill dir exists" test -d "$SCRIPT_DIR/skills/spec"
assert "gather skill dir exists" test -d "$SCRIPT_DIR/skills/gather"
assert "implement skill dir exists" test -d "$SCRIPT_DIR/skills/implement"
assert "govern skill dir exists" test -d "$SCRIPT_DIR/skills/govern"

# REQ-006: Natural language commands — key commands in RULES.md table
assert "rules has spec command" grep -q '| .spec.' "$RULES_FILE"
assert "rules has gather command" grep -q '| .gather.' "$RULES_FILE"
assert "rules has status command" grep -q '| .status.' "$RULES_FILE"
assert "rules has issues command" grep -q '| .issues.' "$RULES_FILE"
assert "rules has decisions command" grep -q '| .decisions.' "$RULES_FILE"
assert "rules has triage command" grep -q '| .triage.' "$RULES_FILE"
assert "rules has debt command" grep -q '| .debt.' "$RULES_FILE"

# REQ-006: Status skill routes matching commands
assert "status routes decisions" grep -q 'decisions' "$STATUS_SKILL"
assert "status routes issues" grep -q 'issues' "$STATUS_SKILL"
assert "status routes history" grep -q 'history' "$STATUS_SKILL"
assert "status routes debt" grep -q 'debt' "$STATUS_SKILL"

# REQ-007: Skill list — every skills/ dir referenced in RULES.md
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    assert "rules references skill: $skill_name" grep -q "$skill_name" "$RULES_FILE"
done

# [50] Govern auto-flow
echo "[50] Govern auto-flow"

GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"

# REQ-001: Steps 3-8 continuous block
assert "govern has continuous block instruction" grep -q 'Continuous Governance Block' "$GOVERN_SKILL"
assert "govern says do not stop between steps" grep -q 'Do not stop' "$GOVERN_SKILL"

# REQ-001/004: Step 6 auto-assessment
assert "govern Step 6 auto-assesses" grep -q 'Auto-assess' "$GOVERN_SKILL"
assert "govern Step 6 does not prompt user" grep -q 'Do NOT prompt' "$GOVERN_SKILL"

# REQ-002: Step 2 unchanged
assert "govern Step 2 still has verified/skip" grep -q 'verified' "$GOVERN_SKILL"

# REQ-003: Final gate unchanged
assert "govern final gate still has STOP" grep -q 'STOP.*Wait for approval' "$GOVERN_SKILL"

# [51] Learn skill foundation
echo "[51] Learn skill foundation"

LEARN_SKILL="$SCRIPT_DIR/skills/learn/SKILL.md"

# REQ-004: Skill exists with correct structure
assert "learn skill exists" test -f "$LEARN_SKILL"
assert "learn has name field" grep -q 'name: gig:learn' "$LEARN_SKILL"
assert "learn has description" grep -q 'description:' "$LEARN_SKILL"
assert "learn has user-invocable" grep -q 'user-invocable: true' "$LEARN_SKILL"
assert "learn has guard check" grep -q 'Guard Check' "$LEARN_SKILL"
assert "learn has lock gate" grep -q 'Lock Gate' "$LEARN_SKILL"

# REQ-005: From-scratch and external course modes
assert "learn has fresh curriculum flow" grep -q 'Fresh Curriculum Flow' "$LEARN_SKILL"
assert "learn has external course flow" grep -q 'External Course Flow' "$LEARN_SKILL"
assert "learn detects URL" grep -q 'http' "$LEARN_SKILL"

# REQ-006: Curriculum maps to SPEC.md
assert "learn writes SPEC.md" grep -q 'SPEC.md' "$LEARN_SKILL"
assert "learn has US-XXX stories" grep -q 'US-001' "$LEARN_SKILL"
assert "learn has REQ-XXX requirements" grep -q 'REQ-001' "$LEARN_SKILL"
assert "learn sets SPECCED status" grep -q 'SPECCED' "$LEARN_SKILL"

# REQ-007: Command stub and install
assert "learn command exists" test -f "$SCRIPT_DIR/commands/learn.md"
assert "learn command has name" grep -q 'name: gig:learn' "$SCRIPT_DIR/commands/learn.md"
assert "install.sh has learn in SKILLS" grep -q 'learn' "$SCRIPT_DIR/install.sh"

# Docs updated
assert "rules.md has gig:learn" grep -q 'gig:learn' "$SCRIPT_DIR/docs/RULES.md"
assert "readme has gig:learn" grep -q 'gig:learn' "$SCRIPT_DIR/README.md"
assert "getting-started has learn" grep -q 'learn' "$SCRIPT_DIR/docs/GETTING-STARTED.md"
assert "architecture has learn skill" grep -q 'learn/SKILL.md' "$SCRIPT_DIR/.gig/ARCHITECTURE.md"

# [52] Lesson article generation
echo "[52] Lesson article generation"

GOVERN_SKILL="$SCRIPT_DIR/skills/govern/SKILL.md"

# REQ-008: Govern generates lesson articles
assert "govern has lesson article step" grep -q 'Generate Lesson Article' "$GOVERN_SKILL"
assert "govern detects learn curriculum" grep -q 'learn curriculum' "$GOVERN_SKILL"
assert "govern writes to lessons/ directory" grep -q 'lessons/' "$GOVERN_SKILL"
assert "govern article has Core Concepts section" grep -q 'Core Concepts' "$GOVERN_SKILL"
assert "govern article has Problem-Solving Patterns" grep -q 'Problem-Solving Patterns' "$GOVERN_SKILL"
assert "govern article has Key Takeaways" grep -q 'Key Takeaways' "$GOVERN_SKILL"
assert "govern article has Example Problem" grep -q 'Example Problem' "$GOVERN_SKILL"

# REQ-009: Articles are standalone
assert "govern article has Date field" grep -q 'Date:' "$GOVERN_SKILL"
assert "govern article has Lesson number" grep -q 'Lesson.*of.*total' "$GOVERN_SKILL"
assert "govern skips if not learn curriculum" grep -q 'Skip this step silently' "$GOVERN_SKILL"

# [53] Init E2E diagram scaffolding
echo "[53] Init E2E diagram scaffolding"

DIAGRAMS_DIR="$SCRIPT_DIR/templates/diagrams"

# REQ-012: Each project type has correct diagram preset files
# Article: outline-flow
assert "article has outline-flow.mmd" test -f "$DIAGRAMS_DIR/article/outline-flow.mmd"
assert "article has exactly 1 diagram" test "$(find "$DIAGRAMS_DIR/article" -name '*.mmd' | wc -l | tr -d ' ')" = "1"

# README: architecture
assert "readme has architecture.mmd" test -f "$DIAGRAMS_DIR/readme/architecture.mmd"
assert "readme has exactly 1 diagram" test "$(find "$DIAGRAMS_DIR/readme" -name '*.mmd' | wc -l | tr -d ' ')" = "1"

# Research: concept-map, flow
assert "research has concept-map.mmd" test -f "$DIAGRAMS_DIR/research/concept-map.mmd"
assert "research has flow.mmd" test -f "$DIAGRAMS_DIR/research/flow.mmd"
assert "research has exactly 2 diagrams" test "$(find "$DIAGRAMS_DIR/research" -name '*.mmd' | wc -l | tr -d ' ')" = "2"

# Web App: architecture, data-flow, er, sequence
assert "webapp has architecture.mmd" test -f "$DIAGRAMS_DIR/webapp/architecture.mmd"
assert "webapp has data-flow.mmd" test -f "$DIAGRAMS_DIR/webapp/data-flow.mmd"
assert "webapp has er.mmd" test -f "$DIAGRAMS_DIR/webapp/er.mmd"
assert "webapp has sequence.mmd" test -f "$DIAGRAMS_DIR/webapp/sequence.mmd"
assert "webapp has exactly 4 diagrams" test "$(find "$DIAGRAMS_DIR/webapp" -name '*.mmd' | wc -l | tr -d ' ')" = "4"

# API: architecture, er, data-flow, sequence
assert "api has architecture.mmd" test -f "$DIAGRAMS_DIR/api/architecture.mmd"
assert "api has er.mmd" test -f "$DIAGRAMS_DIR/api/er.mmd"
assert "api has data-flow.mmd" test -f "$DIAGRAMS_DIR/api/data-flow.mmd"
assert "api has sequence.mmd" test -f "$DIAGRAMS_DIR/api/sequence.mmd"
assert "api has exactly 4 diagrams" test "$(find "$DIAGRAMS_DIR/api" -name '*.mmd' | wc -l | tr -d ' ')" = "4"

# CLI: architecture, data-flow, sequence
assert "cli has architecture.mmd" test -f "$DIAGRAMS_DIR/cli/architecture.mmd"
assert "cli has data-flow.mmd" test -f "$DIAGRAMS_DIR/cli/data-flow.mmd"
assert "cli has sequence.mmd" test -f "$DIAGRAMS_DIR/cli/sequence.mmd"
assert "cli has exactly 3 diagrams" test "$(find "$DIAGRAMS_DIR/cli" -name '*.mmd' | wc -l | tr -d ' ')" = "3"

# Library: architecture, data-flow
assert "library has architecture.mmd" test -f "$DIAGRAMS_DIR/library/architecture.mmd"
assert "library has data-flow.mmd" test -f "$DIAGRAMS_DIR/library/data-flow.mmd"
assert "library has exactly 2 diagrams" test "$(find "$DIAGRAMS_DIR/library" -name '*.mmd' | wc -l | tr -d ' ')" = "2"

# All diagrams have valid Mermaid headers
assert "all mmd files start with %%" find "$DIAGRAMS_DIR" -name '*.mmd' -exec sh -c 'head -1 "$1" | grep -q "%%"' _ {} \;

# Init skill references diagram scaffolding
assert "init has diagram scaffolding step" grep -q 'Scaffold Diagrams' "$SCRIPT_DIR/skills/init/SKILL.md"
assert "init references .gig/design/" grep -q '.gig/design/' "$SCRIPT_DIR/skills/init/SKILL.md"

# --- [54] MVP template ---

echo "[54] MVP template"
MVP_TMPL="$SCRIPT_DIR/templates/gig/MVP.md"
assert "MVP.md template exists" test -f "$MVP_TMPL"
assert "MVP.md has Vision section" grep -q '## Vision' "$MVP_TMPL"
assert "MVP.md has Inspiration section" grep -q '## Inspiration' "$MVP_TMPL"
assert "MVP.md has Core Flows section" grep -q '## Core Flows' "$MVP_TMPL"
assert "MVP.md has Screens section" grep -q '## Screens' "$MVP_TMPL"
assert "MVP.md has Data Model section" grep -q '## Data Model' "$MVP_TMPL"
assert "MVP.md has Success Metrics section" grep -q '## Success Metrics' "$MVP_TMPL"
assert "MVP.md has Open Questions section" grep -q '## Open Questions' "$MVP_TMPL"
assert "MVP.md has Boundaries section" grep -q '## Boundaries' "$MVP_TMPL"
assert "MVP.md has Mermaid flowchart example" grep -q 'flowchart' "$MVP_TMPL"
assert "MVP.md has Mermaid stateDiagram example" grep -q 'stateDiagram' "$MVP_TMPL"

# --- [55] MVP command argument hints ---

echo "[55] MVP command argument hints"
assert "init command has mvp hint" grep -q 'mvp' "$SCRIPT_DIR/commands/init.md"
assert "spec command has mvp hint" grep -q 'mvp' "$SCRIPT_DIR/commands/spec.md"

# --- [56] Init MVP routing ---

echo "[56] Init MVP routing"
INIT_SKILL="$SCRIPT_DIR/skills/init/SKILL.md"
assert "init has MVP flag detection" grep -q 'MVP check' "$INIT_SKILL"
assert "init has MVP routing" grep -q 'MVP flag is set' "$INIT_SKILL"
assert "init scaffold list has MVP.md" grep -q 'MVP.md' "$INIT_SKILL"

# --- [57] Spec MVP interview ---

echo "[57] Spec MVP interview"
SPEC_SKILL="$SCRIPT_DIR/skills/spec/SKILL.md"
assert "spec has MVP Product Discovery section" grep -q 'MVP Product Discovery' "$SPEC_SKILL"
assert "spec has MVP arg detection" grep -q 'mvp' "$SPEC_SKILL"
assert "spec has Mermaid flowchart instruction" grep -q 'flowchart TD' "$SPEC_SKILL"
assert "spec has Mermaid stateDiagram instruction" grep -q 'stateDiagram-v2' "$SPEC_SKILL"
assert "spec has ASCII mockup instruction" grep -q 'ASCII' "$SPEC_SKILL"
assert "spec has 7 interview sections" grep -q 'Section 7' "$SPEC_SKILL"
assert "spec has MVP lock gate" grep -q 'MVP Lock Gate' "$SPEC_SKILL"
assert "spec writes MVP.md on lock" grep -q 'Write.*MVP.md' "$SPEC_SKILL"

# --- [58] Spec MVP context integration ---

echo "[58] Spec MVP context integration"
assert "spec loads MVP.md in context" grep -q 'MVP.md.*MVP product discovery' "$SPEC_SKILL"
assert "spec pre-populates from MVP" grep -q 'pre-populate' "$SPEC_SKILL"
assert "spec surfaces MVP open questions" grep -q 'Open Questions.*MVP' "$SPEC_SKILL"

# --- Summary ---

echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "=== Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed ==="
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
