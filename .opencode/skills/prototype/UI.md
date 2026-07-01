# UI Prototype

Generate **several radically different UI variations** on a single route, switchable from a floating bottom bar. The user flips between variants in the browser, picks one (or steals bits from each), then throws the rest away.

If the question is about logic/state rather than what something looks like — wrong branch. Use [LOGIC.md](LOGIC.md).

## When this is the right shape

- "What should this page look like?"
- "I want to see a few options for this dashboard before committing."
- "Try a different layout for the settings screen."

## Two sub-shapes — strongly prefer sub-shape A

A UI prototype is much easier to judge when it's **butting up against the rest of the app**.

### Sub-shape A — adjustment to an existing page (preferred)

The route already exists. Variants are rendered **on the same route**, gated by a `?variant=` URL search param. The existing data fetching, params, and auth all stay — only the rendering swaps.

### Sub-shape B — a new page (last resort)

Only use this when the thing being prototyped genuinely has no existing page to live inside. Create a throwaway route following whatever routing convention the project already uses.

## Process

### 1. State the question and pick N

Default to **3 variants**. Cap at 5.

### 2. Generate radically different variants

Variants must be **structurally different** — different layout, different information hierarchy, different primary affordance, not just different colours.

### 3. Wire them together

```tsx
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

### 4. Build the floating switcher

A small fixed-position bar at the bottom-centre with:

- **Left arrow** — cycles to the previous variant (wraps).
- **Variant label** — e.g. `B — Sidebar layout`.
- **Right arrow** — cycles forward (wraps).

Behaviour: clicking updates the URL search param. Keyboard: `←` and `→` cycle (unless a text input is focused). Hidden in production builds.

### 5. Hand it over

Surface the URL and the `?variant=` keys.

### 6. Capture the answer and clean up

Once a variant wins, write down which one and why. Then delete the losing variants and the switcher; fold the winner into the page.

## Anti-patterns

- **Variants that differ only in colour or copy.**
- **Sharing too much code between variants.** Each variant should be free to throw out the layout.
- **Wiring variants to real mutations.** Read-only prototypes are fine.
- **Promoting the prototype directly to production.** Rewrite properly when folding in.
