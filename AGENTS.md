# AGENTS.md

House rules that apply **no matter which agent is running**. Keep this file
short — task-specific knowledge lives in `.references/` and is loaded
on demand; role-specific rules live in each agent's own prompt under
`.opencode/agent/`.

## Communication

- **Antworte immer auf Deutsch.**
- Nur das Nötigste: kurz und knapp. Keine Einleitungen, keine Zusammenfassungen,
  kein Smalltalk, kein "Gerne!" oder "Klar!". Direkt zur Sache.
- Keine Wiederholung der Frage, keine Ankündigung was du gleich tust — tu es.
- Erkläre nur, wenn explizit gefragt oder wenn eine Entscheidung eine kurze
  Begründung braucht. Dann ein Satz, nicht drei.

## Philosophy

1. **Alignment before code.** Don't build until you share a design concept with
   the human. A grilling question is cheap; a wrong feature is expensive.
2. **Vertical slices, not horizontal.** Every slice cuts through all layers
   (schema → API → UI → tests) end-to-end. Never "phase 1: all schema, phase 2:
   all API".
3. **Deep modules.** A lot of behavior behind a small interface. Leverage for
   callers, locality for maintainers.
4. **The interface is the test surface.** Test through the public interface. If
   you must mock internal collaborators, the module shape is wrong.
5. **Feedback loops are the speed limit.** Red-green-refactor. No red-capable
   loop for a bug → don't hypothesize.
6. **Fix the system, not just the bug.** When something goes wrong, ask what
   rule, reference doc, or gate would have prevented it — then add it.

## The agent architecture

Two primary orchestrators, each with its own team of subagents. They
communicate through **artifacts** (`docs/prds/`, `docs/issues/`, plans, git commits), not
shared memory — every subagent starts with a fresh, isolated context.

```
PLANNING (talk to `product`)              BUILDING (talk to `implement`)
  product                                   implement
   ├─ requirements  (analysis)               ├─ coder
   ├─ prd-writer    (PRD)                    └─ verifier  ← THE GATE
   └─ issue-planner (tickets)

  planner — human-invoked via /plan only; neither orchestrator calls it
```

```
raw idea ─/idea→ concept ─/to-prd→ PRD ─/to-issues→ issues ─/implement→ tested code
         (or /grill)                                          scripts/adw/run.sh N (AFK)
                                                                      │
                                                                      ▼
                                                            manual QA + code review
```

`/idea` triages first, so trivial work skips the loop:

```
              ┌─ FIX     → /fix           (a bug or small fix; no coder, gate still runs)
raw idea ─/idea┼─ FEATURE → issue(s) → /implement
              └─ PRD     → grill → /to-prd → /to-issues → /implement
```

## Why the build loop is two steps

Every subagent starts cold and pays to rebuild context. That rebuild — not the
thinking — is what makes a feature slow, so the loop is kept at **two cold starts
per issue**: `coder` → `verifier`.

Three deliberate consequences, and the reasons they must not be undone:

- **The issue is the plan.** `issue-planner` already explores the codebase, so it
  records the `## Seams` and `## Behaviors` it found. Re-deriving that in a
  separate planning step means paying for the same exploration three times (once
  in the planner, again in the coder, which starts cold regardless). The
  build loop therefore has **no planning step at all** — the `planner` agent is
  human-invoked via `/plan` when you want the approach reviewable before code,
  and the orchestrator never calls it.
- **One gate, not two.** A test gate and a review gate re-read the same diff and
  both judge test quality. Merging them into `verifier` removes a cold start, and
  it delivers `[red]`, `[coverage]` and `[design]` findings in a *single* verdict
  — so the coder fixes everything in one round instead of failing tests first and
  discovering the design problem a full cycle later. Independence is preserved
  where it matters: `verifier` ≠ `coder`, and the verifier cannot edit.
- **The suite runs once per round.** The `coder` runs only the narrow loop
  (touched tests + typecheck) as its inner loop; the `verifier` runs the full
  suite. Both running everything doubled the slowest step for no added signal.

Because the merged gate reports every defect class at once, the round cap is
**2** — a third round is thrashing, not progress.

Feedback-loop commands are detected **once per project** into `docs/loops.md` and
passed down in prompts. Re-detecting the test runner on every invocation was pure
overhead: it's a constant.

## Commands

| Command | Agent | Purpose |
|---|---|---|
| `/idea <dump>` | product | Kick off from a raw idea: triage its size, then take the right path. |
| `/fix <desc>` | implement | Fast lane for a trivial change: no coder, gate still runs. |
| `/grill <topic>` | product | Interview until a shared design concept exists. |
| `/to-prd` | product | Synthesize the conversation into a draft `docs/prds/<slug>.md`. |
| `/to-issues` | product | Break a PRD into vertical-slice issues. |
| `/implement <issue>` | implement | Build one issue through the gate loop. |
| `/plan <issue>` | implement | Optional: a reviewable plan before code. Not part of the loop. |
| `/diagnose <bug>` | implement | 6-phase bug diagnosis (feedback loop first). |
| `/handoff` | build | Compact the session into a handoff doc. |

