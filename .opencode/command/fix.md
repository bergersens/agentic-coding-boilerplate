---
description: Fast lane for a trivial, well-understood change. No coder — you change it yourself, the verifier still gates it.
agent: implement
---

Run in **FIX mode** (see your agent prompt). This is a small, self-contained
change with no design decisions — don't spin up the `coder`.

1. Make the change directly, yourself.
2. Run the `verifier` subagent as the gate, and tell it the change class so it
   scales effort: `presentational` for a pure CSS/copy change (just confirm the
   feedback loops stay green, no new test needed), or `logic` for anything with a
   condition, calculation, or boundary (require a regression test that would
   have caught the bug).
3. If the verifier comes back FAIL, fix the must-fix findings and re-run — same
   2-round cap.
4. Commit with a message stating what changed and why.

If while working you discover this isn't actually trivial (hidden design
decisions, touches multiple layers, unclear scope), **stop and tell me** — it
should go through `/idea` or `/grill` instead. Don't quietly turn a fix into a
feature.

The change: $ARGUMENTS
