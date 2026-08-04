# Agentic Engineering Boilerplate (opencode + Claude Code)

A framework-neutral template for building software with a team of specialized
agents instead of one over-loaded assistant. It combines two ideas:

- **Real-engineering discipline** (Matt Pocock): alignment before code, vertical
  slices, deep modules, feedback loops as the speed limit.
- **Tactical agentic engineering** (IndyDevDan): build the system that builds
  the system — orchestrators driving fleets of specialized agents, closed
  feedback loops (gates), and AI Developer Workflows (ADWs) that run AFK.

The agent layer ships in **two parallel shapes** so you can run it on either
engine — or both, side by side in the same repo:

- **opencode** — `.opencode/agent/`, `.opencode/command/`, `.references/`,
  house rules in `AGENTS.md`, config in `opencode.json`.
- **Claude Code** — `.claude/agents/`, `.claude/commands/`, `.references/`,
  house rules in `CLAUDE.md`.

The two shapes are kept in lockstep (same orchestrators, same subagents, same
commands, same reference docs), so the workflow is identical regardless of
which engine you point at the repo. Bring your own stack: Next.js, Remix,
Astro, plain Node, Python, Go — this repo only ships the coding-workflow
scaffolding.

## The core idea: two orchestrators, two teams

Agents don't share a conversation. Each runs in an **isolated context** and
coordinates through **artifacts** — the files in `docs/issues/`, PRDs, plans, and git
commits. This is context isolation by construction (the structural version of
the "context reset" trick) and it's what lets long, autonomous runs stay
coherent.

```
PLANNING (talk to `product`)              BUILDING (talk to `implement`)
  product                                   implement
   ├─ requirements  (analysis)               ├─ coder
   ├─ prd-writer    (PRD)                    └─ verifier  ← THE GATE
   └─ issue-planner (tickets)

  planner — human-invoked via /plan only; neither orchestrator calls it
```

You talk to a **primary orchestrator**; it delegates to its **subagents** via
the Task tool. The build loop is gated: `implement` cannot commit past a failing
`verifier`, and it loops at most **2 times** before escalating to you with a
report. That's how "bug-free" is enforced by structure, not hope.

### The build loop is deliberately short

Every subagent starts cold and pays to rebuild context. That rebuild — not the
thinking — is what makes a feature slow, so the loop is **two cold starts per
issue**:

```
coder  →  verifier  ─── PASS ──▶ commit + close
   ▲          │
   └─ FAIL ───┘   all findings at once — [red] + [coverage] + [design]
```

- **The issue is the plan.** `issue-planner` explores the codebase anyway, so it
  writes down the `## Seams` and `## Behaviors` it finds. A separate planning step
  would pay for that same exploration a second and third time (the coder starts
  cold regardless). The loop has **no planning step at all**; the `planner` agent
  is human-invoked via `/plan` when you want the approach reviewable before code.
- **One gate, not two.** A test gate and a review gate re-read the same diff and
  both judge test quality. Merged, they cost one cold start and return every
  defect class in a single verdict — so the coder fixes tests *and* design in one
  round instead of discovering the design problem a full cycle later.
- **The suite runs once per round.** The coder's inner loop is narrow (touched
  tests + typecheck); the verifier runs the full suite.

The result, per issue: 2 cold starts on the happy path instead of 4, and 5 in the
worst case instead of 10.

## The workflow

`/idea` triages every idea into one of three tiers, so small work stays small:

```
              ┌─ FIX     → /fix            a bug or a small fix; no coder, gate still runs
/idea <dump> ─┼─ FEATURE → issue(s)      → /implement
              └─ PRD     → grill → PRD → issues → /implement
```

The full PRD path:

```
IDEA
  │  /idea         dump a raw idea → product triages, then grills you
  │  /grill        (or start here if the idea is already sharp)
  ▼
  │                product interviews you (20–100 questions) → shared design concept
  ▼
PRD
  │  /to-prd       prd-writer synthesizes the conversation → docs/prds/<slug>.md (draft)
  │  approve       you sign off the draft → status: approved
  ▼
ISSUES
  │  /to-issues    issue-planner breaks the PRD into vertical slices (afk | human-in-the-loop)
  ▼
IMPLEMENTATION
  │  /implement <issue>        one issue, interactive, through the gate loop
  │  scripts/adw/run.sh 20     N issues, unattended (AFK)
  ▼
QA + CODE REVIEW    the step that can never be automated
```

Big picture → detail. You decide how far down to break things before handing
off; every step gives the downstream agent unambiguous instructions.

## Commands

