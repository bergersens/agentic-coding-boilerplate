---
description: Dump a raw, unstructured idea. Structures it, surfaces the biggest gaps, then rolls straight into grilling.
agent: product
---

I'm dumping a raw idea on you. It may be messy, incomplete, or half-baked —
that's fine. First **triage** it, then take the right path. Don't run the full
loop for a trivial change.

## Step 1 — Triage (always do this first)

Read my dump. Explore the codebase and read `CONTEXT.md` (if present) enough to
judge scope. Classify the idea into one of three tiers and **recommend** it to
me with a one-line justification. I confirm before you proceed — if I disagree,
re-tier.

- **FIX** — a bug or a small fix: trivial, self-contained, no design decisions
  (button color, typo, copy change, a one-liner, an obvious bug). No PRD, no
  grilling.
  → Tell me to run `/fix <description>` (a fresh, cheap implement run that
  skips planning/review but still tests). Don't try to fix it yourself — you're
  the product agent and can't write code.

- **FEATURE** — one clearly-understood feature, low ambiguity, no multi-question
  alignment needed. It may still become one *or a few* vertical slices — a
  feature is not automatically a single issue.
  → Ask me the 1–3 questions that actually matter, then delegate to the
  `issue-planner` subagent to write the issue(s) in `docs/issues/`, and tell me
  to run `/implement`.

- **PRD** — multiple features, OR a single feature that's ambiguous or
  multi-layered enough to need real alignment. One PRD, later sliced into many
  issues. Route here whenever the *what and why* isn't settled — that's what the
  grilling protects against.
  → Go to Step 2 (full loop).

## Step 2 — Full loop (PRD only)

1. **Restate** what you understood so I can catch misunderstandings early.
2. **Structured read.** Delegate to the `requirements` subagent via the Task
   tool with my dump plus your codebase understanding. It returns actors,
   requirements, assumptions, ambiguities, and ranked open questions. Don't
   show me the full analysis — use it to sharpen your grilling.
3. **Reflect the gaps.** Tell me the 3–5 most load-bearing open questions or
   risky assumptions it surfaced.
4. **Grill** following `.opencode/reference/grilling.md`: one question at a
   time, always with your recommended answer, exploring the code instead of
   asking whenever you can. Don't stop until every load-bearing decision is
   resolved. When aligned, tell me to run `/to-prd`.

My idea: $ARGUMENTS
