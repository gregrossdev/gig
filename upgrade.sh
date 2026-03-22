#!/bin/sh
# upgrade.sh — Update an existing .gig/ directory to match the current gig version.
# Adds missing template files, runs terminology migration, and sets .gig-version.
#
# Usage: /path/to/gig/upgrade.sh [path] [--dry-run]
#   path       Project directory containing .gig/ (default: current directory)
#   --dry-run  Preview changes without modifying anything
#
# Safe to run multiple times — idempotent.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR=""
DRY_RUN=false

# Current gig version (read from plugin.json if available, fallback to hardcoded)
if [ -f "$SCRIPT_DIR/.claude-plugin/plugin.json" ] && command -v jq >/dev/null 2>&1; then
    GIG_VERSION=$(jq -r '.version' "$SCRIPT_DIR/.claude-plugin/plugin.json")
else
    GIG_VERSION="0.61.2"
fi

# --- Argument parsing ---

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: ./upgrade.sh [OPTIONS] [path]"
            echo ""
            echo "Update an existing .gig/ directory to match the current gig version."
            echo ""
            echo "Arguments:"
            echo "  path          Project directory containing .gig/ (default: current directory)"
            echo ""
            echo "Options:"
            echo "  -h, --help    Show this help message"
            echo "  --dry-run     Preview changes without modifying anything"
            echo ""
            echo "What it does:"
            echo "  1. Runs terminology migration (phase -> iteration)"
            echo "  2. Adds missing template files to .gig/"
            echo "  3. Sets .gig/.gig-version to track the gig version"
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Run ./upgrade.sh --help for usage."
            exit 1
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            else
                echo "Error: unexpected argument '$1'"
                exit 1
            fi
            shift
            ;;
    esac
done

# Default to current directory
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="."
fi

GIG_DIR="$TARGET_DIR/.gig"

# --- Guard check ---

if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory not found: $TARGET_DIR"
    exit 1
fi

if [ ! -d "$GIG_DIR" ]; then
    echo "No .gig/ directory found in $(cd "$TARGET_DIR" && pwd)."
    echo "Run /gig:init first to initialize the project."
    exit 1
fi

echo "Upgrading .gig/ in $(cd "$TARGET_DIR" && pwd)..."
if [ "$DRY_RUN" = true ]; then
    echo "(dry run — no changes will be made)"
fi
echo ""

CHANGED=0

# --- Step 1: Terminology migration ---

if [ -f "$SCRIPT_DIR/migrate.sh" ]; then
    # Check if migration is needed before running
    NEEDS_MIGRATE=false
    if [ -f "$GIG_DIR/STATE.md" ] && grep -q '| \*\*Phase\*\*' "$GIG_DIR/STATE.md" 2>/dev/null; then
        NEEDS_MIGRATE=true
    fi
    if [ -f "$GIG_DIR/ROADMAP.md" ] && grep -q '^## Phases$' "$GIG_DIR/ROADMAP.md" 2>/dev/null; then
        NEEDS_MIGRATE=true
    fi

    if [ "$NEEDS_MIGRATE" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would run terminology migration (phase -> iteration)"
            CHANGED=$((CHANGED + 1))
        else
            (cd "$TARGET_DIR" && sh "$SCRIPT_DIR/migrate.sh")
            CHANGED=$((CHANGED + 1))
        fi
    fi
fi

# --- Step 2: Add missing template files ---

# Determine template source: repo templates/ or installed ~/.claude/templates/gig/
TEMPLATE_DIR=""
if [ -d "$SCRIPT_DIR/templates" ]; then
    TEMPLATE_DIR="$SCRIPT_DIR/templates"
elif [ -d "$HOME/.claude/templates/gig" ]; then
    TEMPLATE_DIR="$HOME/.claude/templates/gig"
fi

if [ -z "$TEMPLATE_DIR" ]; then
    echo "  Warning: No template source found. Skipping missing file check."
else
    # Scan template directory for all .md files
    for tmpl_path in "$TEMPLATE_DIR"/*.md; do
        tmpl=$(basename "$tmpl_path")
        if [ ! -f "$GIG_DIR/$tmpl" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [dry-run] Would add missing file: $tmpl"
            else
                cp "$tmpl_path" "$GIG_DIR/$tmpl"
                echo "  Added missing file: $tmpl"
            fi
            CHANGED=$((CHANGED + 1))
        fi
    done

    # Ensure iterations/ directory exists
    if [ ! -d "$GIG_DIR/iterations" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would create iterations/ directory"
        else
            mkdir -p "$GIG_DIR/iterations"
            echo "  Created iterations/ directory"
        fi
        CHANGED=$((CHANGED + 1))
    fi
fi

# --- Step 3: Set .gig-version ---

CURRENT_VERSION=""
if [ -f "$GIG_DIR/.gig-version" ]; then
    CURRENT_VERSION=$(cat "$GIG_DIR/.gig-version")
fi

if [ "$CURRENT_VERSION" != "$GIG_VERSION" ]; then
    if [ "$DRY_RUN" = true ]; then
        if [ -z "$CURRENT_VERSION" ]; then
            echo "  [dry-run] Would set .gig-version to $GIG_VERSION (new)"
        else
            echo "  [dry-run] Would update .gig-version from $CURRENT_VERSION to $GIG_VERSION"
        fi
    else
        printf '%s\n' "$GIG_VERSION" > "$GIG_DIR/.gig-version"
        if [ -z "$CURRENT_VERSION" ]; then
            echo "  Set .gig-version to $GIG_VERSION"
        else
            echo "  Updated .gig-version from $CURRENT_VERSION to $GIG_VERSION"
        fi
    fi
    CHANGED=$((CHANGED + 1))
fi

# --- Summary ---

echo ""
if [ "$DRY_RUN" = true ]; then
    if [ "$CHANGED" -eq 0 ]; then
        echo "No changes needed — .gig/ is up to date (version $GIG_VERSION)."
    else
        echo "Dry run complete. $CHANGED change(s) would be applied."
    fi
else
    if [ "$CHANGED" -eq 0 ]; then
        echo "No changes needed — .gig/ is up to date (version $GIG_VERSION)."
    else
        echo "Done. $CHANGED change(s) applied. .gig/ is now at version $GIG_VERSION."
    fi
fi
