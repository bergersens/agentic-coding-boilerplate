---
name: improve-codebase-architecture
description: Use ONLY when invoked via the /improve-arch slash command. Scans the codebase for module-deepening opportunities (shallow modules that would benefit from being combined into deep ones), presents them as a visual HTML report in the OS temp directory, then grills through whichever one the user picks.
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

Use the vocabulary and principles from the `codebase-design` skill throughout: **module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**, the deletion test, "the interface is the test surface".

## Process

### 1. Explore

Read `AGENTS.md` and `CONTEXT.md` (if present) so proposals use the project's domain vocabulary.

Walk the codebase and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test**: would deleting the module concentrate complexity, or just move it? A "yes, concentrates" is the signal.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to the OS temp directory (`$TMPDIR` on macOS/Linux, fallback `/tmp`). Filename: `architecture-review-<timestamp>.html`. Open it (`open <path>` on macOS, `xdg-open <path>` on Linux) and tell the user the absolute path.

Use **Tailwind via CDN** for layout and **Mermaid via CDN** for graph-shaped diagrams. Mix Mermaid with hand-crafted CSS/SVG for editorial visuals. Each candidate gets a **before/after visualisation**.

For each candidate, render a card with:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram** — side-by-side, illustrating the shallowness and the deepening
- **Recommendation strength** — one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge

End with a **Top recommendation** section: which candidate to tackle first and why.

See [HTML-REPORT.md](HTML-REPORT.md) for scaffold, diagram patterns, and styling.

**Do NOT propose interfaces yet.** After the file is written, ask: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, run the `grilling` skill to walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.
