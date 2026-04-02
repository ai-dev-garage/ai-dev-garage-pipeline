---
name: task-gap-clarification
description: Interactively clarify gaps, mismatches, and ambiguities from a task analysis. Walks through each tagged item one by one, presenting a suggested resolution and letting the user accept, skip, or provide their own answer.
argument-hint: task analysis content containing [GAP], [MISMATCH], or [AMBIGUITY] tags
---

# Task gap clarification

## When to use

- After presenting a task analysis that contains tagged gaps.
- Called by `deliver-task` dispatcher after the analysis phase produces unresolved items.

## Instructions

### 1. Collect the gap list

Extract items tagged `[GAP]`, `[MISMATCH]`, or `[AMBIGUITY]` from the analysis output. Each item has: tag, title, explanation, and source citations.

### 2. Iterate one item at a time

For each item, present to the user:

1. **Tag and title** — e.g. `[GAP] Missing error handling spec`
2. **Explanation** — the issue and its source citations.
3. **Suggested resolution** — best guess based on the analysis context and documentation already read.

Ask the user to choose:
- **Accept** — use the suggested resolution as-is.
- **Skip** — leave unresolved, carry forward.
- **Custom** — user provides their own clarification.

If **Custom**, ask the user to type their clarification. Record the response before moving to the next item.

### 3. Return the clarified summary

After all items are processed, produce two lists:

**Resolved:** Items where the user accepted the suggestion or provided a custom answer. Include the resolution text.

**Unresolved:** Items the user skipped. Keep the original tag and explanation intact.

## Input

- Analysis output containing `[GAP]`, `[MISMATCH]`, or `[AMBIGUITY]` tagged items.

## Output

- Clarified summary with resolved and unresolved lists.

## Rules

- **Interactive skill** — requires user turns; not a stateless one-shot transform.
- One item at a time. Do not batch questions.
- Never auto-resolve items without user confirmation.
- Preserve original tags and citations in the output.
