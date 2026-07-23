# AGENTS.md

House rules that apply **no matter which agent is running**. Keep this file
short — task-specific knowledge lives in `.opencode/reference/` and is loaded
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
   ├─ requirements  (analysis)               ├─ planner
   ├─ prd-writer    (PRD)                     ├─ coder
   └─ issue-planner (tickets)                 ├─ tester    ← GATE
                                              └─ reviewer  ← GATE
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
              ┌─ FIX     → /fix           (a bug or small fix; implement, tester only)
raw idea ─/idea┼─ FEATURE → issue(s) → /implement
              └─ PRD     → grill → /to-prd → /to-issues → /implement
```

## Commands

| Command | Agent | Purpose |
|---|---|---|
| `/idea <dump>` | product | Kick off from a raw idea: triage its size, then take the right path. |
| `/fix <desc>` | implement | Fast lane for a trivial change: no planning/review, still tested. |
| `/grill <topic>` | product | Interview until a shared design concept exists. |
| `/to-prd` | product | Synthesize the conversation into a draft `docs/prds/<slug>.md`. |
| `/to-issues` | product | Break a PRD into vertical-slice issues. |
| `/implement <issue>` | implement | Build one issue through the gate loop. |
| `/diagnose <bug>` | implement | 6-phase bug diagnosis (feedback loop first). |
| `/handoff` | build | Compact the session into a handoff doc. |

## Model tiering

Each agent picks a model matched to its job (model, `mode`, and `permission`
all live in `opencode.json`; the agent `.md` files hold only the description and
prompt), so we don't pay for top-tier reasoning where mechanical work suffices:

| Tier | Agents | Model |
|---|---|---|
| Reasoning / judgment | `product`, `implement`, `reviewer` | `jambit/claude-opus-4-8` |
| Synthesis / structure | `planner`, `prd-writer`, `issue-planner`, `requirements` | `jambit/gpt-5.6-luna` |
| Code generation | `coder` | `jambit/gpt-5.6-terra` |
| Mechanical / high-volume | `tester` | `jambit/luna:coder` (Qwen3.6 35B A3B) |

The pattern: an expensive **critic** (reviewer = Opus) checks a cheaper
**generator** (coder = Terra), with the gates catching mistakes. The two quality
gates plus the 3-round cap absorb the generator's weaker output; if it can't
reach green+approved in 3 rounds it escalates to the human anyway.

`coder = gpt-5.6-terra` because reliability drives loop cost: a coder that
stalls or times out blocks the whole loop, and Anthropic models (Sonnet) showed
timeout trouble here while the OpenAI stack ran clean. Terra is the reliable
sweet spot — stronger than the internal Qwen `luna:coder` (which was weak/slow),
without Opus prices. If the loop rarely needs a second round, drop `coder` to
`jambit/gpt-5.6-luna` to save; if it can't reach green+approved reliably, bump
to `jambit/claude-opus-4-8` for "bug-free at any cost". Measure round counts
with `ADW_DEBUG=1` before moving it. `tester` is purely mechanical (detect
tooling, run loops, verdict), so `luna:coder` is a safe, cheap fit there.

## Deletion rights

Deletion happens via `bash rm` (there is no separate delete tool). Rights are
deliberate:

- **Can delete files** (`rm <file>`; `rm -rf *` is globally denied): `coder`
  (the legitimate main deleter — removes dead code and stale tests under
  "replace, don't layer"), `implement`, `planner`, `prd-writer`,
  `issue-planner`, `product`, `tester`.
- **Cannot delete** (`rm*` denied, `edit: deny`): `reviewer` and `requirements`
  — they are read-only gates/analysts and must not mutate the tree.

## Reference docs (loaded on demand)

- `.opencode/reference/tdd.md` — test discipline, good vs bad tests, mocking.
- `.opencode/reference/code-design.md` — deep modules, seams, design-it-twice.
- `.opencode/reference/diagnosing.md` — the 6-phase bug loop.
- `.opencode/reference/grilling.md` — how to run a grilling interview.

## Always-true working rules

- Read `CONTEXT.md` (if present) for domain vocabulary before doing anything.
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
- When no eligible AFK issue remains, output `<promise>NO MORE TASKS</promise>`.

## Context economy

Context has a smart zone (~first 100k tokens) and a dumb zone after it. Prefer
short, focused sessions. The subagent boundaries and the ADW loop reset context
structurally — lean on them instead of long compact-and-continue sessions.
After a big task, prefer `/handoff` + a fresh session over `compact`.
