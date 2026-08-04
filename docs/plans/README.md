# docs/plans/

Structured implementation plans, written by the `planner` agent.

**Most issues never get one.** In the normal path the issue *is* the plan: the
`issue-planner` records the `## Seams` and `## Behaviors` it found while exploring
the codebase, and the `coder` builds straight from the ticket. A separate planning
step would re-pay for that same exploration.

A plan is written only when an issue isn't buildable as written — the `implement`
orchestrator escalates to the `planner` when:

- the issue has `needs_plan: true` (the issue-planner couldn't name the seam), or
- it has no `## Behaviors` / `## Seams` and its criteria don't map onto observable
  behaviors, or
- it spans more than ~3 modules, or its criteria contradict each other, or
- the `coder` came back `BLOCKED`.

So an empty `docs/plans/` is the healthy state. A directory filling up with plans
is a signal that the issues are being sliced too coarsely.

## Layout

```
docs/plans/
  NN-<slug>.plan.md     one plan per escalated issue
  done/                 plans whose issue has shipped
```

`./scripts/adw/close-issue.sh <issue>` moves the matching plan into `done/` when
the issue ships.
