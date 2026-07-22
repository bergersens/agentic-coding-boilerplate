---
description: Fast lane for a trivial, well-understood change. Skips planning and review, but still tests — the orchestrator scales how hard.
agent: implement
---

Run in **FIX mode** (see your agent prompt). This is a small, self-contained
change with no design decisions — don't spin up the planner or the reviewer.

1. Make the change directly.
2. Run the `tester` subagent as a gate, but tell it the change class so it
   scales effort: for a pure presentational change (CSS/copy) just confirm the
   feedback loops (build/lint/existing tests) stay green; for anything with
   logic, require a regression test that would have caught the bug.
3. If the tester comes back RED, fix and re-run — same 3-round cap.
4. Commit with a message stating what changed and why.

If while working you discover this isn't actually trivial (hidden design
decisions, touches multiple layers, unclear scope), **stop and tell me** — it
should go through `/idea` or `/grill` instead. Don't quietly turn a fix into a
feature.

The change: $ARGUMENTS
