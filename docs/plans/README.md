# docs/plans/

Structured implementation plans — one per issue, written by the `planner` agent
before the `coder` starts. A plan is the self-contained brief a coder executes
without re-reading the whole issue thread.

## Layout

```
docs/plans/
  NN-<slug>.plan.md     one plan per issue (planner output)
  done/                 plans whose issue has shipped
```

When the `implement` orchestrator closes an issue, it moves the matching plan
into `done/`.
