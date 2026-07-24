---
description: Relentlessly interview me until we share a design concept, before any code is written.
---

This is an interactive interview — a single subagent call can't hold a
multi-turn conversation with me, so run it as a loop: call the `product`
subagent (Agent tool) for the next question (with its recommended answer),
relay it to me, feed my answer back into the next `product` call, and repeat
until it signals we're aligned.

Start a grilling session following `.references/grilling.md`.

If I passed a topic or an issue reference as arguments, use it as the seed;
otherwise ask me what I want to build. Explore the codebase first when a
question can be answered from the code instead of from me.

Seed / context: $ARGUMENTS
