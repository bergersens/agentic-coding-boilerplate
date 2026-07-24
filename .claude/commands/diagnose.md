---
description: Structured 6-phase bug diagnosis — feedback loop first, always.
---

Delegate to the `implement` subagent (Agent tool) with the instructions below.
Relay its diagnosis and its final evolution question back to me.

Diagnose the bug below following `.references/diagnosing.md` exactly.
Do not hypothesize until you have a tight, red-capable, deterministic,
agent-runnable feedback loop (Phase 1). Build the regression test before the
fix. End with the system-evolution question: what rule, reference doc, or gate
would have prevented this?

Bug: $ARGUMENTS
