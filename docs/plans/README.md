# docs/plans/

Reviewable implementation plans, written by the `planner` agent **only when you
ask for one** via `/plan <issue>`.

The build loop does not plan. `/implement` runs `coder` → `verifier` and nothing
else: the `issue-planner` already recorded the `## Seams` and `## Behaviors` while
exploring the codebase, and the `coder` derives its own order of attack from the
ticket. So an empty `docs/plans/` is the normal, healthy state.

## When a plan is worth its cold start

Ask for one when *you* want to argue with the approach before code exists:

- a risky or irreversible slice (data migration, auth, money),
- an unfamiliar module where you want the seam named before it's touched,
- a design you suspect is wrong and want on paper to push back on.

The value is the review, not the document. A plan nobody reads is pure overhead —
that's why nothing generates them automatically.

## How it flows

```
/plan <issue>   → planner writes docs/plans/<issue>.plan.md, then STOPS
you             → read it, edit it, argue with it
/implement      → picks the plan up automatically and passes it to the coder
```

The plan overrides the coder's own judgment on approach, so your edits are the
point of the exercise.

## What a plan carries that an issue can't

An issue states *what* and *why*. A plan adds the judgment: the order of attack,
the risks, and the alternatives that were considered and rejected. If a plan only
restates the ticket, it wasn't worth writing.

## Layout

```
docs/plans/
  NN-<slug>.plan.md     one plan per issue you asked for
  done/                 plans whose issue has shipped
```

`./scripts/adw/close-issue.sh <issue>` moves the matching plan into `done/` when
the issue ships. Plans from before the loop was shortened stay in `done/` as
history.

## If the planner returns BLOCKED

That means the issue can't be planned as one slice — usually it's too large. The
fix is re-slicing it via `issue-planner`, not planning harder. The same is true if
the `coder` returns `BLOCKED` during a build: a bad ticket is a ticket problem.
