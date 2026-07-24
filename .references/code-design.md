# Reference: Codebase Design (deep modules)

On-demand knowledge for any agent designing or reviewing module shape.
Load this when deciding an interface, placing a seam, or judging whether a
change keeps the codebase navigable.

Design **deep modules**: a lot of behavior behind a small interface, placed at
a clean seam, testable through that interface. The aim is leverage for callers,
locality for maintainers, and testability for everyone.

## Glossary (use these terms exactly)

Don't substitute "component," "service," "API," or "boundary." Consistent
language is the whole point.

- **Module** — anything with an interface and an implementation. Scale-agnostic:
  a function, class, package, or tier-spanning slice.
- **Interface** — everything a caller must know to use the module correctly:
  the type signature, but also invariants, ordering constraints, error modes,
  required configuration, and performance characteristics.
- **Implementation** — what's inside a module.
- **Depth** — leverage at the interface: how much behavior a caller (or test)
  can exercise per unit of interface they must learn. **Deep** = lots of
  behavior behind a small interface. **Shallow** = interface nearly as complex
  as the implementation.
- **Seam** (Michael Feathers) — a place where you can alter behavior without
  editing in that place; the *location* at which a module's interface lives.
- **Adapter** — a concrete thing that satisfies an interface at a seam.
  Describes *role* (what slot it fills), not substance.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge, and
  verification concentrate in one place.

## Deep vs shallow

```
DEEP  (aim for this)        SHALLOW  (avoid)
┌──────────────────┐        ┌──────────────────────────────┐
│  Small Interface │        │      Large Interface         │
├──────────────────┤        ├──────────────────────────────┤
│                  │        │  Thin Implementation         │
│  Deep Impl       │        └──────────────────────────────┘
│                  │
└──────────────────┘
```

When designing an interface, ask: Can I reduce the number of methods? Can I
simplify the parameters? Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep
  module can be internally composed of small, mockable, swappable parts — they
  just aren't part of the interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes,
  it was a pass-through. If complexity reappears across N callers, it earned
  its keep.
- **The interface is the test surface.** Callers and tests cross the same seam.
  If you want to test *past* the interface, the module is the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.**
  Don't introduce a seam unless something actually varies across it.

## Designing for testability

1. **Accept dependencies, don't create them.**
   ```typescript
   function processOrder(order, paymentGateway) {}   // testable
   function processOrder(order) { new StripeGateway() }  // hard to test
   ```
2. **Return results, don't produce side effects.**
   ```typescript
   function calculateDiscount(cart): Discount {}     // testable
   function applyDiscount(cart): void { cart.total -= d }  // hard to test
   ```
3. **Small surface area.** Fewer methods = fewer tests. Fewer params = simpler
   setup.

## Deepening a cluster: classify its dependencies

The category determines how the deepened module is tested across its seam.

1. **In-process** — pure computation, in-memory state, no I/O. Always
   deepenable; merge and test through the new interface directly. No adapter.
2. **Local-substitutable** — has a local test stand-in (PGLite for Postgres,
   in-memory filesystem). Deepenable if the stand-in exists; run it in the test
   suite.
3. **Remote but owned (Ports & Adapters)** — your own services across a
   network boundary. Define a **port** at the seam; inject the transport as an
   **adapter**. Tests use an in-memory adapter; production uses HTTP/gRPC/queue.
4. **True external (Mock)** — third-party services (Stripe, Twilio). Inject as
   a port; tests provide a mock adapter.

**Testing strategy: replace, don't layer.** Old unit tests on shallow modules
become waste once tests exist at the deepened interface — delete them. Write
new tests at the deepened interface; assert on observable outcomes, not
internal state.

## Design it twice (Ousterhout)

Your first interface idea is unlikely to be the best. Before committing to a
non-trivial interface, sketch 2–3 radically different designs with different
constraints:

- **Minimize the interface** — 1–3 entry points, maximum leverage each.
- **Maximize flexibility** — support many use cases and extension.
- **Optimize for the common caller** — make the default case trivial.

For each: state the interface (types, invariants, error modes), a usage
example, what it hides behind the seam, its dependency strategy, and its
trade-offs. Then compare by depth, locality, and seam placement, and pick (or
hybridize) with an opinionated recommendation.
