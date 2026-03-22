#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CLAUDE_DIR="$HOME/.claude"
SKILLS_DEST="$CLAUDE_DIR/skills/gig"
TEMPLATES_DEST="$CLAUDE_DIR/templates/gig"
HOOKS_DEST="$CLAUDE_DIR/hooks/gig"
SETTINGS="$CLAUDE_DIR/settings.json"

SKILLS="init gather implement govern status milestone research handoff"
HAS_JQ=false
SKIP_HOOKS=false

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
            echo "      --no-hooks    Skip hook installation and registration"
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
        --no-hooks)
            SKIP_HOOKS=true
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

    if [ -e "$CLAUDE_DIR/templates/project" ]; then
        rm -rf "$CLAUDE_DIR/templates/project"
        echo "  Removed $CLAUDE_DIR/templates/project"
    fi

    if [ -e "$HOOKS_DEST" ]; then
        rm -rf "$HOOKS_DEST"
        echo "  Removed $HOOKS_DEST"
    fi

    # Remove all gig hook entries from settings.json
    if [ "$HAS_JQ" = true ] && [ -f "$SETTINGS" ]; then
        if jq -e '.hooks' "$SETTINGS" >/dev/null 2>&1; then
            cp "$SETTINGS" "$SETTINGS.bak"
            jq '
              .hooks |= with_entries(
                .value |= map(
                  select(.hooks | all(
                    .command | (
                      test("govern-context-check\\.sh$") or
                      test("check-readme\\.sh$") or
                      test("block-git-add\\.sh$") or
                      test("load-gig-state\\.sh$")
                    ) | not
                  ))
                )
              ) |
              .hooks |= with_entries(select(.value | length > 0))
            ' "$SETTINGS.bak" > "$SETTINGS"
            echo "  Removed gig hooks from settings.json"
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

    if [ "$SKIP_HOOKS" = false ]; then
        ln -s "$SCRIPT_DIR/hooks" "$HOOKS_DEST"
        echo "  Linked hooks: $HOOKS_DEST -> $SCRIPT_DIR/hooks"
    fi

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
    for tmpl in "$SCRIPT_DIR"/templates/gig/*.md; do
        cp "$tmpl" "$TEMPLATES_DEST/"
        echo "  Installed template: $(basename "$tmpl")"
    done

    # Copy RULES.md for use by /gig:init project-level setup
    cp "$SCRIPT_DIR/docs/RULES.md" "$TEMPLATES_DEST/RULES.md"
    echo "  Installed template: RULES.md"

    PROJECT_TEMPLATES_DEST="$CLAUDE_DIR/templates/project"
    mkdir -p "$PROJECT_TEMPLATES_DEST"
    for tmpl in "$SCRIPT_DIR"/templates/project/*.md; do
        cp "$tmpl" "$PROJECT_TEMPLATES_DEST/"
        echo "  Installed project template: $(basename "$tmpl")"
    done

    if [ "$SKIP_HOOKS" = false ]; then
        mkdir -p "$HOOKS_DEST"
        for hook in "$SCRIPT_DIR"/hooks/*; do
            cp "$hook" "$HOOKS_DEST/"
            chmod +x "$HOOKS_DEST/$(basename "$hook")"
            echo "  Installed hook: $(basename "$hook")"
        done
    fi
fi

# --- Register hooks in settings.json ---

if [ "$SKIP_HOOKS" = true ]; then
    echo "  Skipped hooks (--no-hooks)"
elif [ "$HAS_JQ" = true ]; then
    # Determine the absolute path prefix for hooks
    if [ "$MODE" = "symlink" ]; then
        HOOK_DIR="$SCRIPT_DIR/hooks"
    else
        HOOK_DIR="$HOOKS_DEST"
    fi

    # Ensure settings.json exists with at least an empty object
    if [ ! -f "$SETTINGS" ]; then
        echo '{}' > "$SETTINGS"
    fi

    REGISTERED=0

    # Helper: register a hook if not already present
    register_hook() {
        event="$1"
        matcher="$2"
        script="$3"
        filename=$(basename "$script")

        if ! jq -e --arg e "$event" --arg f "$filename" '
            [.hooks[$e] // [] | .[] | .hooks[]? | .command] | any(test($f + "$"))
        ' "$SETTINGS" >/dev/null 2>&1; then
            cp "$SETTINGS" "$SETTINGS.bak"
            jq --arg e "$event" --arg m "$matcher" --arg cmd "$script" '
              .hooks[$e] = (.hooks[$e] // []) + [
                {
                  "matcher": $m,
                  "hooks": [
                    {
                      "type": "command",
                      "command": $cmd
                    }
                  ]
                }
              ]
            ' "$SETTINGS.bak" > "$SETTINGS"
            REGISTERED=$((REGISTERED + 1))
        fi
    }

    register_hook "UserPromptSubmit" "gig:govern" "$HOOK_DIR/govern-context-check.sh"
    register_hook "UserPromptSubmit" "gig:govern" "$HOOK_DIR/check-readme.sh"
    register_hook "PreToolUse" "Bash" "$HOOK_DIR/block-git-add.sh"
    register_hook "SessionStart" "" "$HOOK_DIR/load-gig-state.sh"

    if [ "$REGISTERED" -gt 0 ]; then
        echo "  Registered $REGISTERED gig hook(s) in settings.json"
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
