---
name: code-implementation
description: Implement production code or tests following project conventions. Use when asked to implement a feature, logic, class, function, or to cover something with tests. Language-agnostic — stack-specific extensions compose on top.
argument-hint: description of what to implement
---

# Code implementation

## When to use

- Implement a feature, function, class, module, or test.
- Ad-hoc implementation requests.
- The calling agent provides context (scope, constitution rules, build commands).

## Inputs (provided by caller)

- Description of what to implement.
- `PROJECT_ROOT` — resolved project root path.
- `build-command` — project's configured build command.
- `test-command` — project's configured test command.
- Constitution rules (if any) — architecture principles to follow.
- Scope context — which module(s) or directory the change belongs to.

## Instructions

### 1. Identify scope

Using the caller-provided scope context and constitution rules:

- Determine which module(s) or directory the change belongs to.
- Confirm whether this is production code, tests, or both.
- Confirm any cross-module dependency rules that apply.

### 2. Implement production code

Apply project conventions and constitution principles:

- Module placement and dependency direction.
- Naming and structural conventions.
- Forbidden patterns explicitly listed in the constitution.
- When a design decision is non-obvious, leave a brief inline comment.

### 3. Implement tests

Apply project testing conventions:

- Test naming conventions.
- Test structure and organization.
- Mocking and assertion rules.
- Test placement conventions.

### 4. Self-review

After implementing, verify:

- [ ] No unnecessary duplication introduced across files.
- [ ] Build passes: run the configured build command for affected modules.
- [ ] Tests pass: run the configured test command for affected modules.
- [ ] No hardcoded secrets or credentials.
- [ ] No debug/temporary code left in.
- [ ] Constitution principles followed (if provided by caller).

## Output

- Implemented code files.
- Self-review results.

## Rules

- Language-agnostic: use the project's actual tech stack, not hardcoded patterns.
- Build/test commands come from caller-provided inputs, not hardcoded.
- Project-specific patterns belong in the constitution, not in this skill.
- Stack-specific extensions (e.g., `java-code-implementation`) compose on top of this skill when the project stack is detected. See [REFERENCE.md](references/REFERENCE.md).