| Command | Agent | What it does |
|---|---|---|
| `/idea <dump>` | product | Dump a raw idea; it's triaged into FIX / FEATURE / PRD and routed. |
| `/fix <desc>` | implement | Fast lane for a trivial change — no coder, the gate still runs. |
| `/grill <topic>` | product | Interviews you until the design concept is aligned. |
| `/to-prd` | product | Turns the conversation into a draft `docs/prds/<slug>.md`. |
| `/to-issues` | product | Breaks a PRD into `docs/issues/NN-<slug>.md` vertical slices. |
| `/implement <issue>` | implement | Builds one issue through coder→verifier. |
| `/plan <issue>` | implement | Optional: a reviewable plan before code. Not part of the loop. |
| `/diagnose <bug>` | implement | 6-phase structured bug diagnosis (feedback loop first). |
| `/handoff` | build | Compacts the session into a handoff doc for a fresh agent. |

## What's in the box

```
.
├── opencode.json           # opencode config: default agent + permissions
├── AGENTS.md               # slim, always-true house rules (loaded every opencode session)
├── CLAUDE.md               # same house rules, for Claude Code sessions
├── package.json            # empty scaffold — add your stack
├── docs/                   # planning artifacts
│   ├── prds/               # PRD documents (draft → approved lifecycle)
│   ├── issues/             # work tickets — seams + behaviors included, so they ARE the plan
│   │   └── done/           # completed issues
│   ├── plans/              # escalation plans only (most issues never get one)
│   └── loops.md            # this project's feedback-loop commands, detected once
├── scripts/
│   ├── adw/
│   │   ├── run.sh                       # the ADW loop: deterministic code over the implement agent
│   │   ├── close-issue.sh               # deterministic issue/plan/PRD retirement
│   │   ├── format-stream-claude.js      # live, colorized rendering of Claude stream-json events
│   │   └── format-stream-opencode.js    # live, colorized rendering of opencode --format json events
│   └── misc/
│       ├── update-from-template.sh      # pull shared agent-layer updates from the template
│       └── push-to-template.sh          # contribute generic improvements back up to the template
├── .opencode/
│   ├── agent/              # the two orchestrators + their subagents (opencode shape)
│   │   ├── product.md  requirements.md  prd-writer.md  issue-planner.md
│   │   ├── implement.md  coder.md  verifier.md
│   │   └── planner.md      # human-invoked via /plan, outside the loop
│   └── command/            # thin slash-command entry points (opencode shape)
├── .claude/                # Claude Code shape — parallel to .opencode/
│   ├── agents/             # same orchestrators + subagents, Claude Code frontmatter
│   ├── commands/           # same slash commands
│   └── settings.json       # Claude Code permissions (allow/deny for AFK runs)
└── .references/             # shared on-demand knowledge (loaded only when relevant)
    ├── tdd.md  code-design.md  diagnosing.md  grilling.md
```

The two shapes carry the same content; only the path prefix, frontmatter, and
house-rules filename differ (`.opencode/` → `AGENTS.md`, `.claude/` → `CLAUDE.md`).
Pick one engine and ignore the other half, or keep both in sync to switch
engines per project.

## The three layers of knowledge (modular rules)

Kept deliberately separate so the template stays maintainable:

- **`AGENTS.md` / `CLAUDE.md`** — only what's true no matter which agent runs.
  Stays short. One per engine.
- **Agent prompts** (`.opencode/agent/*.md` or `.claude/agents/*.md`) — each
  agent's own role and rules.
