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
# Because `git checkout` only ever writes, it cannot remove a file the template
# DELETED (e.g. when two agents are merged into one). Those linger locally as
# orphans — still registered with the engine, no longer called by any
# orchestrator. The sync reports them at the end; re-run with PRUNE=1 to delete
# them. Pruning is opt-in on purpose: the script can't tell a retired template
# file from an agent you wrote yourself.
#
# Usage:
#   ./scripts/misc/update-from-template.sh            # sync from the default template
#   ./scripts/misc/update-from-template.sh <git-url>  # sync from a different template
#   TEMPLATE_REF=some-branch ./scripts/misc/update-from-template.sh
#   PRUNE=1 ./scripts/misc/update-from-template.sh    # also delete orphaned files
#   npm run update-from-template                      # same, via npm
#   npm run update-from-template -- <git-url>         # pass args after --

set -eo pipefail

TEMPLATE_URL="${1:-https://github.com/bergersens/opencode-boilerplate.git}"
TEMPLATE_REF="${TEMPLATE_REF:-main}"

# Paths owned by the template (overwritten on sync). Both agent layers are
# shared: .claude/ (Claude Code) and .opencode/ (OpenCode). House rules and
# opencode.json are listed too — comment them out if you keep those
# project-local in a given client.
SHARED_PATHS=(
  ".claude/agents"
  ".claude/commands"
  ".claude/settings.json"
  ".opencode/agent"
  ".opencode/command"
  ".references"
  "scripts/adw"
  "scripts/misc"
  "CLAUDE.md"
  "AGENTS.md"
  "opencode.json"
  "README.md"
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

# Find orphans: tracked files inside a shared DIRECTORY that the template no
# longer has. These are either agents the template retired, or files you wrote
# yourself — the script can't tell, so it reports and lets you decide.
ORPHANS=()
for p in "${SHARED_PATHS[@]}"; do
  # Only directories can contain orphans; a plain file is either synced or not.
  [ -d "$p" ] || continue
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    git cat-file -e "template/$TEMPLATE_REF:$f" 2>/dev/null || ORPHANS+=("$f")
  done < <(git ls-files "$p")
done

if [ "${#ORPHANS[@]}" -gt 0 ]; then
  echo ""
  if [ -n "${PRUNE:-}" ]; then
    echo "Pruning files no longer in the template:"
    for f in "${ORPHANS[@]}"; do
      git rm --quiet "$f"
      echo "  ✗ $f"
    done
  else
    echo "⚠  In a shared folder but NOT in the template (retired upstream, or yours):"
    for f in "${ORPHANS[@]}"; do echo "     $f"; done
    echo "   A retired agent left in place stays registered with the engine even"
    echo "   though no orchestrator calls it. Delete them with:"
    echo ""
    echo "       PRUNE=1 $0"
  fi
fi

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
