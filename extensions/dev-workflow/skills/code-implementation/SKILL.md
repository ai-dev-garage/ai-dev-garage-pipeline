---
name: code-implementation
description: Implement production code or tests ensuring compliance with the project constitution. Use when asked to implement a feature, logic, class, function, or to cover something with tests. Language-agnostic.
argument-hint: description of what to implement
---

# Code implementation

## When to use

- User asks to implement a feature, function, class, module, or test.
- Called by `implement-task` agent during WBS execution.
- Ad-hoc implementation requests outside a delivery workflow.

## Instructions

### 1. Load WBS context (if available)

Resolve the task key in order:

1. **Explicit** — caller or user provided a task key.
2. **Branch name** — run `git branch --show-current`. If the branch matches `{prefix}/{TASK-KEY}`, extract the key.
3. **Single state dir** — list directories under `.ai-dev-garage/.workflow-state-tmp/`. If exactly one exists, use it.

If a key is found, read `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/work-breakdown-structure.md`.

If found:
- Read the `## Progress` section.
- Find the first `[IN PROGRESS]` item. If none, note the first `NOT STARTED` item.
- Use this context to align the implementation with the agreed plan.

If no WBS exists, proceed without tracking.

### 2. Read the constitution

Look for `CONSTITUTION.md` at the project root.

Read it fully. All implementation decisions must comply with every principle it defines. If the file does not exist, warn the user and proceed with general best-practice defaults.

### 3. Identify scope

Using the constitution's architecture principles (if available):

- Determine which module(s) or directory the change belongs to.
- Confirm whether this is production code, tests, or both.
- Confirm any cross-module dependency rules that apply.

### 4. Implement production code

Apply every constitution principle that governs this type of change:

- Module placement and dependency direction.
- Naming and structural conventions.
- Forbidden patterns explicitly listed in the constitution.
- When a design decision is non-obvious, leave a brief inline comment.

### 5. Implement tests

Apply every constitution principle that governs testing:

- Test naming conventions.
- Test structure and organization.
- Mocking and assertion rules.
- Test placement conventions.

Prefer TDD when the WBS phase indicates it.

### 6. Self-review

After implementing, review every modified file against:

1. All applicable constitution principles — tick off each one.
2. No duplication introduced across files.
3. Build passes: run the project's configured build command for affected modules.

### 7. Update WBS (if active)

If a WBS was found in step 1:

- Match the change to WBS items (scan the entire `## Progress` section).
- Mark completed items `[DONE]`, partially addressed items `[IN PROGRESS]`.
- Append to `### Implementation Summary` of the relevant phase:
  - What was changed and why (one line per change).
  - HLD impact: decisions that may require documentation updates, or "None".
- If all items in a phase are now `[DONE]`, write the full phase summary.

## Input

- Description of what to implement.
- `PROJECT_ROOT` — resolved project root path.
- `TASK-KEY` (optional) — for WBS tracking.
- `build-command` — project's configured build command.

## Output

- Implemented code files.
- Updated WBS (if active).
- Self-review results.

## Rules

- Constitution compliance is mandatory when a constitution exists.
- WBS tracking is optional — activates only when state files exist.
- Language-agnostic: use the project's actual tech stack, not hardcoded patterns.
- Build/test commands come from caller-provided inputs, not hardcoded.
- Project-specific patterns belong in the constitution, not in this skill. See [REFERENCE.md](references/REFERENCE.md).