- **`.references/*.md`** — deep, task-specific knowledge an agent reads *on demand*
  (an agent's prompt says "when you write tests, read `.references/tdd.md`"). This
  protects the context window: nothing heavy is loaded until it's actually
  needed. Shared by both engines — one copy, referenced from both agent shapes.

## The ADW loop (AFK mode)

`scripts/adw/run.sh` is deterministic code wrapping a non-deterministic agent —
the "loop over an agent" pattern. Each iteration hands **one** eligible issue to
the `implement` orchestrator in a fresh context; `implement` runs its own gated
build loop. The script stops early when the agent emits
`<promise>NO MORE TASKS</promise>`.

It auto-detects which engine to drive: `claude` if the `claude` CLI is on PATH,
otherwise `opencode`. Pin it explicitly with `ADW_ENGINE=claude` or
`ADW_ENGINE=opencode`. Either way, the engine's raw JSON event stream is piped
through a Node formatter (`format-stream-claude.js` / `format-stream-opencode.js`)
so you can watch every orchestrator step — tool calls, subagent spawns, gated
results — live and color-coded in the terminal.

```
./scripts/adw/run.sh        # one iteration — watch it, tune the prompts
./scripts/adw/run.sh 20     # up to 20 iterations, unattended
npm run adw                 # same, via npm
npm run adw -- 20           # pass args after --

ADW_ENGINE=claude   ./scripts/adw/run.sh 20    # force the Claude Code engine
ADW_ENGINE=opencode ./scripts/adw/run.sh 20    # force the opencode engine
ADW_DEBUG=1         ./scripts/adw/run.sh 20    # extra debug logging
```

It only touches `type: afk` issues whose `blocked_by` is fully resolved;
`human-in-the-loop` issues are left for you.

## Setup

### With opencode

1. Install [opencode](https://opencode.ai).
2. Run `opencode` in the repo. The `product` orchestrator is the default agent —
   start with `/grill <your idea>`.
3. Restart opencode after editing any agent, command, or `opencode.json` —
   config is loaded once at startup.

### With Claude Code

1. Install [Claude Code](https://claude.com/claude-code).
2. Run `claude` in the repo. The `.claude/agents/*.md` files register the same
   orchestrators and subagents; house rules come from `CLAUDE.md`.
3. Restart Claude Code after editing agents, commands, or `CLAUDE.md`.

Both engines read the same `docs/` artifacts and `scripts/adw/` loop, so you
can switch engines mid-project without losing state.

## Keeping projects up to date with the template

GitHub template repos are **not** linked like forks, so template improvements
have to be pulled in on purpose. A project created from this template can sync
its shared agent layer at any time:

```
./scripts/misc/update-from-template.sh
npm run update-from-template            # same, via npm
```

This adds the boilerplate as a git remote called `template`, fetches it, and
**overwrites only the shared paths** — both engine shapes (`.opencode/agent`,
`.opencode/command`, `.claude/agents`, `.claude/commands`,
`.claude/settings.json`), the shared `.references/`, `scripts/adw`,
`scripts/misc`, and the shared root files (`AGENTS.md`, `CLAUDE.md`,
`opencode.json`, `README.md`). Everything project-specific (`docs/issues/`,
`docs/prds/`, and any skills, agents, or commands you added yourself) is left
untouched. It never commits — you review the diff and commit yourself.

- Runs only when you invoke it (manual, never automatic).
- Requires a clean working tree so the template's changes are easy to review.
- Edit the `SHARED_PATHS` list in the script to change what gets synced (e.g.
  drop `opencode.json` if you keep that project-local in a given client).
- Point it at a different template with `./scripts/misc/update-from-template.sh <url>`
  (or `npm run update-from-template -- <url>`).

**Retired files.** `git checkout` only ever writes, so it cannot delete a file the
template removed — when two agents are merged into one, the old prompts linger
locally as orphans that are still registered with the engine but never called.
The sync lists them at the end; delete them with:

```
PRUNE=1 ./scripts/misc/update-from-template.sh
```

Pruning is opt-in because the script can't tell a retired template file from an
agent you wrote yourself — read the list before you run it.

### Contributing improvements back up

The mirror image: push generic agent-layer improvements from a project back to
the template. Name the files you want to contribute:

```
./scripts/misc/push-to-template.sh .claude/agents/implement.md .opencode/agent/implement.md
./scripts/misc/push-to-template.sh AGENTS.md CLAUDE.md README.md
npm run push-to-template -- scripts/adw/run.sh
```

It builds the contribution on a fresh branch off the template's `main` (in a
temporary `git worktree`, so your working tree is never disturbed), commits
there, and prints the push + PR command. It **never pushes** — you review and
land it yourself.

- Only files inside the shared agent layer (or the opt-in root files) may go up
  — `docs/` and other project-specific paths are refused, so client context
  can't leak into the template.
- Each named file must be committed in the project first (so you contribute a
  reviewed state, not a working-tree accident).

## Extending it

- **New role?** Add `<engine>/agent/<name>.md` (opencode) or
  `<engine>/agents/<name>.md` (Claude Code) with `mode: subagent`, in both
  shapes, and reference it from the relevant orchestrator's prompt.
- **New reusable knowledge?** Add `.references/<topic>.md` (one copy, shared by
  both engines) and point the agents that need it at the file. Don't inline it
  into the house rules.
- **New workflow step?** Add a thin command in both shapes that routes to the
  right agent. If you prompt something more than twice, commandify it.
- **System evolution.** When an agent gets something wrong, fix the *system*:
  add a rule to the relevant agent prompt, a `.references/` doc, or a tighter
  gate — so the same mistake can't recur.

## Credit

Engineering discipline and the grill → PRD → vertical-slice-issues → TDD
workflow are based on Matt Pocock's "Real Engineering with AI". The agent
architecture — orchestrators, gated loops, ADWs, and "build the system that
builds the system" — is inspired by IndyDevDan's Tactical Agentic Coding.