#!/bin/bash
# ADW (AI Developer Workflow): deterministic code orchestrating a non-deterministic
# agent. Each iteration hands ONE issue to the `implement` orchestrator, which
# runs its own coder → verifier(gate) loop (max 2 rounds) in a fresh, isolated
# context.
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
# Engine: works with BOTH Claude Code and OpenCode. Auto-detected from PATH
# (claude preferred), or pin it explicitly:
#   ADW_ENGINE=claude   ./scripts/adw/run.sh
#   ADW_ENGINE=opencode ./scripts/adw/run.sh
#
# Debug (watch what the implement agent and its subagents actually do):
#   ADW_DEBUG=1 ./scripts/adw/run.sh          # stream the engine's response to
#                                             # screen + save a per-iteration
#                                             # debug log under scripts/adw/logs/
#   ADW_DEBUG_FILTER=api,hooks ADW_DEBUG=1 …  # (claude only) narrow debug
#                                             # categories, see `claude --debug`
#
# Permissions: AFK mode runs unattended, so there is no one to answer
# permission prompts. The allow/deny rules live per engine — .claude/settings.json
# for Claude Code, opencode.json for OpenCode — with a broad `allow` (Bash,
# Edit, …) so the loop never stalls, plus a hard `deny` for the destructive
# commands (`git push`, `git reset --hard`, `rm -rf`). Deny always wins, so those
# stay blocked even unattended. On Claude Code the run uses `--permission-mode
# default`; override with ADW_PERMISSION_MODE (e.g. bypassPermissions, acceptEdits,
# plan). ADW_PERMISSION_MODE is ignored by OpenCode (it has no such flag).
#
# Stops early when the agent emits <promise>NO MORE TASKS</promise> (all eligible
# AFK issues done or blocked by human-in-the-loop issues).

set -eo pipefail

ITERATIONS="${1:-1}"
PERMISSION_MODE="${ADW_PERMISSION_MODE:-default}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Pick the agent engine. Both read the same agents/commands (Claude from
# .claude/, OpenCode from .opencode/) and the same house rules (CLAUDE.md /
# AGENTS.md), so the loop is engine-agnostic — only the CLI invocation differs.
ENGINE="${ADW_ENGINE:-}"
if [[ -z "$ENGINE" ]]; then
  if command -v claude >/dev/null 2>&1; then
    ENGINE="claude"
  elif command -v opencode >/dev/null 2>&1; then
    ENGINE="opencode"
  else
    echo "Neither 'claude' nor 'opencode' found on PATH. Install one or set ADW_ENGINE." >&2
    exit 1
  fi
fi
if ! command -v "$ENGINE" >/dev/null 2>&1; then
  echo "ADW_ENGINE=$ENGINE but '$ENGINE' is not on PATH." >&2
  exit 1
fi
echo "ADW engine: $ENGINE"

read -r -d '' PROMPT <<'EOF' || true
You are being driven by the ADW loop, unattended (AFK mode).

Work on exactly ONE issue this iteration, then stop.

1. Read the open issues in `docs/issues/`. Each has YAML frontmatter with `type`
   (afk | human-in-the-loop), `status`, and `blocked_by`.
2. Pick the highest-priority eligible issue: `type: afk`, and every entry in
   its `blocked_by` already in `docs/issues/done/`. Priority order: critical
   bugfixes → dev infrastructure → tracer bullets → polish → refactors.
3. If NO eligible afk issue exists at the START of this iteration (all done,
   or only human-in-the-loop issues remain, or everything left is blocked by
   human-in-the-loop work), output exactly `<promise>NO MORE TASKS</promise>`
   and stop — do nothing else.
4. Otherwise run your gate loop on that ONE issue: `coder` → `verifier`, at most
   2 rounds. Skip the `planner` unless the issue genuinely isn't buildable as
   written (see the escalation criteria in your prompt). Commit when the gate
   returns PASS, then close it with
   `./scripts/adw/close-issue.sh docs/issues/<file>` — that script handles the
   issue, its plan, and the parent PRD. If you can't reach PASS in 2 rounds,
   append a note to the issue describing the blocker and stop (do NOT emit the
   NO MORE TASKS promise — this issue still needs a human).

