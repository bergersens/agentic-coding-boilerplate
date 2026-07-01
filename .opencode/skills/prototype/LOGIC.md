# Logic Prototype

A tiny interactive terminal app that lets the user drive a state model by hand. Use this when the question is about **business logic, state transitions, or data shape** — the kind of thing that looks reasonable on paper but only feels wrong once you push it through real cases.

## When this is the right shape

- "I'm not sure if this state machine handles the edge case where X then Y."
- "Does this data model actually let me represent the case where..."
- "I want to feel out what the API should look like before writing it."
- Anything where the user wants to **press buttons and watch state change**.

If the question is "what should this look like" — wrong branch. Use [UI.md](UI.md).

## Process

### 1. State the question

Before writing code, write down what state model and what question you're prototyping. One paragraph, in the prototype's README or a comment at the top of the file.

### 2. Pick the language

Use whatever the host project uses. Match existing conventions for tooling — don't add a new package manager or runtime just for the prototype.

### 3. Isolate the logic in a portable module

Put the actual logic — the bit that's answering the question — behind a small, pure interface that could be lifted out and dropped into the real codebase later. The TUI around it is throwaway; the logic module shouldn't be.

The right shape depends on the question:

- **A pure reducer** — `(state, action) => state`. Good when actions are discrete events and state is a single value.
- **A state machine** — explicit states and transitions.
- **A small set of pure functions** over a plain data type.
- **A class or module with a clear method surface** when the logic genuinely owns ongoing internal state.

Keep it pure: no I/O, no terminal code, no `console.log` for control flow. The TUI imports it and calls into it; nothing flows the other direction.

### 4. Build the smallest TUI that exposes the state

Build it as a **lightweight TUI** — on every tick, clear the screen and re-render the whole frame. Each frame has two parts:

1. **Current state**, pretty-printed and diff-friendly.
2. **Keyboard shortcuts**, listed at the bottom: `[a] add user  [d] delete user  [t] tick clock  [q] quit`.

Behaviour: initialise state → read one keystroke → dispatch to a handler → re-render → loop until quit.

### 5. Make it runnable in one command

Add a script to the project's task runner. The user should run `pnpm run <prototype-name>` or equivalent — never need to remember a path.

### 6. Hand it over and capture the answer

Give the user the run command. When the prototype has answered its question, leave a `NOTES.md` next to the prototype with the answer before deleting it.

## Anti-patterns

- **Don't add tests.** A prototype that needs tests is no longer a prototype.
- **Don't wire it to the real database.** Use an in-memory store.
- **Don't generalise.** No "what if we wanted to support X later."
- **Don't blur the logic and the TUI together.**
- **Don't ship the TUI shell into production.**
