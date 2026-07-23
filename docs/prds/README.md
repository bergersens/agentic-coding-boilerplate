# docs/prds/

Product Requirement Documents — the long-lived decision documents that the
`product` orchestrator produces and the `issue-planner` slices into `docs/issues/`.

PRDs are kept separate from `docs/issues/` on purpose: a PRD is a durable record of
*what and why*, while an issue is a short-lived unit of *work*.

## Layout

```
docs/prds/
  <slug>.md             one PRD per feature set, written by prd-writer / /to-prd
  done/                 PRDs whose issues have all shipped
```

A PRD moves into `done/` once every issue it was sliced into sits in
`docs/issues/done/`.

## Lifecycle

A PRD carries a `status` in its frontmatter:

```yaml
---
type: prd
status: draft         # draft = still an idea, in progress
created: <ISO date>   # → approved = signed off, ready to slice
---
```

- **`draft`** — a raw idea, still being shaped. `/to-issues` refuses to slice a
  draft.
- **`approved`** — signed off by the human. Only now can the `issue-planner`
  break it into vertical-slice issues.

You approve a PRD by telling the `product` orchestrator it's approved; it flips
`status: draft` → `status: approved`. Want changes first? Keep iterating on the
draft until you're happy.
