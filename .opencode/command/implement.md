---
description: Implement one ready-to-build issue through the planner→coder→tester→reviewer gate loop.
agent: implement
---

Implement a single issue end-to-end, honoring the 3-round gate cap.

If an issue is named below, work that one. Otherwise pick the highest-priority
eligible issue (all `blocked_by` resolved, prefer `type: afk`). Read it fully,
then run the loop: `planner` → `coder` → `tester` (gate) → `reviewer` (gate).
Commit when both gates pass, then close it per your Close step: issue →
`docs/issues/done/`, its plan → `docs/plans/done/`, and the parent PRD →
`docs/prds/done/` once its last issue ships. If you can't get green + approved
within 3 rounds, stop and report back to me.

Issue: $ARGUMENTS
