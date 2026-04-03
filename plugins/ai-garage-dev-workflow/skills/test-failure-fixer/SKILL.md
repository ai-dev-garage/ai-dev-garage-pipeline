---
name: test-failure-fixer
description: Run tests, diagnose failures, and attempt automated fixes with up to 5 retries. Produces a structured failure report when automated fixing is exhausted. Language-agnostic — uses project-configured test commands.
argument-hint: module or test scope (optional)
---

# Test failure fixer

## When to use

- A build or test phase fails during implementation.
- User asks to fix failing tests.
- Called by an agent when tests fail during a workflow.

## Instructions

### 1. Determine test scope

Resolve what to run based on context:

- **Caller provided specific modules/tests** — use those.
- **WBS is active** — use the modules affected by the current phase.
- **Neither** — ask the user which modules or test scope to run.

Use the caller-provided `test-command` and `build-command`.

### 2. Run tests (attempt 1)

Run the configured test command. Capture the full output.

If all tests pass, report success and return.

If tests fail, parse the output and extract:
- Failing test file(s) and method(s)/case(s).
- Error type (assertion failure, exception, timeout, compilation error).
- Relevant error message or stack trace.

### 3. Diagnose failures

Classify each failure:

| Category | Indicators | Typical fix |
|---|---|---|
| **Assertion mismatch** | Expected vs actual mismatch | Fix expectation or production logic |
| **Missing/wrong mock** | Null reference on mock, unused stubs | Add/fix mock setup |
| **Timeout** | Timeout exceptions, async wait exceeded | Increase timeout, fix async logic |
| **Configuration error** | Context/setup failures, missing deps | Fix configuration |
| **Compilation error** | Symbol not found, type mismatch | Fix code |
| **Flaky / intermittent** | Passes on re-run with no changes | Note as flaky, proceed |

Read the failing test source and the production code it exercises to understand intent before fixing.

### 4. Fix and retry loop (up to 5 total attempts)

For each attempt:

1. Apply the fix — edit test or production code. Follow the project constitution.
2. Run only the failing tests (not the full suite on retries).
3. If the test passes, run the full suite for affected modules to check for regressions.
4. If the test still fails, re-diagnose and attempt the next fix.

**Stop retrying early if:**
- Same error repeats identically after 2 consecutive attempts.
- Fix would require fundamental redesign.
- Failure is in infrastructure (not code).

### 5. Full suite verification

After individual failures are resolved, run the complete test suite once.

If new failures appear, repeat from step 3 (counts toward the same 5-attempt budget).

### 6. Report

**If all pass:** Report success with summary of fixes.

**If attempts exhausted:** Produce a structured failure report:
- Failure category, error, attempts made, root cause hypothesis, suggested actions.

Ask the user how to proceed for each unresolved failure:
- **A) Provide guidance** — give a hint, retry.
- **B) Fix manually** — leave as-is.
- **C) Disable and move on** — mark the test as skipped/disabled with context.

For option C, use the language-appropriate mechanism to disable the test, including the root cause and the exact command to reproduce the failure.

## Input

- Test scope (optional — module, file, or test name).
- `PROJECT_ROOT` — resolved project root path.
- `test-command` — project's configured test command.
- `build-command` — project's configured build command.

## Output

- Test results: pass/fail summary.
- Failure report (if unresolved).

## Rules

- Use caller-provided test/build commands, never hardcoded commands.
- Follow the project constitution for all code changes.
- Maximum 5 total attempts (including the initial run).
- Language-agnostic: disable mechanism depends on the project's test framework.
