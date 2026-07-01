#!/bin/bash
# Ralph AFK loop: runs the agent unattended for N iterations.
# Each iteration re-reads the current issues + last commits, so newly-added
# issues get picked up automatically.
#
# The loop exits early when the agent outputs <promise>NO MORE TASKS</promise>.
#
# Usage:  ./scripts/ralph/afk.sh <iterations>
#         ./scripts/ralph/afk.sh 20

set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

for ((i=1; i<=$1; i++)); do
  echo ""
  echo "=============================="
  echo " Ralph iteration $i / $1"
  echo "=============================="
  echo ""

  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  commits=$(git log -n 5 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No commits found")
  issues=$(cat issues/*.md 2>/dev/null || echo "No issues found")
  prompt=$(cat scripts/ralph/prompt.md)

  # opencode run streams output; we also capture it to detect the completion sentinel.
  opencode run "Previous commits: $commits Issues: $issues $prompt" \
    | tee "$tmpfile"

  if grep -q "<promise>NO MORE TASKS</promise>" "$tmpfile"; then
    echo ""
    echo "Ralph complete after $i iterations."
    exit 0
  fi
done

echo ""
echo "Ralph reached max iterations ($1) without completing all AFK tasks."
