# Reference: Diagnosing Bugs

On-demand knowledge for the `/diagnose` command and any agent chasing a hard
bug or performance regression. Skip phases only when explicitly justified.

## Phase 1 — Build a feedback loop (this IS the skill)

Everything else is mechanical. If you have a **tight** pass/fail signal that
goes red on *this* bug, you will find the cause — bisection, hypothesis-testing,
and instrumentation all just consume it. If you don't, no amount of staring at
code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to
give up.**

### Ways to construct one — roughly in this order

1. **Failing test** at whatever seam reaches the bug (unit, integration, e2e).
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright/Puppeteer) asserting on DOM/console/network.
5. **Replay a captured trace** — save a real request/payload/event log, replay it in isolation.
6. **Throwaway harness** — minimal subset of the system exercising the bug with one call.
7. **Property / fuzz loop** — for "sometimes wrong output", run 1000 random inputs.
8. **Bisection harness** — "boot at state X, check, repeat" across commits/datasets/versions.
9. **Differential loop** — same input through old vs new, diff outputs.
10. **HITL bash script** — last resort. If a human must click, script it so it's still repeatable.

### Tighten the loop (treat it as a product)

- Faster? (Cache setup, skip unrelated init, narrow scope.)
- Sharper signal? (Assert the specific symptom, not "didn't crash".)
- More deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

A 30-second flaky loop is barely better than none; a 2-second deterministic one
is a debugging superpower.

### Completion criterion

Phase 1 is done when you can name **one command** you have already run that is:

- [ ] **Red-capable** — drives the actual bug code path, asserts the user's exact symptom
- [ ] **Deterministic** — same verdict every run
- [ ] **Fast** — seconds, not minutes
- [ ] **Agent-runnable** — you can run it unattended

**No red-capable command, no Phase 2.**

## Phase 2 — Reproduce + minimise

Run the loop, watch it go red. Confirm it produces the failure the **user**
described (not a nearby one) and that it's reproducible. Then shrink to the
**smallest scenario that still goes red** — cut inputs, callers, config, data,
steps one at a time. Done when every remaining element is load-bearing.

## Phase 3 — Hypothesise

Generate **3–5 ranked, falsifiable hypotheses** before testing any:

> "If X is the cause, then changing Y will make the bug disappear."

Show the ranked list to the user first — domain knowledge often re-ranks it
instantly.

## Phase 4 — Instrument

Each probe maps to a specific prediction. **Change one variable at a time.**
Prefer debugger/REPL (one breakpoint beats ten logs), then targeted logs at
distinguishing boundaries. Never "log everything and grep". **Tag every debug
log** with a unique prefix like `[DEBUG-a4f2]` so cleanup is one grep.

## Phase 5 — Fix + regression test

Write the regression test **before the fix**, but only if there's a correct
seam for it: turn the minimised repro into a failing test → watch it fail →
apply the fix → watch it pass → re-run the Phase 1 loop against the original
scenario.

## Phase 6 — Cleanup + post-mortem

- [ ] Original repro no longer reproduces
- [ ] Regression test passes
- [ ] All `[DEBUG-...]` instrumentation removed (grep the prefix)
- [ ] The correct hypothesis is stated in the commit / PR message

Then ask: **what would have prevented this bug?** This is the system-evolution
step — the answer is usually a new rule in an agent prompt, a new
`reference/` doc, or a tightened gate. Fix the system that allowed the bug, not
just the bug.
