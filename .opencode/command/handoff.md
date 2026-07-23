---
description: Compact this session into a handoff document for a fresh agent.
agent: build
---

Write a handoff document so a fresh agent can continue without this session's
accumulated context. Save it to the OS temp directory (`$TMPDIR`, fallback
`/tmp`) — not the workspace. Print its absolute path when done.

Rules:
- Don't duplicate content already in PRDs, plans, issues, or commits — reference
  them by path.
- Redact secrets (API keys, passwords, PII).
- If arguments describe the next session's focus, tailor the doc to it.

Template:

```markdown
# Handoff — <short title>

**Date:** <ISO>
**Focus for next session:** <from arguments or inferred>

## Where we left off
One paragraph: what was being worked on, what's blocking, the immediate next step.

## Key decisions made this session
- Decision (why)

## Open questions
- Question

## References
- `docs/issues/NN-<slug>.md` — active issue
- `docs/prds/<slug>.md` — parent PRD
- commit `abc1234` — last known-good state

## Suggested next steps
- `/grill <topic>` — to align on the open questions before more code
- `/implement <issue>` — to continue the build loop
- `/diagnose <bug>` — if a failing test returns
```

Focus for next session: $ARGUMENTS
