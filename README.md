# opencode Real-Engineering Boilerplate

A framework-neutral starter for new projects that codifies the "Real Engineering with AI" workflow (based on Matt Pocock's [skills repo](https://github.com/mattpocock/skills) and [ai-engineer-workshop-2026-project](https://github.com/mattpocock/ai-engineer-workshop-2026-project)) — but for **opencode** instead of Claude Code.

Bring your own framework: Next.js, Remix, Astro, plain Node, Python — this repo doesn't care. Only `package.json` and the coding-workflow scaffolding are included.

## What's in the box

```
.
├── opencode.json               # opencode config: skills + slash commands
├── AGENTS.md                   # house rules the agent reads on every session
├── package.json                # empty scaffold — add your stack
├── issues/                     # local issue tracker (markdown)
│   └── done/                   # completed issues live here
├── scripts/ralph/              # Ralph AFK loop
│   ├── once.sh                 # one iteration (human-in-the-loop)
│   ├── afk.sh                  # N iterations, unattended
│   └── prompt.md               # prompt fed to opencode each iteration
├── .opencode/
│   └── skills/                 # Matt Pocock skills ported to opencode
│       ├── grill-me/
│       ├── grilling/
│       ├── to-prd/
│       ├── to-issues/
│       ├── tdd/
│       ├── improve-codebase-architecture/
│       ├── diagnosing-bugs/
│       ├── prototype/
│       ├── codebase-design/
│       └── handoff/
└── docs/                       # (empty — for ADRs, CONTEXT.md, etc.)
```

## Setup

1. Use this as a GitHub template (or clone + reset git history).
2. Install [opencode](https://opencode.ai).
3. Add your stack to `package.json`. Framework, test runner, typechecker, whatever you want.
4. Recommended: create `CONTEXT.md` at the repo root as your domain glossary. `AGENTS.md` already references it.
5. `opencode` — start the interactive session.

## The workflow

```
IDEA
  │  /grill-me       align on the design concept (interviews you 20–100 questions)
  ▼
PRD
  │  /to-prd         synthesises the conversation into issues/PRD-<slug>.md
  ▼
ISSUES
  │  /to-issues      breaks PRD into vertical-slice issues (AFK vs HITL)
  ▼
IMPLEMENTATION
  │  scripts/ralph/once.sh    one iteration — watch it, tune the prompt
  │  scripts/ralph/afk.sh 20  N iterations, unattended
  ▼
QA + CODE REVIEW      the step that can never be automated
```

## Slash commands (from `opencode.json`)

| Command | What it does |
|---|---|
| `/grill-me` | Interviews you until the design concept is aligned. |
| `/to-prd` | Turns the current conversation into `issues/PRD-<slug>.md`. |
| `/to-issues` | Breaks a PRD into `issues/NN-<slug>.md` vertical slices. |
| `/improve-arch` | Scans the codebase for deepening opportunities, produces an HTML report. |
| `/diagnose <bug>` | 6-phase structured bug diagnosis. |
| `/prototype <question>` | Builds a throwaway prototype to answer a design question. |
| `/handoff` | Compacts the session into a handoff doc for a fresh agent. |

Other skills (`tdd`, `codebase-design`, `diagnosing-bugs`, `prototype`) are invoked automatically by opencode when the topic matches.

## The Ralph loop

Two scripts, ported from `mattpocock/ai-engineer-workshop-2026-project/ralph`:

- **`scripts/ralph/once.sh`** — single opencode run over the current issues + last 5 commits + `scripts/ralph/prompt.md`. Watch it work. Tune the prompt if it goes wrong.
- **`scripts/ralph/afk.sh <N>`** — runs the same iteration N times. Exits early when opencode outputs `<promise>NO MORE TASKS</promise>` (all AFK issues done or blocked by HITL).

Both scripts read `issues/*.md` fresh every iteration, so newly-added issues get picked up automatically. They only touch `type: afk` issues — anything marked `type: human-in-the-loop` is left for you.

## Issue types

Every issue file has YAML frontmatter with a `type`:

- `afk` — safe for Ralph to grab unattended (schema changes, well-defined service work, refactors with tests).
- `human-in-the-loop` — needs your eyes (UX decisions, design taste, manual QA, third-party integrations).

## Why this exists

Standard vibe-coding hits a wall around 100k tokens and produces slop. This workflow trades some upfront alignment work (grilling, PRD, vertical-slice issues) for:

- **AFK-ready implementation.** Ralph runs while you sleep.
- **Feedback loops that don't lie.** TDD-first, red-green-refactor.
- **Codebases that stay navigable.** Deep modules, not balls of mud.
- **Retained mental model of your own code.** You design interfaces, the agent implements behind them.

Full talk: [Matt Pocock's Real Engineering with AI workshop](https://github.com/mattpocock/ai-engineer-workshop-2026-project).

## Credit

All skills in `.opencode/skills/` are ported from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). Ralph scripts are ported from [mattpocock/ai-engineer-workshop-2026-project](https://github.com/mattpocock/ai-engineer-workshop-2026-project) with `claude` swapped for `opencode run`. All credit to Matt Pocock — this repo is just the opencode-flavoured wiring.
