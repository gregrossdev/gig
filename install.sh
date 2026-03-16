#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CLAUDE_DIR="$HOME/.claude"
SKILLS_DEST="$CLAUDE_DIR/skills/gig"
TEMPLATES_DEST="$CLAUDE_DIR/templates/gig"
HOOKS_DEST="$CLAUDE_DIR/hooks/gig"
SETTINGS="$CLAUDE_DIR/settings.json"
RULES_SRC="$SCRIPT_DIR/docs/RULES.md"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

SKILLS="init gather implement govern status milestone research handoff"
HAS_JQ=false

MODE="copy"

# --- Argument parsing ---

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -h, --help        Show this help message"
            echo "  -s, --symlink     Symlink instead of copy (for development)"
            echo "  -u, --uninstall   Remove gig from ~/.claude/"
            echo ""
            echo "Default: copies skills, templates, and hooks to ~/.claude/"
            exit 0
            ;;
        -s|--symlink)
            MODE="symlink"
            shift
            ;;
        -u|--uninstall)
            MODE="uninstall"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run ./install.sh --help for usage."
            exit 1
            ;;
    esac
done

# --- Preflight ---

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Error: ~/.claude/ directory not found."
    echo "Please install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    HAS_JQ=true
fi

# --- Uninstall ---

if [ "$MODE" = "uninstall" ]; then
    echo "Uninstalling gig..."

    if [ -e "$SKILLS_DEST" ]; then
        rm -rf "$SKILLS_DEST"
        echo "  Removed $SKILLS_DEST"
    fi

    if [ -e "$TEMPLATES_DEST" ]; then
        rm -rf "$TEMPLATES_DEST"
        echo "  Removed $TEMPLATES_DEST"
    fi

    if [ -e "$HOOKS_DEST" ]; then
        rm -rf "$HOOKS_DEST"
        echo "  Removed $HOOKS_DEST"
    fi

    # Remove gig hook entries from settings.json
    if [ "$HAS_JQ" = true ] && [ -f "$SETTINGS" ]; then
        if jq -e '.hooks' "$SETTINGS" >/dev/null 2>&1; then
            cp "$SETTINGS" "$SETTINGS.bak"
            jq '
              .hooks |= with_entries(
                .value |= map(
                  select(.hooks | all(.command | test("govern-context-check\\.sh$") | not))
                )
              ) |
              .hooks |= with_entries(select(.value | length > 0))
            ' "$SETTINGS.bak" > "$SETTINGS"
            echo "  Removed gig hooks from settings.json"
        fi
    fi

    if [ -f "$CLAUDE_MD" ]; then
        if grep -q "# --- gig workflow rules ---" "$CLAUDE_MD" 2>/dev/null; then
            cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
            # Remove everything between the gig markers (inclusive)
            sed '/^# --- gig workflow rules ---$/,/^# --- end gig workflow rules ---$/d' "$CLAUDE_MD.bak" > "$CLAUDE_MD"
            echo "  Removed gig rules from CLAUDE.md (backup: CLAUDE.md.bak)"
        fi
    fi

    echo ""
    echo "Uninstall complete."
    exit 0
fi

# --- Update detection ---

if [ -L "$SKILLS_DEST" ] && [ "$MODE" = "copy" ]; then
    echo "gig is installed via symlinks."
    echo "Use --symlink to update, or --uninstall first to switch to copy mode."
    exit 0
fi

if [ -d "$SKILLS_DEST" ] && [ "$MODE" = "copy" ]; then
    echo "gig is already installed. Reinstalling..."
fi

# --- Symlink mode ---

if [ "$MODE" = "symlink" ]; then
    echo "Installing gig via symlinks (dev mode)..."

    # Remove existing (copy or symlink) before creating new symlinks
    [ -e "$SKILLS_DEST" ] && rm -rf "$SKILLS_DEST"
    [ -e "$TEMPLATES_DEST" ] && rm -rf "$TEMPLATES_DEST"
    [ -e "$HOOKS_DEST" ] && rm -rf "$HOOKS_DEST"

    # Ensure parent directories exist
    mkdir -p "$(dirname "$SKILLS_DEST")"
    mkdir -p "$(dirname "$TEMPLATES_DEST")"
    mkdir -p "$(dirname "$HOOKS_DEST")"

    ln -s "$SCRIPT_DIR/skills" "$SKILLS_DEST"
    echo "  Linked skills: $SKILLS_DEST -> $SCRIPT_DIR/skills"

    ln -s "$SCRIPT_DIR/templates" "$TEMPLATES_DEST"
    echo "  Linked templates: $TEMPLATES_DEST -> $SCRIPT_DIR/templates"

    ln -s "$SCRIPT_DIR/hooks" "$HOOKS_DEST"
    echo "  Linked hooks: $HOOKS_DEST -> $SCRIPT_DIR/hooks"

