# docs/issues/

Work tickets — the shared memory of the build half of the agent architecture.
Agents run in isolated contexts and coordinate through these files, not through
a shared conversation. Long-lived PRD documents live separately in `docs/prds/`.

**An issue is the build plan.** The `issue-planner` explores the codebase before
writing it, so it records the seam the work lands in and the behaviors to drive
out. The `coder` then builds straight from the ticket — no separate planning step,
which is what keeps the build loop at two subagent calls per issue.

## Layout

```
docs/issues/
  01-<slug>.md          Vertical-slice issues (written by issue-planner / /to-issues)
  02-<slug>.md
  ...
  done/                 Completed issues
```

Each of `docs/prds/`, `docs/issues/`, and `docs/plans/` has its own `done/`
folder. `./scripts/adw/close-issue.sh <issue>` retires all three in one step —
the issue, its plan (if it had one), and the parent PRD once its last issue ships.
Don't move them by hand: a mis-moved artifact silently breaks `blocked_by`
resolution for every later issue.

Escalation plans (rare — see `docs/plans/README.md`) live in `docs/plans/`.

## Issue frontmatter

Every issue file starts with YAML frontmatter:

```yaml
---
title: Short descriptive title
status: ready-for-agent # or: in-progress, blocked, done
type: afk # or: human-in-the-loop
blocked_by: [] # list of issue filenames
parent: docs/prds/gamification.md
---
```

- `type: afk` — the `implement` orchestrator / ADW loop may pick this up unattended.
- `type: human-in-the-loop` — needs UX judgement, design decisions, or manual QA. The ADW loop skips it.
- `blocked_by: []` — work only starts on issues whose blockers are already in `done/`.
- `parent:` — required for PRD-derived issues; `close-issue.sh` uses it to retire
  the PRD once the last slice ships.

## Body sections

Beyond `## What to build` and `## Acceptance criteria`, a well-formed issue carries:

- `## Seams` — the module(s) and public interface(s) that change.
- `## Behaviors` — an ordered list of observable outcomes, each one RED→GREEN cycle
  for the coder.
- `## Out of scope` — what this slice must not touch.

If those are missing the `coder` derives them from the acceptance criteria — but if
the criteria don't map onto observable behaviors either, it returns `BLOCKED` and
the ticket comes back for re-slicing. There is no planning step to absorb a vague
ticket.

## Workflow

1. `/idea` or `/grill` → align on the feature (product orchestrator)
2. `/to-prd` → prd-writer writes a draft to `docs/prds/<slug>.md`
3. Approve the PRD (`status: draft` → `approved`)
4. `/to-issues docs/prds/<slug>.md` → issue-planner writes numbered vertical slices here
5. `/implement <issue>` (one issue, interactive) or `./scripts/adw/run.sh N`
   (unattended) → `coder` → `verifier` (gate), max 2 rounds, then commit and close
