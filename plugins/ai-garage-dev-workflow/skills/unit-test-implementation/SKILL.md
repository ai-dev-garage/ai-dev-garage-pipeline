---
name: unit-test-implementation
description: Implement unit tests following isolation-first patterns. Use when the WBS phase type is unit-test. Language-agnostic — stack-specific extensions compose on top.
argument-hint: description of what to test
---

# Unit test implementation

## When to use

- WBS phase is annotated `[type:unit-test]`.
- Caller (implement-task) routes here based on `implementation-routing` config.
- Ad-hoc unit test requests when isolation-first guidance is needed.

## Inputs (provided by caller)

- Description of what to test (production code under test).
- `PROJECT_ROOT` — resolved project root path.
- `test-command` — project's configured test command.
- Constitution rules (if any) — testing principles to follow.
- Scope context — which module(s) or directory the tests belong to.

## Instructions

### 1. Identify scope

Using the caller-provided scope context and constitution rules:

- Identify the production code under test (classes, functions, modules).
- Map the dependency graph of the code under test — which collaborators need substitution.
- Confirm test placement conventions (co-located, mirror directory, separate source set).

### 2. Test design

Structure each test for clarity and maintainability:

- **Arrange-Act-Assert** (or Given-When-Then) — one logical assertion per test method.
- **Naming:** descriptive names that state expected behaviour (`should_<expected>_when_<condition>`). Follow project naming conventions from the constitution if specified.
- **Boundary conditions:** include edge cases, null/empty inputs, off-by-one, and error paths — not just the happy path.
- **Parameterized tests:** when multiple inputs exercise the same logic path, use the project's parameterized test mechanism instead of duplicating test methods.

### 3. Isolation strategy

Unit tests must run without framework context, network, or filesystem access:

- **No heavyweight fixtures:** avoid Spring `ApplicationContext`, database connections, or container startup. If the production code requires them, use lightweight alternatives (plain constructors, in-memory implementations).
- **Mocks and stubs:** substitute external collaborators with test doubles. Prefer constructor injection for testability. Mock only direct collaborators — do not mock the class under test.
- **Determinism:** no shared mutable state between tests, no time-dependence without a controllable clock, no random values without a seed.
- **Speed:** each test should complete in milliseconds. If a test needs I/O, it belongs in integration tests.

### 4. Implement tests

Apply project testing conventions from the constitution:

- Place tests per project layout conventions.
- Use the project's test framework and assertion library.
- Follow existing test patterns visible in the codebase for consistency.
- When a design decision is non-obvious, leave a brief inline comment.

### 5. Self-review

After implementing, verify:

- [ ] Tests actually exercise the code path (not just happy-path coverage).
- [ ] No test-to-test coupling (shared state, execution order dependency).
- [ ] Deterministic — no flaky tests from timing, randomness, or environment.
- [ ] Tests pass: run the configured test command for affected modules.
- [ ] No hardcoded secrets or credentials in test fixtures.
- [ ] Constitution test principles followed (if provided by caller).

## Output

- Test files.
- Self-review results.

## Rules

- Language-agnostic: use the project's actual test framework, not hardcoded patterns.
- Test commands come from caller-provided inputs, not hardcoded.
- Project-specific test patterns belong in the constitution, not in this skill.
- Stack-specific extensions (e.g., `java-unit-test-implementation`) compose on top of this skill when the project stack is detected. See naming convention: `{stack}-unit-test-implementation`.
- Precedence: CONSTITUTION.md > Stack extension > This skill.
