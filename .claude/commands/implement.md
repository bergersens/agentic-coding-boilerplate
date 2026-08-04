---
description: Implement one ready-to-build issue through the coder→verifier gate loop.
---

Delegate to the `implement` subagent (Agent tool) with the instructions below.
Relay its result — the commit, the closed issue, or the escalation report — back
to me.

Implement a single issue end-to-end, honoring the 2-round gate cap.

If an issue is named below, work that one. Otherwise pick the highest-priority
eligible issue (all `blocked_by` resolved, prefer `type: afk`). Read it fully,
establish the feedback loops from `docs/loops.md` (write it if missing), then run
the loop: `coder` → `verifier` (gate). There is no planning step — never invoke
the `planner`. If a plan already exists at `docs/plans/<issue>.plan.md` (because I
ran `/plan`), pass it to the coder. If the coder returns BLOCKED, stop and tell me
— the ticket needs re-slicing, not another attempt.

Commit when the gate passes, then close it with
`./scripts/adw/close-issue.sh docs/issues/<file>`. If you can't get a PASS
within 2 rounds, stop and report back with the findings verbatim.

Issue: $ARGUMENTS
