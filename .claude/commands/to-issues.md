---
description: Break an approved PRD into vertical-slice issues in docs/issues/NN-<slug>.md.
---

Delegate to the `issue-planner` subagent (Agent tool). Pass it the PRD path
(given below, or the most recent `docs/prds/*.md` if omitted). The PRD must be
`status: approved` — if it's still `draft`, don't slice it; tell me to approve it
first. Bring the proposed breakdown back to me and iterate on granularity,
dependencies, and afk-vs-human-in-the-loop classification before the issues are
finalized.

PRD path / context: $ARGUMENTS
