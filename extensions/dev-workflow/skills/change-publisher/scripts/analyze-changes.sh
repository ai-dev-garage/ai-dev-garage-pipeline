#!/usr/bin/env bash
# Summarize uncommitted and unmerged changes for a feature branch.
# Usage: scripts/analyze-changes.sh [base-branch]
#   base-branch defaults to origin/main

set -euo pipefail

BASE=${1:-origin/main}

TICKET=$(git rev-parse --abbrev-ref HEAD | grep -oE '[A-Za-z]+-[0-9]+' || echo "UNKNOWN")

echo "=== Ticket : $TICKET ==="
echo "=== Base   : $BASE ==="
echo ""

# ── Commits ahead of base ─────────────────────────────────────────────────────
AHEAD=$(git log "$BASE..HEAD" --oneline 2>/dev/null || true)
AHEAD_COUNT=$(echo "$AHEAD" | grep -c '[^[:space:]]' || true)

if [ -n "$AHEAD" ]; then
    echo "Commits NOT yet in $BASE ($AHEAD_COUNT):"
    echo "$AHEAD"
    echo ""
    echo "→ CASE A: feature commits exist locally — recommend soft reset"
    echo "  Command: git reset --soft $BASE"
else
    echo "No commits ahead of $BASE."
    echo ""
    echo "→ CASE B: work with uncommitted changes only (no reset needed)"
fi

echo ""
echo "=== Change breakdown ==="

STAGED=$(git diff --cached --numstat 2>/dev/null || true)
UNSTAGED=$(git diff --numstat 2>/dev/null || true)

if [ -n "$STAGED" ]; then
    echo "Staged (index):"
    echo "$STAGED"
    echo ""
fi

if [ -n "$UNSTAGED" ]; then
    echo "Unstaged (working tree):"
    echo "$UNSTAGED"
    echo ""
fi

if [ -z "$STAGED" ] && [ -z "$UNSTAGED" ]; then
    echo "(no changes detected — run after soft reset if Case A)"
fi

# ── Total line count ──────────────────────────────────────────────────────────
TOTAL=$(
    { echo "$STAGED"; echo "$UNSTAGED"; } \
    | awk 'NF>=2 && $1~/^[0-9]+$/ && $2~/^[0-9]+$/ { a+=$1; d+=$2 } END { print a+d+0 }'
)

echo "Total lines changed (additions + deletions): $TOTAL"
echo ""

if   [ "$TOTAL" -eq 0 ] 2>/dev/null; then
    echo "→ Nothing to commit"
elif [ "$TOTAL" -le 500 ] 2>/dev/null; then
    echo "→ Single commit recommended"
elif [ "$TOTAL" -le 1000 ] 2>/dev/null; then
    echo "→ Consider 2 commits (target ~500 lines each)"
else
    echo "→ Split into multiple commits (target 300–500 lines each, max 1 000 per commit)"
fi
