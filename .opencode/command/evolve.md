---
description: Turn a just-finished feature or a recurring failure into a system improvement. Reflects execution vs. plan vs. rules, then proposes concrete edits to rules, reference docs, or commands — never auto-applied.
agent: implement
---

Run in **EVOLVE mode**. This is Philosophy #6 ("fix the system, not the bug") as
a repeatable step. You are not building anything — you are making the next build
more reliable. Don't write feature code and don't touch `docs/`.

## Input

`$ARGUMENTS` is what triggered this: a feature that just shipped, a bug you had
to fix by hand, or a pattern the agent keeps getting wrong. If empty, use the
most recent work in this session.

## Reflect

1. **Compare** what actually happened against the plan, the issue, `AGENTS.md`,
   and the relevant `.opencode/reference/` docs. Where did execution diverge
   from the rules or the process?
2. **Find the root gap**, not the symptom. A wrong result usually means a rule
   the agent never had, a reference doc that was missing or unclear, or a gap in
   a command/gate. Prefer the smallest change that would have prevented it.
3. **Check for a pattern.** If the same class of mistake shows up more than
   once, say so — recurring failures earn a stronger fix than one-offs.

## Propose (do NOT apply yet)

Map each finding to exactly one target and keep the change minimal:

- **Global rule** (`AGENTS.md`) — only if it applies no matter what's being
  worked on. Usually a one-liner. Keep this file short; if the rule is
  task-specific, it belongs in a reference doc instead.
- **Reference doc** (`.opencode/reference/*.md`) — task-type-specific knowledge
  loaded on demand. New doc, or an edit to an existing one.
- **Command / agent prompt** (`.opencode/command/*.md`, `.opencode/agent/*.md`)
  — if the process or a gate should have caught it.

For each proposal, show: the target file, the exact edit (diff or before/after),
and one sentence on which failure it prevents. If a proposal adds a reference
doc, note where its path gets wired in (global rules or the relevant command).

Then **stop and wait for my approval.** I approve per proposal — apply only what
I greenlight, then confirm the changed paths. Don't bundle unrelated changes,
and don't lower the bar on keeping `AGENTS.md` lean.

What to evolve from: $ARGUMENTS
