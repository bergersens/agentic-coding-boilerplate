#!/bin/bash
# Close a shipped issue: move it (and its plan, and its PRD once fully shipped)
# into the matching done/ folder.
#
# This is deliberately deterministic code, not agent reasoning. File shuffling
# has exactly one correct answer, so paying an orchestrator to think about it is
# waste — and a mis-moved artifact silently breaks `blocked_by` resolution for
# every later issue.
#
# Usage:
#   ./scripts/adw/close-issue.sh docs/issues/03-add-points-schema.md
#   ./scripts/adw/close-issue.sh 03-add-points-schema.md    # basename works too
#
# It moves:
#   docs/issues/NN-<slug>.md       → docs/issues/done/
#   docs/plans/NN-<slug>.plan.md   → docs/plans/done/    (if it exists)
#   docs/prds/<slug>.md            → docs/prds/done/     (only once no open
#                                                         issue references it)
#
# Exits non-zero if the issue doesn't exist, so a caller can't "close" a typo.
# Never commits and never pushes — the caller reviews and commits.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <issue-path-or-basename>" >&2
  exit 1
fi

ISSUE_BASE="$(basename "$1")"
ISSUE="docs/issues/$ISSUE_BASE"

if [ ! -f "$ISSUE" ]; then
  echo "✗ no such open issue: $ISSUE" >&2
  [ -f "docs/issues/done/$ISSUE_BASE" ] && echo "  (it is already in docs/issues/done/)" >&2
  exit 1
fi

# Move a file with git when it's tracked, plain mv otherwise. Keeps history
# attached for tracked artifacts without failing on untracked ones.
move() {
  local src="$1" destdir="$2"
  mkdir -p "$destdir"
  if git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    git mv -f "$src" "$destdir/"
  else
    mv -f "$src" "$destdir/"
  fi
}

# Read the parent PRD out of the issue's frontmatter BEFORE moving it.
# Matches:  parent: docs/prds/<slug>.md   (quoted or bare, absent is fine)
PARENT="$(sed -n 's/^parent:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"']*\)["'"'"']\{0,1\}[[:space:]]*$/\1/p' "$ISSUE" | head -1)"

move "$ISSUE" "docs/issues/done"
echo "✓ issue → docs/issues/done/$ISSUE_BASE"

PLAN="docs/plans/${ISSUE_BASE%.md}.plan.md"
if [ -f "$PLAN" ]; then
  move "$PLAN" "docs/plans/done"
  echo "✓ plan  → docs/plans/done/$(basename "$PLAN")"
fi

if [ -z "$PARENT" ]; then
  echo "· no parent PRD in frontmatter — nothing else to close"
  exit 0
fi

if [ ! -f "$PARENT" ]; then
  echo "· parent PRD not in docs/prds/ (already closed or moved): $PARENT"
  exit 0
fi

# The PRD is done only when NO open issue still points at it. Search the open
# issues only — done/ is a sibling directory, so a plain glob stays out of it.
remaining=0
for f in docs/issues/*.md; do
  [ -e "$f" ] || continue
  [ "$(basename "$f")" = "README.md" ] && continue
  if grep -qF -- "$PARENT" "$f"; then
    remaining=$((remaining + 1))
  fi
done

if [ "$remaining" -gt 0 ]; then
  echo "· PRD stays open: $remaining issue(s) still reference $PARENT"
else
  move "$PARENT" "docs/prds/done"
  echo "✓ PRD   → docs/prds/done/$(basename "$PARENT")  (last issue shipped)"
fi
