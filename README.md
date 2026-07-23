# opencode Agentic Engineering Boilerplate

A framework-neutral **opencode template** for building software with a team of
specialized agents instead of one over-loaded assistant. It combines two ideas:

- **Real-engineering discipline** (Matt Pocock): alignment before code, vertical
  slices, deep modules, feedback loops as the speed limit.
- **Tactical agentic engineering** (IndyDevDan): build the system that builds
  the system — orchestrators driving fleets of specialized agents, closed
  feedback loops (gates), and AI Developer Workflows (ADWs) that run AFK.

Bring your own stack: Next.js, Remix, Astro, plain Node, Python, Go — this repo
only ships the coding-workflow scaffolding.

## The core idea: two orchestrators, two teams

Agents don't share a conversation. Each runs in an **isolated context** and
coordinates through **artifacts** — the files in `docs/issues/`, PRDs, plans, and git
commits. This is context isolation by construction (the structural version of
the "context reset" trick) and it's what lets long, autonomous runs stay
coherent.

```
PLANNING (talk to `product`)              BUILDING (talk to `implement`)
  product                                   implement
   ├─ requirements  (analysis)               ├─ planner
   ├─ prd-writer    (PRD)                     ├─ coder
   └─ issue-planner (tickets)                 ├─ tester    ← GATE
                                              └─ reviewer  ← GATE
```

You talk to a **primary orchestrator**; it delegates to its **subagents** via
the Task tool. The build loop is gated: `implement` cannot advance past a red
`tester` or a rejecting `reviewer`, and it loops at most **3 times** before
escalating to you with a report. That's how "bug-free" is enforced by
structure, not hope.

## The workflow

`/idea` triages every idea into one of three tiers, so small work stays small:

```
              ┌─ FIX     → /fix            a bug or a small fix, tested, no loop
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
| `/fix <desc>` | implement | Fast lane for a trivial change — skips planning/review, still tested. |
| `/grill <topic>` | product | Interviews you until the design concept is aligned. |
| `/to-prd` | product | Turns the conversation into a draft `docs/prds/<slug>.md`. |
| `/to-issues` | product | Breaks a PRD into `docs/issues/NN-<slug>.md` vertical slices. |
| `/implement <issue>` | implement | Builds one issue through planner→coder→tester→reviewer. |
| `/diagnose <bug>` | implement | 6-phase structured bug diagnosis (feedback loop first). |
| `/handoff` | build | Compacts the session into a handoff doc for a fresh agent. |

## What's in the box

```
.
├── opencode.json            # config: default agent + permissions
├── AGENTS.md                # slim, always-true house rules (loaded every session)
├── package.json             # empty scaffold — add your stack
├── docs/                    # planning artifacts
│   ├── prds/                # PRD documents (draft → approved lifecycle)
│   ├── issues/              # work tickets + shared agent memory
│   │   └── done/            # completed issues
│   └── plans/               # structured implementation plans (planner output)
├── scripts/
│   ├── adw/run.sh                    # the ADW loop: deterministic code over the implement agent
│   └── misc/update-from-template.sh  # pull shared agent-layer updates from the template
└── .opencode/
    ├── agent/               # the two orchestrators + their subagents
    │   ├── product.md  requirements.md  prd-writer.md  issue-planner.md
    │   └── implement.md  planner.md  coder.md  tester.md  reviewer.md
    ├── command/             # thin slash-command entry points
    └── reference/           # on-demand knowledge (loaded only when relevant)
        ├── tdd.md  code-design.md  diagnosing.md  grilling.md
```

## The three layers of knowledge (modular rules)

Kept deliberately separate so the template stays maintainable:

- **`AGENTS.md`** — only what's true no matter which agent runs. Stays short.
- **Agent prompts** (`.opencode/agent/*.md`) — each agent's own role and rules.
- **`.opencode/reference/*.md`** — deep, task-specific knowledge an agent reads
  *on demand* (an agent's prompt says "when you write tests, read
  `reference/tdd.md`"). This protects the context window: nothing heavy is
  loaded until it's actually needed.

## The ADW loop (AFK mode)

`scripts/adw/run.sh` is deterministic code wrapping a non-deterministic agent —
the "loop over an agent" pattern. Each iteration hands **one** eligible issue to
the `implement` orchestrator in a fresh context; `implement` runs its own gated
build loop. The script stops early when the agent emits
`<promise>NO MORE TASKS</promise>`.

```
./scripts/adw/run.sh        # one iteration — watch it, tune the prompts
./scripts/adw/run.sh 20     # up to 20 iterations, unattended
npm run adw                 # same, via npm
npm run adw -- 20           # pass args after --
```

It only touches `type: afk` issues whose `blocked_by` is fully resolved;
`human-in-the-loop` issues are left for you.

## Setup

1. Install [opencode](https://opencode.ai).
2. Run `opencode`. The `product` orchestrator is the default agent — start with
   `/grill <your idea>`.
3. Restart opencode after editing any agent, command, or config file — config is
   loaded once at startup.

## Keeping projects up to date with the template

GitHub template repos are **not** linked like forks, so template improvements
have to be pulled in on purpose. A project created from this template can sync
its shared agent layer at any time:

```
./scripts/misc/update-from-template.sh
npm run update-from-template            # same, via npm
```

This adds the boilerplate as a git remote called `template`, fetches it, and
**overwrites only the shared paths** — `.opencode/agent`, `.opencode/command`,
`.opencode/reference`, and `scripts/adw`. Everything project-specific
(`AGENTS.md`, `opencode.json`, `docs/issues/`, `docs/prds/`, and any skills, agents, or
commands you added yourself) is left untouched. It never commits — you review
the diff and commit yourself.

- Runs only when you invoke it (manual, never automatic).
- Requires a clean working tree so the template's changes are easy to review.
- Edit the `SHARED_PATHS` list in the script to change what gets synced (e.g.
  add `AGENTS.md` if you want house rules pulled in too).
- Point it at a different template with `./scripts/misc/update-from-template.sh <url>`
  (or `npm run update-from-template -- <url>`).

## Extending it

- **New role?** Add `.opencode/agent/<name>.md` (`mode: subagent`) and reference
  it from the relevant orchestrator's prompt.
- **New reusable knowledge?** Add `.opencode/reference/<topic>.md` and point the
  agents that need it at the file. Don't inline it into `AGENTS.md`.
- **New workflow step?** Add a thin `.opencode/command/<name>.md` that routes to
  the right agent. If you prompt something more than twice, commandify it.
- **System evolution.** When an agent gets something wrong, fix the *system*:
  add a rule to the relevant agent prompt, a `reference/` doc, or a tighter
  gate — so the same mistake can't recur.

## Credit

Engineering discipline and the grill → PRD → vertical-slice-issues → TDD
workflow are based on Matt Pocock's "Real Engineering with AI". The agent
architecture — orchestrators, gated loops, ADWs, and "build the system that
builds the system" — is inspired by IndyDevDan's Tactical Agentic Coding.
