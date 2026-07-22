# Reference: Grilling

How to interview a human until you share a design concept. Used by the
`product` orchestrator and the `/grill` command.

Interview the user relentlessly about every aspect of the plan until you reach
a shared understanding. Walk down each branch of the design tree, resolving
dependencies between decisions one by one.

## Rules

- Ask questions **one at a time**, waiting for feedback on each before
  continuing. Asking multiple questions at once is bewildering.
- For each question, provide **your recommended answer** with a short
  justification. This lets the user say "yes" and move on quickly.
- If a question can be answered by exploring the codebase, **explore the
  codebase instead** of asking.
- Cover the whole decision tree: not only the happy path, but edge cases, error
  handling, out-of-scope decisions, testing strategy, data lifecycle, and
  rollout.
- Do not stop until every load-bearing decision has been discussed. It is
  normal for a grilling session to last 20–100 questions.
- Prioritize technical accuracy over agreement. If the user's idea has a flaw,
  say so and explain why — respectful correction beats false consensus.

## Output

The output of a grilling session is **not a document** — it is a shared design
concept in the conversation history. Downstream steps (`/to-prd`, `/to-issues`,
implementation) synthesize from it.
