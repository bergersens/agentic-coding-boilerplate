---
name: to-issues
description: Use ONLY when invoked via the /to-issues slash command. Breaks a PRD or plan into independently-grabbable issues in ./issues/ using tracer-bullet vertical slices. Each issue is a thin end-to-end slice through all layers, not a horizontal slice of one layer.
---

# To Issues

Break a plan into independently-grabbable issues using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passed an issue reference (path to a PRD in `./issues/`) as an argument, read its full body.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Issue titles and descriptions should use the project's domain vocabulary.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

**Vertical slice rules:**

- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Any prefactoring should be done first
- Feedback should be available at the end of the slice - not multiple slices later

**Anti-pattern (horizontal slicing):** "Phase 1: all schema changes. Phase 2: all API. Phase 3: all UI." The agent codes blind until phase 3. Reject this shape.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: `afk` (safe for an agent to execute unattended) or `human-in-the-loop` (needs UX judgement, design decisions, or manual QA)
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Is the first slice a true vertical slice, or is it horizontal?

**Iterate until the user approves the breakdown.**

### 5. Write the issues to ./issues/

For each approved slice, write a new markdown file to `./issues/` named `NN-<slug>.md` where `NN` is a zero-padded incrementing number (e.g. `01-add-points-schema.md`).

Publish in dependency order (blockers first) so you can reference real filenames in `blocked_by`.

### Issue Template

```markdown
---
title: <short descriptive title>
status: ready-for-agent
type: afk           # or: human-in-the-loop
blocked_by: []      # list of issue filenames, e.g. ["01-add-points-schema.md"]
parent: <PRD filename, or omit>
---

# <title>

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it here and note briefly that it came from a prototype.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- `01-<other-issue>.md` (or "None - can start immediately")
```

Do NOT modify or close the parent PRD.
