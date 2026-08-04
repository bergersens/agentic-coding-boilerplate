#!/bin/bash
# Contribute generic agent-layer improvements from THIS project back UP to the
# boilerplate template. The mirror image of update-from-template.sh.
#
# GitHub "template" repos aren't linked like forks, so backflow is explicit.
# This script takes the specific files you name, drops them onto a fresh branch
# based on the template's main, and commits them there — so the next clone gets
# the improvement. It NEVER pushes: it prints the push + PR command and stops,
# so nothing lands on the template without your say-so (same guardrail as the
# agent's `git push` deny).
#
# Only files inside the shared agent layer may go up — project-specific files
# (docs/) are refused, so you can't leak client context into the template.
# House rules and opencode.json are allowed when named explicitly (opt-in),
# since they may carry generic improvements worth sharing back. Name
# individual files, not folders, so you upload exactly the generic change and
# nothing project-local that happens to sit in the same folder.
#
# Usage:
#   ./scripts/misc/push-to-template.sh .claude/commands/evolve.md [more files...]
#   ./scripts/misc/push-to-template.sh CLAUDE.md AGENTS.md opencode.json
#   TEMPLATE_REF=some-branch ./scripts/misc/push-to-template.sh <file...>
#   npm run push-to-template -- .claude/commands/evolve.md

set -eo pipefail

TEMPLATE_URL="${TEMPLATE_URL:-https://github.com/bergersens/opencode-boilerplate.git}"
TEMPLATE_REF="${TEMPLATE_REF:-main}"

# Roots the template owns. A file must live under one of these (or be one of
# the exact root-level files listed) to go up. Both agent layers are shared:
# .claude/ (Claude Code) and .opencode/ (OpenCode). House rules and the
# OpenCode config are normally project-local, but can be contributed up too
# — opt in by naming them explicitly.
ALLOWED_ROOTS=(
  ".claude/agents" ".claude/commands"
  ".opencode/agent" ".opencode/command"
  ".references"
  "scripts/adw" "scripts/misc"
)
ALLOWED_FILES=(
  "CLAUDE.md"
  "AGENTS.md"
  "opencode.json"
  ".claude/settings.json"
  "README.md"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <file> [file...]   (files inside: ${ALLOWED_ROOTS[*]})" >&2
  exit 1
fi

# Validate every path before touching git.
for f in "$@"; do
  [ -f "$f" ] || { echo "✗ not a file: $f" >&2; exit 1; }
  ok=""
  for root in "${ALLOWED_ROOTS[@]}"; do
    case "$f" in "$root"/*) ok=1;; esac
  done
  for af in "${ALLOWED_FILES[@]}"; do
    [ "$f" = "$af" ] && ok=1
  done
  [ -n "$ok" ] || { echo "✗ refused (not in shared agent layer): $f" >&2; exit 1; }
  if [ -n "$(git status --porcelain -- "$f")" ]; then
    echo "✗ uncommitted changes in $f — commit it here first, then contribute up." >&2
    exit 1
  fi
done

# Add or update the `template` remote and fetch it.
if git remote get-url template >/dev/null 2>&1; then
  git remote set-url template "$TEMPLATE_URL"
else
  git remote add template "$TEMPLATE_URL"
fi
echo "Fetching template from $TEMPLATE_URL ($TEMPLATE_REF)…"
git fetch --quiet template "$TEMPLATE_REF"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PROJECT="$(basename "$REPO_ROOT")"
CONTRIB_BRANCH="contrib/${PROJECT}-$(date +%Y%m%d-%H%M%S)"

# Build the contribution in a separate worktree off the template, so the main
# working tree (and any dirty/untracked files in it) is never touched. The
# contrib branch lives in the main repo's ref store; only the checkout is
# temporary.
WT="$(mktemp -d -t push-to-template.XXXXXX)"
trap 'git worktree remove --force "$WT" 2>/dev/null; rm -rf "$WT"' EXIT
git worktree add --quiet --detach "$WT" "template/$TEMPLATE_REF"
cd "$WT"
git checkout --quiet -b "$CONTRIB_BRANCH"

for f in "$@"; do mkdir -p "$(dirname "$f")"; cp "$REPO_ROOT/$f" "$f"; git add "$f"; done

if git diff --cached --quiet; then
  echo "Nothing to contribute — these files already match the template."
  cd "$REPO_ROOT"
  git worktree remove --force "$WT" 2>/dev/null
  git branch -D "$CONTRIB_BRANCH" >/dev/null 2>&1
  exit 0
fi

git commit --quiet -m "Contribute agent-layer improvements from $PROJECT

$(printf '  - %s\n' "$@")"

cd "$REPO_ROOT"
git worktree remove --force "$WT" 2>/dev/null

echo ""
echo "Prepared branch '$CONTRIB_BRANCH' with:"
printf '  - %s\n' "$@"
echo ""
echo "Review it, then push and open a PR against the template yourself:"
echo ""
echo "    git push template $CONTRIB_BRANCH"
echo "    # then open: ${TEMPLATE_URL%.git}/compare/${TEMPLATE_REF}...${CONTRIB_BRANCH}?expand=1"
