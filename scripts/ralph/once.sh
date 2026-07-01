#!/bin/bash
# Ralph: single-iteration run of the AFK agent loop.
# Reads all local issues + last 5 commits + the Ralph prompt, then hands them
# to opencode in a single non-interactive run.
#
# Use this for the human-in-the-loop phase - watch what the agent does, tune
# the prompt, then graduate to `afk.sh` for a real unattended loop.
#
# Usage:  ./scripts/ralph/once.sh

set -eo pipefail

# Resolve repo root so this works from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

issues=$(cat issues/*.md 2>/dev/null || echo "No issues found")
commits=$(git log -n 5 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No commits found")
prompt=$(cat scripts/ralph/prompt.md)

opencode run "Previous commits: $commits Issues: $issues $prompt"
