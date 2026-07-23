#!/bin/bash
# ADW (AI Developer Workflow): deterministic code orchestrating a non-deterministic
# agent. Each iteration hands ONE issue to the `implement` orchestrator, which
# runs its own planner → coder → tester(gate) → reviewer(gate) loop (max 3
# rounds) in a fresh, isolated context.
#
# This is the "loop over an agent" pattern. The determinism lives here (issue
# selection, iteration cap, stop condition); the intelligence lives in the
# implement agent and its subagents.
#
# Usage:
#   ./scripts/adw/run.sh            # one iteration (watch it, human-in-the-loop)
#   ./scripts/adw/run.sh 20         # up to 20 iterations, unattended (AFK)
#   npm run adw                     # same, via npm
#   npm run adw -- 20               # pass args after --
#
# Stops early when the agent emits <promise>NO MORE TASKS</promise> (all eligible
# AFK issues done or blocked by human-in-the-loop issues).

set -eo pipefail

ITERATIONS="${1:-1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

read -r -d '' PROMPT <<'EOF' || true
You are being driven by the ADW loop, unattended (AFK mode).

Work on exactly ONE issue this iteration, then stop.

1. Read the open issues in `docs/issues/`. Each has YAML frontmatter with `type`
   (afk | human-in-the-loop), `status`, and `blocked_by`.
2. Pick the highest-priority eligible issue: `type: afk`, and every entry in
   its `blocked_by` already in `docs/issues/done/`. Priority order: critical
   bugfixes → dev infrastructure → tracer bullets → polish → refactors.
3. If there is NO eligible afk issue (all done, or only human-in-the-loop
   issues remain, or everything left is blocked by human-in-the-loop work),
   output exactly `<promise>NO MORE TASKS</promise>` and stop.
4. Otherwise run your full gate loop on that one issue: planner → coder →
   tester → reviewer, at most 3 rounds. Commit when both gates pass and move
   the issue to `docs/issues/done/`. If you can't reach green+approved in 3 rounds,
   append a note to the issue describing the blocker and stop (do NOT emit the
   NO MORE TASKS promise — this issue still needs a human).

Never touch human-in-the-loop issues. Never modify PRD files. Never run
destructive git commands.
EOF

for ((i=1; i<=ITERATIONS; i++)); do
  echo ""
  echo "=============================="
  echo " ADW iteration $i / $ITERATIONS"
  echo "=============================="
  echo ""

  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  opencode run --agent implement "$PROMPT" | tee "$tmpfile"

  if grep -q "<promise>NO MORE TASKS</promise>" "$tmpfile"; then
    echo ""
    echo "ADW complete after $i iteration(s): no eligible AFK issues remain."
    exit 0
  fi
done

echo ""
echo "ADW reached max iterations ($ITERATIONS) without draining all AFK issues."
