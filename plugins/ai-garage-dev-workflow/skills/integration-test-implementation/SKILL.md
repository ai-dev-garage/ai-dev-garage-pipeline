---
name: integration-test-implementation
description: Implement integration tests with real dependencies and end-to-end flows. Use when the WBS phase type is integration-test. Language-agnostic — stack-specific extensions compose on top.
argument-hint: description of what to test end-to-end
---

# Integration test implementation

## When to use

- WBS phase is annotated `[type:integration-test]`.
- Caller (implement-task) routes here based on `implementation-routing` config.
- Ad-hoc integration or functional test requests involving real dependencies.

## Inputs (provided by caller)

- Description of what to test (components, flows, external dependencies).
- `PROJECT_ROOT` — resolved project root path.
- `build-command` — project's configured build command.
- `test-command` — project's configured test command.
- Constitution rules (if any) — testing principles to follow.
- Scope context — which module(s) or directory the tests belong to.

## Instructions

### 1. Identify scope

Using the caller-provided scope context and constitution rules:

- Identify the components that participate in the flow under test.
- Map external dependencies: databases, message queues, HTTP services, file systems.
- Determine the flow boundary — where the test starts and where it verifies outcomes.
- Confirm integration test placement conventions (separate source set, dedicated directory, test profile).

### 2. Fixture strategy

Design the test infrastructure before writing assertions:

- **Setup/teardown:** choose per-test or per-class lifecycle. Prefer per-test isolation unless startup cost is prohibitive.
- **Test data:** use builders, migration-based seeding, or fixture files — not production data snapshots. Ensure data is self-contained within each test.
- **Container management:** if the project uses testcontainers, docker-compose, or embedded servers, follow existing patterns. Do not introduce a new container strategy without checking what the project already uses.
- **Cleanup guarantees:** ensure teardown runs even on test failure (try-finally, framework lifecycle hooks, or transactional rollback).

### 3. Test design

Structure tests for reliability and debuggability:

- **End-to-end flow:** exercise the real path from entry point to side effect verification.
- **Real dependencies:** use actual database connections, real HTTP calls (to test containers or stubs), real serialization — not mocks of infrastructure.
- **Deterministic ordering:** tests must not depend on execution order. Isolate state between tests.
- **Timeouts:** configure reasonable timeouts for I/O operations to prevent hanging tests.
- **Error scenarios:** test failure paths with real error conditions (connection refused, invalid data, timeout) — not just the happy path.

### 4. Implement tests

Apply project conventions from the constitution:

- Place tests per project layout conventions for integration tests.
- Use the project's test framework, assertion library, and integration test tooling.
- Configure test profiles or properties as needed (database URLs, service endpoints).
- Follow existing integration test patterns visible in the codebase for consistency.
- When a design decision is non-obvious, leave a brief inline comment.

### 5. Self-review

After implementing, verify:

- [ ] Tests are deterministic and repeatable across environments.
- [ ] No resource leaks (unclosed connections, orphaned containers, temp files).
- [ ] Cleanup runs even on failure (transactional rollback, try-finally, lifecycle hooks).
- [ ] Tests pass: run the configured test command for affected modules.
- [ ] No hardcoded secrets, URLs, or credentials — use test configuration.
- [ ] Side effects are verified (database state, published events, API responses).
- [ ] Constitution test principles followed (if provided by caller).

## Output

- Test files.
- Fixture or configuration files (if needed).
- Self-review results.

## Rules

- Language-agnostic: use the project's actual test framework, not hardcoded patterns.
- Build/test commands come from caller-provided inputs, not hardcoded.
- Project-specific test patterns belong in the constitution, not in this skill.
- Stack-specific extensions (e.g., `java-integration-test-implementation`) compose on top of this skill when the project stack is detected. See naming convention: `{stack}-integration-test-implementation`.
- Precedence: CONSTITUTION.md > Stack extension > This skill.
