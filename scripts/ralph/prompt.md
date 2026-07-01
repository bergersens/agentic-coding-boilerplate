# ISSUES

Local issue files from `issues/` are provided at start of context. Parse them to understand the open issues.

Each issue is a markdown file with YAML frontmatter. The `type` field tells you whether it is an AFK task or a human-in-the-loop task. The `status` field tells you whether it is ready to be picked up. The `blocked_by` list tells you which issues must be closed first.

**You will work on the AFK issues only, not the HITL ones.**

You've also been passed a file containing the last few commits. Review these to understand what work has been done.

If all AFK tasks are complete (or blocked by HITL tasks), output <promise>NO MORE TASKS</promise>.

# TASK SELECTION

Pick the next task. Prioritize tasks in this order:

1. **Critical bugfixes**
2. **Development infrastructure** — tests, types, dev scripts, feedback loops. These are precursors to building features.
3. **Tracer bullets for new features** — small vertical slices through all layers of the system. Build a tiny, end-to-end slice of the feature first, then expand it out.
4. **Polish and quick wins**
5. **Refactors**

Only pick a task whose `blocked_by` list is empty or fully resolved (all blockers moved to `issues/done/`).

# EXPLORATION

Explore the repo. Read `AGENTS.md` and `CONTEXT.md` (if present) for house rules and domain vocabulary.

# IMPLEMENTATION

Use the `tdd` skill to complete the task. Red-green-refactor, vertical slices, real integration tests through public interfaces.

# FEEDBACK LOOPS

Before committing, run the project's feedback loops. Look them up from `package.json` scripts (or the project's task runner). Typical candidates:

- `npm test` / `pnpm test` / `bun test`
- `npm run typecheck` / `pnpm typecheck`
- `npm run lint`

If a script does not exist, do not invent one — note it and move on.

# COMMIT

Make a git commit. The commit message must:

1. Include key decisions made
2. Include files changed
3. Include blockers or notes for the next iteration

# THE ISSUE

If the task is complete, move the issue file to `issues/done/`.

If the task is not complete, add a note at the bottom of the issue file with what was done and what is left.

# FINAL RULES

- ONLY WORK ON A SINGLE TASK PER ITERATION.
- Never touch HITL issues — leave them for the human.
- Never modify PRD files in `issues/`.
- Prefer editing existing files over creating new ones.
