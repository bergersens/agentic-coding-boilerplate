# Refactor Candidates

After each TDD cycle (all tests green), look for:

- **Duplication** → Extract function/class
- **Long methods** → Break into private helpers (keep tests on public interface)
- **Shallow modules** → Combine or deepen
- **Feature envy** → Move logic to where data lives
- **Primitive obsession** → Introduce value objects
- **Existing code** the new code reveals as problematic

Never refactor while RED. Get to GREEN first, then refactor with the safety net of passing tests.