## Model tiering

Each agent picks a model matched to its job (model, `mode`, and `permission`
all live in `opencode.json`; the agent `.md` files hold only the description and
prompt), so we don't pay for top-tier reasoning where mechanical work suffices:

| Tier | Agents | Role |
|---|---|---|
| Reasoning / judgment | `product`, `implement`, `verifier` | design decisions, the verdict |
| Synthesis / structure | `planner`, `prd-writer`, `issue-planner`, `requirements` | turning concepts into structure |
| Code generation | `coder` | writing production code + its tests |

The pattern: an expensive **critic** (verifier) checks a cheaper **generator**
(coder). The gate plus the 2-round cap absorb the generator's weaker output; if
it can't reach PASS in 2 rounds it escalates to the human anyway.

The verifier sits in the top tier deliberately. It now does the mechanical work
(run the loops) *and* the judgment (design, scope, test quality) in one pass, and
judgment is the part that fails on a cheap model — a weak gate spends its budget
producing false verdicts, which cost a full extra round each. One top-tier call
replaces the old cheap-tester + expensive-reviewer pair and is net cheaper,
because it removes a cold start and the rounds that the weak tester's misjudgment
caused.

Pick concrete model IDs per tier to match whatever providers you have configured
in `opencode.json` — the tiers are stable, the model IDs are not. Reliability
drives loop cost: a coder that stalls or times out blocks the whole loop, so
favor a reliable mid-tier coder over the strongest available one. If the loop
rarely needs a second round, drop the coder tier down to save; if it can't reach
PASS reliably, bump the coder tier up for "bug-free at any cost". Measure round
counts with `ADW_DEBUG=1` before moving either.

## Deletion rights

Deletion happens via `bash rm` (there is no separate delete tool). Rights are
deliberate:

- **Can delete files** (`rm <file>`; `rm -rf *` is denied for every agent):
  `coder` (the legitimate main deleter — removes dead code and stale tests under
  "replace, don't layer"), `implement`, `planner`, `prd-writer`, `issue-planner`,
  `product`.
- **Cannot delete** (`rm*` denied, `edit: deny`): `verifier` and `requirements` —
  they are read-only gates/analysts and must not mutate the tree. The verifier's
  read-only status is load-bearing: a gate that can patch what it judges is not a
  gate. Missing coverage is a `[coverage]` finding, never a quick fix it applies
  itself.

## Reference docs (loaded on demand)

- `.references/tdd.md` — test discipline, good vs bad tests, mocking.
- `.references/code-design.md` — deep modules, seams, design-it-twice.
- `.references/diagnosing.md` — the 6-phase bug loop.
- `.references/grilling.md` — how to run a grilling interview.

## Project artifacts

- `docs/prds/` — PRDs (`draft` → `approved` → `done/`).
- `docs/issues/` — tickets, the build plan (`done/` when shipped).
- `docs/plans/` — escalation plans only; most issues never get one.
- `docs/loops.md` — this project's real feedback-loop commands, detected once.
  Delete it to force re-detection after the tooling changes.

## Always-true working rules

- Read `CONTEXT.md` (if present) for domain vocabulary before doing anything.
- Take the feedback-loop commands from `docs/loops.md` instead of re-deriving
  them. Never invent a script that doesn't exist.
- Prefer editing existing files over creating new ones.
- Do not add libraries, package managers, or runtimes not already in the
  project.
- Test through the **public interface only.** Mock only at true system
  boundaries — never your own modules.
- Before committing, run the project's feedback loops (tests, typecheck, lint —
  whichever exist). Never invent a script that doesn't exist.
- Commit messages must state: key decisions, files changed, and any
  blockers/notes for next time.
- Don't write speculative "might need it later" code.
- Stay inside the scope of the current issue.

## Hard rules for AFK mode (`scripts/adw/run.sh`)

- ONE issue per iteration. Don't chain issues.
- Only `type: afk` issues whose `blocked_by` is fully resolved. Never touch
  `type: human-in-the-loop`.
- Never modify PRD files. Never run destructive git commands.
- Close a shipped issue with `./scripts/adw/close-issue.sh <issue>`, not by hand
  — a mis-moved artifact silently breaks `blocked_by` for every later issue.
- When no eligible AFK issue remains, output `<promise>NO MORE TASKS</promise>`.

## Context economy

Context has a smart zone (~first 100k tokens) and a dumb zone after it. Prefer
short, focused sessions. The subagent boundaries and the ADW loop reset context
structurally — lean on them instead of long compact-and-continue sessions.
After a big task, prefer `/handoff` + a fresh session over `compact`.
