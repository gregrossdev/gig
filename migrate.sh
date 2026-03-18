#!/bin/sh
# migrate.sh — Update an existing .gig/ directory from "phase" to "iteration" terminology.
# Run this in any project that has a .gig/ directory created before the iteration rename.
#
# Usage: /path/to/gig/migrate.sh
#   or:  cd your-project && /path/to/gig/migrate.sh
#
# Safe to run multiple times — only replaces exact patterns.

set -e

GIG_DIR=".gig"

if [ ! -d "$GIG_DIR" ]; then
    echo "No .gig/ directory found in $(pwd)."
    echo "Run this script from a project that has been initialized with gig."
    exit 1
fi

echo "Migrating .gig/ from 'phase' to 'iteration' terminology..."
echo ""

CHANGED=0

# --- STATE.md ---
if [ -f "$GIG_DIR/STATE.md" ]; then
    if grep -q '| \*\*Phase\*\*' "$GIG_DIR/STATE.md" 2>/dev/null; then
        sed -i.bak 's/| \*\*Phase\*\*/| **Iteration**/g' "$GIG_DIR/STATE.md"
        rm -f "$GIG_DIR/STATE.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  STATE.md: renamed **Phase** field to **Iteration**"
    fi
    if grep -q '| Phase |' "$GIG_DIR/STATE.md" 2>/dev/null; then
        sed -i.bak 's/| Phase |/| Iteration |/g' "$GIG_DIR/STATE.md"
        rm -f "$GIG_DIR/STATE.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  STATE.md: renamed Phase column header to Iteration"
    fi
fi

# --- ISSUES.md ---
if [ -f "$GIG_DIR/ISSUES.md" ]; then
    if grep -q 'phase' "$GIG_DIR/ISSUES.md" 2>/dev/null; then
        sed -i.bak \
            -e 's/archived with their phase/archived with their iteration/g' \
            -e 's/carry forward to future phases/carry forward to future iterations/g' \
            -e 's/deferral to a future phase/deferral to a future iteration/g' \
            -e 's/\*\*Phase:\*\* {phase number where discovered}/\*\*Iteration:\*\* {iteration number where discovered}/g' \
            "$GIG_DIR/ISSUES.md"
        rm -f "$GIG_DIR/ISSUES.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  ISSUES.md: updated phase references to iteration"
    fi
fi

# --- ROADMAP.md ---
if [ -f "$GIG_DIR/ROADMAP.md" ]; then
    if grep -q '^## Phases$' "$GIG_DIR/ROADMAP.md" 2>/dev/null; then
        sed -i.bak 's/^## Phases$/## Iterations/' "$GIG_DIR/ROADMAP.md"
        rm -f "$GIG_DIR/ROADMAP.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  ROADMAP.md: renamed ## Phases to ## Iterations"
    fi
    if grep -q '^## Upcoming Phases$' "$GIG_DIR/ROADMAP.md" 2>/dev/null; then
        sed -i.bak 's/^## Upcoming Phases$/## Upcoming Iterations/' "$GIG_DIR/ROADMAP.md"
        rm -f "$GIG_DIR/ROADMAP.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  ROADMAP.md: renamed ## Upcoming Phases to ## Upcoming Iterations"
    fi
    if grep -q 'Pre-planned phases' "$GIG_DIR/ROADMAP.md" 2>/dev/null; then
        sed -i.bak \
            -e 's/Pre-planned phases/Pre-planned iterations/g' \
            -e 's/Phases added by/Iterations added by/g' \
            -e 's/Phases table/Iterations table/g' \
            -e 's/the Phases table/the Iterations table/g' \
            "$GIG_DIR/ROADMAP.md"
        rm -f "$GIG_DIR/ROADMAP.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  ROADMAP.md: updated comments"
    fi
fi

# --- ARCHITECTURE.md ---
if [ -f "$GIG_DIR/ARCHITECTURE.md" ]; then
    if grep -q 'Phase-based versioning' "$GIG_DIR/ARCHITECTURE.md" 2>/dev/null; then
        sed -i.bak \
            -e 's/Phase-based versioning/Iteration-based versioning/g' \
            -e 's/MINOR = phase number/MINOR = iteration number/g' \
            -e 's/milestone\/phase hierarchy/milestone\/iteration hierarchy/g' \
            "$GIG_DIR/ARCHITECTURE.md"
        rm -f "$GIG_DIR/ARCHITECTURE.md.bak"
        CHANGED=$((CHANGED + 1))
        echo "  ARCHITECTURE.md: updated phase references"
    fi
fi

echo ""
if [ "$CHANGED" -eq 0 ]; then
    echo "No changes needed — .gig/ already uses iteration terminology."
else
    echo "Done. $CHANGED update(s) applied."
fi
