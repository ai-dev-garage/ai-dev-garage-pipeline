---
name: code-quality-review
description: Review code for design quality issues — cohesion, coupling, abstraction leaks, and missed structural opportunities. Paradigm-aware: adapts finding vocabulary to the detected stack. Use after implementation or ad-hoc on any file or module.
argument-hint: file path(s), directory, or description of changed files
---

# Code quality review

## When to use

- Ad-hoc: reviewing any file, module, or directory at any time.
- Post-implementation: called by `implement-task` after a WBS phase completes.

## Instructions

### 1. Resolve target

- If a file path or directory was provided, read those files.
- If called from `implement-task`, read files listed as changed in the phase work report.
- If neither, ask the caller to specify a target.

### 2. Detect paradigm

From file extensions, imports, and code patterns, identify the dominant paradigm(s) per file:

- Class-based OOP (Java, C#, Python classes, Kotlin classes)
- Protocol/value-oriented (Swift, Kotlin data/sealed classes)
- Functional (Haskell, Elixir, F#, Clojure)
- Mixed OOP+Functional (TypeScript/JS, Kotlin, Scala, Python)
- Component/declarative UI (React, SwiftUI, Jetpack Compose)

If `project.stack` was passed by the caller, use it as the primary signal.

### 3. Apply base quality checks

For each reviewed unit, evaluate the design quality problems defined in [REFERENCE.md](references/REFERENCE.md):

- **Cohesion** — does this unit have one clear responsibility?
- **Coupling** — does this unit depend on concrete details it shouldn't need to know?
- **Abstraction leak** — does this unit expose or rely on implementation details that belong inside a boundary?
- **Rigidity** — would adding a new variant require modifying existing units?
- **Interface bloat** — does any contract expose more than its consumers need?
- **Substitutability** — can implementations be swapped without callers breaking? (apply where paradigm-relevant)

Classify each finding:
- `[BLOCKER]` — clear violation with a concrete negative consequence
- `[SUGGESTION]` — improvement opportunity; code works but carries a design smell
- `[NOTE]` — observation worth noting; no immediate action needed

### 4. Load stack extension (if available)

If `project.stack` is set and a `{stack}-code-quality-review` skill is installed, load and apply it. Stack extensions add paradigm-specific vocabulary and idiomatic solutions on top of this base review.

### 5. Apply constitution rules (if provided)

Cross-check findings against any constitution rules passed by the caller. A constitution-approved pattern is not a violation. Constitution overrides base checks.

### 6. Produce review report

Output a structured report per the format in [REFERENCE.md](references/REFERENCE.md).

## Input

- **Target** — file path(s), directory, or reference to changed files (required).
- **project.stack** — stack identifier (optional; auto-detected if absent).
- **Constitution rules** — architecture constraints (optional; passed by pipeline agents).

## Output

- Structured review report: classified findings with locations, problem descriptions, and idiomatic improvement suggestions.

## Rules

- Paradigm-first: frame findings in the vocabulary of the detected paradigm. Do not apply OOP terms to functional code or vice versa.
- Constitution overrides base checks.
- Non-blocking: report findings, do not apply changes. The caller decides what to act on.
- Stack extension takes precedence over base check findings where they conflict.
- No invention: only flag what is present. Do not suggest patterns for hypothetical future needs.

## More detail

- Problem taxonomy, paradigm-to-vocabulary mapping, output format, stack extension contract: [REFERENCE.md](references/REFERENCE.md)
