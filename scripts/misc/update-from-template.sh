#!/bin/bash
# Update the shared agent layer of this project from the boilerplate template.
#
# GitHub "template" repos are NOT linked like forks, so updates have to be
# pulled in explicitly. This script adds the boilerplate as a git remote called
# `template`, fetches it, and overwrites ONLY the shared agent-layer paths —
# leaving everything project-specific (AGENTS.md, opencode.json, docs/issues/, docs/prds/,
# your own skills/agents/commands) untouched.
#
# It overwrites files that exist in the template. Files you added inside the
# shared folders are left alone (git checkout only writes what the template
# has). Nothing is committed — you review the diff and commit yourself.
#
# Usage:
#   ./scripts/misc/update-from-template.sh            # sync from the default template
#   ./scripts/misc/update-from-template.sh <git-url>  # sync from a different template
#   TEMPLATE_REF=some-branch ./scripts/misc/update-from-template.sh
#   npm run update-from-template                      # same, via npm
#   npm run update-from-template -- <git-url>         # pass args after --

set -eo pipefail

TEMPLATE_URL="${1:-https://github.com/bergersens/opencode-boilerplate.git}"
TEMPLATE_REF="${TEMPLATE_REF:-main}"

# Paths owned by the template (overwritten on sync). Edit this list to taste —
# e.g. add "AGENTS.md" if you want house rules pulled in too.
SHARED_PATHS=(
  ".opencode/agent"
  ".opencode/command"
  ".opencode/reference"
  "scripts/adw"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "⚠  Working tree is dirty. Commit or stash first so you can cleanly review"
  echo "   what the template changes. Aborting."
  exit 1
fi

# Add or update the `template` remote.
if git remote get-url template >/dev/null 2>&1; then
  git remote set-url template "$TEMPLATE_URL"
else
  git remote add template "$TEMPLATE_URL"
fi

echo "Fetching template from $TEMPLATE_URL ($TEMPLATE_REF)…"
git fetch --quiet template "$TEMPLATE_REF"

echo "Overwriting shared paths from template/$TEMPLATE_REF:"
for p in "${SHARED_PATHS[@]}"; do
  if git cat-file -e "template/$TEMPLATE_REF:$p" 2>/dev/null; then
    git checkout "template/$TEMPLATE_REF" -- "$p"
    echo "  ✓ $p"
  else
    echo "  – $p (not in template, skipped)"
  fi
done

echo ""
if [ -n "$(git status --porcelain)" ]; then
  echo "Done. Review the changes, then commit:"
  echo ""
  git status --short
  echo ""
  echo "    git add -A && git commit -m \"Update agent layer from template\""
else
  echo "Already up to date — nothing changed."
fi
