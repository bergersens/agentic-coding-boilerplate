# issues/

This is the local issue tracker. Everything the AFK Ralph loop picks up lives here as a markdown file.

## Layout

```
issues/
  PRD-<slug>.md         Product Requirement Docs (written by /to-prd)
  01-<slug>.md          Vertical-slice issues (written by /to-issues)
  02-<slug>.md
  ...
  done/                 Completed issues (Ralph moves them here)
```

## Issue frontmatter

Every issue file starts with YAML frontmatter:

```yaml
---
title: Short descriptive title
status: ready-for-agent    # or: in-progress, blocked, done
type: afk                  # or: human-in-the-loop
blocked_by: []             # list of issue filenames
parent: PRD-gamification.md
---
```

- `type: afk` — the Ralph loop is allowed to pick this up unattended.
- `type: human-in-the-loop` — needs UX judgement, design decisions, or manual QA. Ralph will skip it.
- `blocked_by: []` — Ralph will only start work on issues whose blockers are already in `done/`.

## Workflow

1. `/grill-me` → align on the feature
2. `/to-prd` → writes `PRD-<slug>.md` here
3. `/to-issues PRD-<slug>.md` → writes numbered vertical slices here
4. `./scripts/ralph/once.sh` (or `afk.sh N`) → Ralph picks up AFK issues and moves them to `done/` on completion
