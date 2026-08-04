---
description: Write a reviewable implementation plan for one issue, before any code exists. Optional — the build loop does not need it.
---

Delegate to the `planner` subagent (Agent tool). Pass it the issue path below (or
the highest-priority eligible issue if I didn't name one).

This is **not** part of the build loop — `/implement` runs `coder` → `verifier`
and never plans. Use this when I want the approach on paper and reviewable before
code exists: a risky slice, an unfamiliar module, a design I want to argue with
first.

The planner writes `docs/plans/<issue-basename>.plan.md` and returns the path.
Report that path back to me and summarize, in a few lines: the seam it picked, the
order of attack, and the risks or rejected alternatives it flagged. Don't dump the
whole plan — I'll read the file.

Then stop. Do **not** start implementing. I review and edit the plan first; the
next `/implement` on this issue picks it up automatically.

If the planner returns `BLOCKED`, relay its reason and its proposed split — that
usually means the issue needs re-slicing via `issue-planner`, not planning.

Issue: $ARGUMENTS
