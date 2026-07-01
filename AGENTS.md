# AGENTS.md

House rules for coding agents working in this repo. Read this before doing anything.

## Philosophy

This project follows the workflow from Matt Pocock's "Real Engineering with AI" methodology. The core ideas:

1. **Alignment before code.** Grill the human relentlessly until you share a design concept with them. Don't code until you're aligned.
2. **Vertical slices, not horizontal.** Every implementation slice cuts through all layers (schema → API → UI → tests) end-to-end. Never "phase 1: all schema, phase 2: all API".
3. **Deep modules.** A lot of behaviour behind a small interface. Callers get leverage, maintainers get locality.
4. **The interface is the test surface.** Tests exercise the public interface. If you have to mock internal collaborators, the module shape is wrong.
5. **Feedback loops are the speed limit.** Red-green-refactor TDD. If you can't build a red-capable feedback loop for a bug, don't hypothesise.

## The Loop

```
IDEA
  │
  ▼
/grill-me           ← align on the design concept
  │
  ▼
/to-prd             ← writes issues/PRD-<slug>.md
  │
  ▼
/to-issues          ← writes issues/NN-<slug>.md (vertical slices, AFK vs HITL)
  │
  ▼
./scripts/ralph/once.sh   ← run one iteration (human-in-the-loop mode)
  │
  ▼
./scripts/ralph/afk.sh N  ← run N iterations unattended (AFK mode)
  │
  ▼
manual QA + code review   ← the human step that can never be automated
```

## Slash commands

| Command | Purpose |
|---|---|
| `/grill-me` | Relentlessly interview the user until a shared design concept exists. |
| `/to-prd` | Synthesise the current conversation into a PRD in `issues/`. |
| `/to-issues` | Break a PRD into independently-grabbable vertical-slice issues. |
| `/improve-arch` | Scan for module-deepening opportunities, present as HTML report. |
| `/diagnose <bug>` | Structured 6-phase debugging loop (feedback loop first, always). |
| `/prototype <question>` | Build a throwaway prototype to answer a design question. |
| `/handoff` | Compact the session into a handoff doc for a fresh agent. |

Skills that get invoked automatically (no slash prefix needed) when the topic matches: `tdd`, `codebase-design`, `diagnosing-bugs`, `prototype`.

## Working in this repo

### Before starting any task

1. Read the issue file (`issues/NN-<slug>.md`) end-to-end, including its `blocked_by` list.
2. Read the parent PRD if referenced.
3. Read `CONTEXT.md` (if it exists) for domain vocabulary.
4. Skim the last 5–10 commits so you know what happened recently.
5. Explore the modules the issue is going to touch before writing code.

### When implementing

- Use the `tdd` skill. Write one failing test, make it pass, repeat. Never write all tests first.
- Prefer editing existing files over creating new ones.
- Do not add libraries, package managers, or runtimes that aren't already in the project.
- Keep modules **deep**: small interfaces, rich implementations. If the interface is almost as complex as the implementation, you have a shallow module — reconsider.
- Test through the **public interface only.** Don't reach into private state to verify.

### Before committing

Run the project's feedback loops:

- Tests: `npm test` / `pnpm test` / `bun test` — whichever the project uses
- Types: `npm run typecheck` — if it exists
- Lint: `npm run lint` — if it exists

Skip any script that doesn't exist. Do not invent scripts.

### Commit messages

Every commit message must include:

1. What key decisions were made
2. Which files changed
3. Any blockers or notes for the next iteration

### After completing a task

- If done: move the issue file from `issues/` to `issues/done/`.
- If partially done: add a note at the bottom of the issue file describing what was completed and what's left.

## Hard rules for AFK mode

When invoked through `./scripts/ralph/afk.sh`, you are running unattended. In this mode:

- **ONLY work on ONE task per iteration.** Do not chain multiple issues.
- **Only pick issues with `type: afk`.** Never touch `type: human-in-the-loop` issues.
- **Only pick issues whose `blocked_by` list is fully resolved** (all blockers already in `issues/done/`).
- **Never modify PRD files.**
- **Never run destructive git commands** (`git push --force`, `git reset --hard`, etc).
- If all AFK issues are done or blocked by HITL issues, output `<promise>NO MORE TASKS</promise>` and exit.

## Context economy

Context windows have a smart zone (~first 100k tokens) and a dumb zone (everything after). Big single-shot sessions push you into the dumb zone quickly.

- Prefer short, focused sessions over long compact-and-continue ones.
- After completing a task, prefer `/handoff` + fresh session over `compact`.
- The Ralph loop naturally resets context between iterations — take advantage of it.

## What NOT to do

- Do not write speculative "we might need this later" code. Prototypes are throwaway; production code answers today's need.
- Do not mock your own modules. Mocks are for system boundaries (payment, email, DB in some cases).
- Do not write horizontal test slices ("all tests first, all impl later"). Vertical slices only.
- Do not skip the grilling phase. Alignment is cheap; wrong-feature implementation is expensive.
- Do not touch anything outside the scope defined by the current issue.