IMPORTANT — the NO MORE TASKS promise is ONLY for the case where you found no
eligible issue at the START (step 3). If you DID work on an issue in step 4,
simply stop when finished — do NOT re-check eligibility afterward and do NOT
emit the promise. The outer loop starts a fresh iteration (with a fresh
context) that will pick the next eligible issue itself; re-checking at the end
of your run risks a false "no more tasks" that stops the whole loop early.

Never touch human-in-the-loop issues. Never edit PRD content — you may only
relocate a fully-shipped PRD to `docs/prds/done/`. Never run destructive git
commands.
EOF

for ((i=1; i<=ITERATIONS; i++)); do
  echo ""
  echo "=============================="
  echo " ADW iteration $i / $ITERATIONS"
  echo "=============================="
  echo ""

  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  if [[ "$ENGINE" == "claude" ]]; then
    # Stream events as JSON so we can render them live (format-stream-claude.js)
    # while tee'ing the raw jsonl to $tmpfile for the NO-MORE-TASKS grep.
    # `claude -p` in plain text mode only prints once at the very end —
    # stream-json is what makes the loop watchable live in the terminal.
    if [[ -n "${ADW_DEBUG:-}" ]]; then
      # Additionally write Claude Code's internal debug logs (subagent tool
      # calls, API, hooks, timings) to a persistent per-iteration file.
      mkdir -p "$REPO_ROOT/scripts/adw/logs"
      logfile="$REPO_ROOT/scripts/adw/logs/adw-$(date +%Y%m%d-%H%M%S)-iter$i.log"
      echo "(debug) full debug log for this iteration → $logfile"
      debug_args=(--debug)
      [[ -n "${ADW_DEBUG_FILTER:-}" ]] && debug_args=(--debug "$ADW_DEBUG_FILTER")
      claude -p --agent implement --permission-mode "$PERMISSION_MODE" \
        --verbose --output-format stream-json "${debug_args[@]}" --debug-file "$logfile" \
        "$PROMPT" | tee "$tmpfile" | node "$SCRIPT_DIR/format-stream-claude.js"
    else
      claude -p --agent implement --permission-mode "$PERMISSION_MODE" \
        --verbose --output-format stream-json \
        "$PROMPT" | tee "$tmpfile" | node "$SCRIPT_DIR/format-stream-claude.js"
    fi
  else
    # OpenCode: stream raw JSON events and render them live via
    # format-stream-opencode.js (mirrors format-stream-claude.js for the Claude
    # engine). Plain `opencode run` only prints the orchestrator's final
    # answer, which hides every tool call and subagent spawn — `--format json`
    # surfaces each orchestrator step (bash, read, edit, task/...) as it
    # happens, so the loop is watchable live in the terminal. Permission rules
    # come from opencode.json, not --permission-mode.
    if [[ -n "${ADW_DEBUG:-}" ]]; then
      mkdir -p "$REPO_ROOT/scripts/adw/logs"
      logfile="$REPO_ROOT/scripts/adw/logs/adw-$(date +%Y%m%d-%H%M%S)-iter$i.log"
      echo "(debug) full log for this iteration → $logfile"
      opencode run --format json --print-logs --log-level "${ADW_LOG_LEVEL:-DEBUG}" \
        --agent implement "$PROMPT" 2>&1 \
        | tee "$tmpfile" "$logfile" \
        | node "$SCRIPT_DIR/format-stream-opencode.js"
    else
      opencode run --format json --agent implement "$PROMPT" 2>&1 \
        | tee "$tmpfile" \
        | node "$SCRIPT_DIR/format-stream-opencode.js"
    fi
  fi

  if grep -q "<promise>NO MORE TASKS</promise>" "$tmpfile"; then
    echo ""
    echo "ADW complete after $i iteration(s): no eligible AFK issues remain."
    exit 0
  fi
done

echo ""
echo "ADW reached max iterations ($ITERATIONS) without draining all AFK issues."
