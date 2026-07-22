# issues/

Work tickets — the shared memory of the build half of the agent architecture.
Agents run in isolated contexts and coordinate through these files, not through
a shared conversation. Long-lived PRD documents live separately in `prds/`.

## Layout

```
issues/
  01-<slug>.md          Vertical-slice issues (written by issue-planner / /to-issues)
  02-<slug>.md
  ...
  plans/                Structured implementation plans (written by the planner agent)
  done/                 Completed issues (the implement orchestrator moves them here)
```

## Issue frontmatter

Every issue file starts with YAML frontmatter:

```yaml
---
title: Short descriptive title
status: ready-for-agent    # or: in-progress, blocked, done
type: afk                  # or: human-in-the-loop
blocked_by: []             # list of issue filenames
parent: prds/gamification.md
---
```

- `type: afk` — the `implement` orchestrator / ADW loop may pick this up unattended.
- `type: human-in-the-loop` — needs UX judgement, design decisions, or manual QA. The ADW loop skips it.
- `blocked_by: []` — work only starts on issues whose blockers are already in `done/`.

## Workflow

1. `/idea` or `/grill` → align on the feature (product orchestrator)
2. `/to-prd` → prd-writer writes a draft to `prds/<slug>.md`
3. Approve the PRD (`status: draft` → `approved`)
4. `/to-issues prds/<slug>.md` → issue-planner writes numbered vertical slices here
5. `/implement <issue>` (one issue, interactive) or `./scripts/adw/run.sh N`
   (unattended) → the implement orchestrator plans, builds, gates, and moves
   the issue to `done/` on completion
