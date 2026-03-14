#!/bin/sh
set -e

# Resolve the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CLAUDE_DIR="$HOME/.claude"
SKILLS_DEST="$CLAUDE_DIR/skills/gig"
TEMPLATES_DEST="$CLAUDE_DIR/templates/gig"
RULES_SRC="$SCRIPT_DIR/docs/RULES.md"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

SKILLS="init gather implement govern status milestone research handoff"

# --- Preflight: validate Claude Code installation ---

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Error: ~/.claude/ directory not found."
    echo "Please install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

echo "Installing gig workflow system..."

# --- Create skill directories and copy SKILL.md files ---

for skill in $SKILLS; do
    dest="$SKILLS_DEST/$skill"
    mkdir -p "$dest"
    cp "$SCRIPT_DIR/skills/$skill/SKILL.md" "$dest/SKILL.md"
    echo "  Installed skill: $skill"
done

# --- Copy templates ---

mkdir -p "$TEMPLATES_DEST"
for tmpl in "$SCRIPT_DIR"/templates/*.md; do
    cp "$tmpl" "$TEMPLATES_DEST/"
    echo "  Installed template: $(basename "$tmpl")"
done

# --- Offer to append workflow rules to CLAUDE.md ---

echo ""
printf "Append gig workflow rules to %s? [y/N] " "$CLAUDE_MD"
read -r answer

case "$answer" in
    [yY]|[yY][eE][sS])
        if [ -f "$CLAUDE_MD" ]; then
            cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
            echo "  Backed up existing CLAUDE.md to CLAUDE.md.bak"
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

# --- Done ---

echo ""
echo "Installation complete."
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to pick up the new skills"
echo "  2. Navigate to a project directory and run /gig:init"
