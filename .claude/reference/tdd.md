# Reference: Test-Driven Development

On-demand knowledge for any agent writing tests or implementing behavior.
Load this when you are about to write code test-first.

## Core principle

Tests verify **behavior through public interfaces**, not implementation
details. Code can change entirely; good tests shouldn't.

- **Good tests** are integration-style: they exercise real code paths through
  public APIs. They read like a specification ("user can checkout with valid
  cart"). They survive refactors because they don't care about internal
  structure.
- **Bad tests** are coupled to implementation: they mock internal
  collaborators, test private methods, or verify through external means (e.g.
  querying a DB directly instead of using the interface). Warning sign: the
  test breaks when you refactor but behavior hasn't changed.
- **Tautological tests** restate the implementation inside the assertion, so
  they pass by construction and give zero confidence. The expected value must
  come from an independent source of truth — a known-good literal, a worked
  example, the spec.

## The one hard rule: vertical slices, never horizontal

**DO NOT write all tests first, then all implementation.** That is horizontal
slicing and it produces crap tests that verify *imagined* behavior.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

One test → one implementation → repeat.

## Workflow

1. **Plan.** Confirm the public interface, list the behaviors to test
   (behaviors, not implementation steps), prioritize them, spot deep-module
   opportunities.
2. **Tracer bullet.** Write ONE test for ONE behavior → watch it fail (RED) →
   write the minimal code to pass (GREEN).
3. **Incremental loop.** For each remaining behavior: RED → GREEN → repeat.
   One test at a time. Only enough code to pass the current test. Don't
   anticipate future tests.
4. **Refactor** — only while GREEN, never while RED. Extract duplication,
   deepen modules, then re-run tests after each step.

## Per-cycle checklist

- [ ] Test describes behavior, not implementation
- [ ] Test uses the public interface only
- [ ] Test would survive an internal refactor
- [ ] Expected values are independent literals, not recomputed from the code
- [ ] Code is minimal for this test
- [ ] No speculative features added

## Good vs bad tests

```typescript
// GOOD: observable behavior, public API, survives refactor
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});

// BAD: asserts on an internal call
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});

// BAD: bypasses the interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: verifies through the interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});

// BAD (tautological): expected value recomputed the way the code computes it
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: expected value is an independent, known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```

## When to mock

Mock at **system boundaries only**: external APIs (payment, email),
databases (prefer a test DB), time/randomness, sometimes the filesystem.

**Never mock** your own classes/modules, internal collaborators, or anything
you control.

Design boundaries to be mockable:

1. **Inject dependencies**, don't create them internally.

   ```typescript
   // Easy to mock
   function processPayment(order, paymentClient) {
     return paymentClient.charge(order.total);
   }
   // Hard to mock
   function processPayment(order) {
     const client = new StripeClient(process.env.STRIPE_KEY);
     return client.charge(order.total);
   }
   ```

2. **Prefer SDK-style interfaces over generic fetchers** — one function per
   external operation, so each mock returns one specific shape with no
   conditional logic.

## Refactor candidates (only while GREEN)

- Duplication → extract function/class
- Long methods → break into private helpers (keep tests on the public interface)
- Shallow modules → combine or deepen
- Feature envy → move logic to where the data lives
- Primitive obsession → introduce value objects
