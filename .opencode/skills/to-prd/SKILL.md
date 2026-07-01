---
name: to-prd
description: Use ONLY when invoked via the /to-prd slash command. Turns the current conversation into a PRD (Product Requirements Document) written to ./issues/. Does NOT interview the user - synthesizes what has already been discussed (typically after a grilling session).
---

# To PRD

This skill takes the current conversation context and codebase understanding and produces a PRD. **Do NOT interview the user — just synthesize what you already know.**

## Process

1. **Explore the repo** to understand the current state of the codebase, if you haven't already. Use the project's domain vocabulary throughout the PRD, and respect any existing ADRs in the area you're touching.

2. **Sketch out the seams at which you're going to test the feature.** Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

   Check with the user that these seams match their expectations. If the user disagrees, iterate.

3. **Write the PRD** using the template below, then save it as a markdown file to `./issues/PRD-<slug>.md` where `<slug>` is a short kebab-case identifier of the feature.

## PRD Template

```markdown
---
type: prd
status: ready
created: <ISO date>
---

# <Feature name>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

Example:
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending

This list should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- The seams at which tests are placed
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD. This is critical - it defines what "done" means.

## Further Notes

Any further notes about the feature.
```

## After writing

Confirm the PRD path to the user and suggest running `/to-issues <path>` next to break it into implementable issues.
