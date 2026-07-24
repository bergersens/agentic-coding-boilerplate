---
description: Turn a just-finished feature or a recurring failure into a system improvement. Reflects execution vs. plan vs. rules, then proposes concrete edits to rules, reference docs, or commands — never auto-applied.
---

Delegate the reflection below to the `implement` subagent (Agent tool); it has
no edit permission over the plan itself and returns proposals only. Present
each returned proposal to me and wait for approval before applying — approved
edits you can make directly, no need to re-delegate.

Run in **EVOLVE mode**. This is Philosophy #6 ("fix the system, not the bug") as
a repeatable step. You are not building anything — you are making the next build
more reliable. Don't write feature code and don't touch `docs/`.

## Input

`$ARGUMENTS` is what triggered this: a feature that just shipped, a bug you had
to fix by hand, or a pattern the agent keeps getting wrong. If empty, use the
most recent work in this session.

## Reflect

1. **Compare** what actually happened against the plan, the issue, `CLAUDE.md`,
   and the relevant `.claude/reference/` docs. Where did execution diverge
   from the rules or the process?
2. **Find the root gap**, not the symptom. A wrong result usually means a rule
   the agent never had, a reference doc that was missing or unclear, or a gap in
   a command/gate. Prefer the smallest change that would have prevented it.
3. **Check for a pattern.** If the same class of mistake shows up more than
   once, say so — recurring failures earn a stronger fix than one-offs.

## Propose (do NOT apply yet)

**Classify each proposal first** — this repo is a template that gets cloned:

- **project-specific** — knowledge true only for this codebase (e.g. this
  project's auth flow, a client convention). Stays in the clone. Never goes up.
- **generic** — a workflow improvement any clone benefits from (a better gate, a
  new command, a rule that always applies). Candidate to contribute back up to
  the template.

Map each finding to exactly one target and keep the change minimal:

- **Global rule** (`CLAUDE.md`) — only if it applies no matter what's being
  worked on. Usually a one-liner. Keep this file short; if the rule is
  task-specific, it belongs in a reference doc instead.
- **Reference doc** (`.claude/reference/*.md`) — task-type-specific knowledge
  loaded on demand. New doc, or an edit to an existing one.
- **Command / agent prompt** (`.claude/commands/*.md`, `.claude/agents/*.md`)
  — if the process or a gate should have caught it.

For each proposal, show: the target file, the exact edit (diff or before/after),
and one sentence on which failure it prevents. If a proposal adds a reference
doc, note where its path gets wired in (global rules or the relevant command).

Then **stop and wait for my approval.** I approve per proposal — apply only what
I greenlight, then confirm the changed paths. Don't bundle unrelated changes,
and don't lower the bar on keeping `CLAUDE.md` lean.

## Contribute generic changes back to the template

After I've approved and you've committed a **generic** change that lives in the
shared agent layer (`.claude/agents`, `.claude/commands`, `.claude/reference`,
`scripts/adw`), offer to send it upstream:

```
npm run push-to-template -- <file> [file...]
```

That prepares a branch on the template and prints the push + PR command — it
never pushes on its own. Only pass files I approved as generic; project-specific
changes stay here. If nothing generic was approved, skip this.

What to evolve from: $ARGUMENTS
