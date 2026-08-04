---
description: Synthesize the current conversation into a draft PRD in docs/prds/<slug>.md.
---

Delegate to the `prd-writer` subagent (Agent tool). Give it the full design
concept from this conversation plus any extra context below. Do NOT interview me
— synthesize what we've already discussed. It writes the PRD to
`docs/prds/<slug>.md` with `status: draft`. When it returns, confirm the path and
remind me it's a draft: I review it, and once I approve it the `product` agent
flips it to `status: approved` — only then can `/to-issues` slice it.

Extra context: $ARGUMENTS
