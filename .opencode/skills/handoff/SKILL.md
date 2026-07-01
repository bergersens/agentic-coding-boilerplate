---
name: handoff
description: Use ONLY when invoked via the /handoff slash command. Compacts the current conversation into a handoff document so a fresh agent can continue the work without the accumulated context.
---

# Handoff

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to the OS temp directory (`$TMPDIR` on macOS/Linux, fallback `/tmp`) — not the current workspace.

Include a **"suggested skills" section** in the document that lists which skills the next agent should invoke.

## Rules

- Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). **Reference them by path or URL instead.**
- Redact any sensitive information: API keys, passwords, personally identifiable information.
- If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## Template

```markdown
# Handoff — <short title>

**Date:** <ISO>
**Focus for next session:** <from arguments or inferred>

## Where we left off

One paragraph. What was being worked on, what's blocking, what's the immediate next step.

## Key decisions made this session

- Decision 1 (why)
- Decision 2 (why)

## Open questions

- Question 1
- Question 2

## References

- `issues/03-add-points-schema.md` — active issue
- `issues/PRD-gamification.md` — parent PRD
- commit `abc1234` — last known-good state

## Suggested skills for next session

- `/grill-me` — to align on the open questions above before writing more code
- `tdd` skill — for continuing implementation red-green-refactor
- `/diagnose` — if the failing test in `x_test.ts` returns
```

Print the absolute path of the handoff file to the user.
