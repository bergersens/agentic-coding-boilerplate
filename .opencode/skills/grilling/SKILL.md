---
name: grilling
description: Use when the user wants to stress-test a plan, design, or idea before building. Interviews the user relentlessly, one question at a time, until every branch of the decision tree is resolved. Trigger phrases include "grill me", "interview me", "ask me questions", "help me think this through". The reusable loop behind /grill-me.
---

# Grilling

Interview the user relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

## Rules

- Ask questions **one at a time**, waiting for feedback on each question before continuing. Asking multiple questions at once is bewildering.
- For each question, provide **your recommended answer** with a short justification. This lets the user say "yes" and move on quickly.
- If a question can be answered by exploring the codebase, **explore the codebase instead** of asking.
- Cover the whole decision tree: not only the happy path, but edge cases, error handling, out-of-scope decisions, testing strategy, data lifecycle, and rollout.
- Do not stop until every load-bearing decision has been discussed. It is normal for a grilling session to last 20-100 questions.

## Output

The output of a grilling session is not a document — it is a **shared design concept** in the conversation history. Downstream skills (`to-prd`, `to-issues`, `tdd`) will synthesise from it.