# --- Copy mode (default) ---

else
    echo "Installing gig..."

    for skill in $SKILLS; do
        dest="$SKILLS_DEST/$skill"
        mkdir -p "$dest"
        cp "$SCRIPT_DIR/skills/$skill/SKILL.md" "$dest/SKILL.md"
        echo "  Installed skill: $skill"
    done

    mkdir -p "$TEMPLATES_DEST"
    for tmpl in "$SCRIPT_DIR"/templates/*.md; do
        cp "$tmpl" "$TEMPLATES_DEST/"
        echo "  Installed template: $(basename "$tmpl")"
    done

    mkdir -p "$HOOKS_DEST"
    for hook in "$SCRIPT_DIR"/hooks/*; do
        cp "$hook" "$HOOKS_DEST/"
        chmod +x "$HOOKS_DEST/$(basename "$hook")"
        echo "  Installed hook: $(basename "$hook")"
    done
fi

# --- Offer to append workflow rules to CLAUDE.md ---

echo ""
printf "Append gig workflow rules to %s? [y/N] " "$CLAUDE_MD"
read -r answer || answer="n"

case "$answer" in
    [yY]|[yY][eE][sS])
        if [ -f "$CLAUDE_MD" ]; then
            # Remove existing gig section if present (update, not duplicate)
            if grep -q "# --- gig workflow rules ---" "$CLAUDE_MD" 2>/dev/null; then
                cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
                sed '/^# --- gig workflow rules ---$/,/^# --- end gig workflow rules ---$/d' "$CLAUDE_MD.bak" > "$CLAUDE_MD"
                echo "  Removed old gig rules section"
            else
                cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
            fi
            echo "  Backed up CLAUDE.md to CLAUDE.md.bak"
        fi

        {
            echo ""
            echo "# --- gig workflow rules ---"
            echo ""
            cat "$RULES_SRC"
            echo ""
            echo "# --- end gig workflow rules ---"
        } >> "$CLAUDE_MD"

        echo "  Appended gig workflow rules to CLAUDE.md"
        ;;
    *)
        echo "  Skipped. You can find the rules in docs/RULES.md"
        ;;
esac

# --- Register hooks in settings.json ---

if [ "$HAS_JQ" = true ]; then
    # Determine the absolute path to the installed hooks
    if [ "$MODE" = "symlink" ]; then
        HOOK_PATH="$SCRIPT_DIR/hooks/govern-context-check.sh"
    else
        HOOK_PATH="$HOOKS_DEST/govern-context-check.sh"
    fi

    # Ensure settings.json exists with at least an empty object
    if [ ! -f "$SETTINGS" ]; then
        echo '{}' > "$SETTINGS"
    fi

    # Check if gig hook is already registered (by filename)
    if ! jq -e '
        [.hooks.UserPromptSubmit // [] | .[] | .hooks[]? | .command] | any(test("govern-context-check\\.sh$"))
    ' "$SETTINGS" >/dev/null 2>&1; then
        cp "$SETTINGS" "$SETTINGS.bak"
        jq --arg cmd "$HOOK_PATH" '
          .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + [
            {
              "matcher": "gig:govern",
              "hooks": [
                {
                  "type": "command",
                  "command": $cmd
                }
              ]
            }
          ]
        ' "$SETTINGS.bak" > "$SETTINGS"
        echo "  Registered gig hooks in settings.json"
    else
        echo "  Gig hooks already registered in settings.json"
    fi
else
    echo ""
    echo "  Note: jq not found — hook files installed but not registered in settings.json."
    echo "  Install jq and re-run, or manually add the hook to ~/.claude/settings.json."
fi

# --- Done ---

echo ""
echo "Installation complete."
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to pick up the new skills"
echo "  2. Navigate to a project directory and run /gig:init"
