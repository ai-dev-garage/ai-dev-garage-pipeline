---
name: update-constitution
description: Load or initialize the project constitution, fill or amend its content, version the change, propagate updates to dependent docs, and write the result back to CONSTITUTION.md.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does, when to use it, and stop after **Usage** below.

   **What:** Creates or updates `<PROJECT_ROOT>/CONSTITUTION.md`: placeholders, semver, governance dates, propagation to dependent docs, validation, and a sync impact report (HTML comment).

   **When:** Bootstrapping governance, amending principles, or aligning docs after constitution changes.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace or the single tree containing `CONSTITUTION.md` (if ambiguous, ask). Pass free-text instructions for partial updates (e.g. one principle).

2. **Resolve target project**
   - Parse user input for `project=<path>`. If present, use that as `PROJECT_ROOT`. If not: use workspace root or the single directory containing a `CONSTITUTION.md`; if ambiguous, ask the user.
   - Set `CONSTITUTION_PATH` = `<PROJECT_ROOT>/CONSTITUTION.md`.

3. **Load or initialize the constitution**
   - Check if `CONSTITUTION_PATH` exists.
   - If it exists, load it and identify every placeholder token of the form `[ALL_CAPS_IDENTIFIER]`.
   - If it does NOT exist, create it from the default template file `default-constitution-template.md`. Resolve `TEMPLATE_PATH` by walking **`GARAGE_SEARCH_ROOTS`** in order: for each root `R`, use the first existing path among (1) `R/commands/references/default-constitution-template.md` (extension source tree), (2) any `R/commands/references/*/default-constitution-template.md` (merged install, e.g. `.../references/dev-workflow/default-constitution-template.md`).
   - If the user specifies a different number of principles than the template, adapt the structure accordingly.

4. **Collect or derive values for placeholders**
   - If user input supplies a value, use it.
   - Otherwise infer from existing repo context (README, docs, prior constitution if embedded).
   - For governance dates:
     - `RATIFICATION_DATE`: original adoption date; if unknown on first creation, use today's date or mark TODO.
     - `LAST_AMENDED_DATE`: today if any change is made; otherwise keep previous.
   - `CONSTITUTION_VERSION` must follow semantic versioning:
     - **MAJOR**: backward-incompatible governance or principle removals / redefinitions.
     - **MINOR**: new principle or section added, or material expansion.
     - **PATCH**: clarifications, wording, typo fixes, non-semantic refinements.
   - If bump type is ambiguous, propose reasoning before finalizing.
   - First creation always starts at `1.0.0`.

5. **Draft the updated constitution**
   - Replace every placeholder with concrete text. No bracketed tokens may remain unless the project has explicitly chosen to defer them — justify any deferred token.
   - Preserve heading hierarchy; remove explanatory comments once replaced.
   - Each Principle section: succinct name line, declarative rules paragraph or bullet list, explicit rationale if not obvious.
   - Governance section must cover: amendment procedure, versioning policy, compliance expectations.

6. **Consistency propagation**
   - Scan `PROJECT_ROOT` for any docs that reference principles by name or number (e.g., `README.md`, `docs/`, architecture decision records). Update stale references.
   - If any pipeline or command files under `PROJECT_ROOT` reference principles, verify alignment.
   - Only process files that actually exist; skip gracefully for missing ones.

7. **Produce a Sync Impact Report** (prepend as an HTML comment at the top of the written file):
   - Version change: old → new (or "initial creation").
   - Principles modified (old title → new title if renamed).
   - Sections added / removed.
   - Dependent files updated (✅ updated / ⚠ pending / ➖ not present).
   - Deferred TODOs if any placeholders were intentionally left.

8. **Validate before writing**
   - No unexplained bracket tokens remain.
   - Version line matches the report.
   - Dates are ISO format `YYYY-MM-DD`.
   - Principles are declarative and use MUST/SHOULD with rationale where "should" appeared vaguely.

9. **Write** the completed constitution to `CONSTITUTION_PATH` (overwrite).

10. **Output a final summary** to the user:
    - New version and bump rationale.
    - Files flagged for manual follow-up.
    - Suggested commit message (e.g., `docs: amend constitution to vX.Y.Z — <brief reason>`).

---

## Formatting Rules

- Use Markdown headings exactly as in the template (do not demote or promote levels).
- Keep a single blank line between sections.
- Avoid trailing whitespace.
- Wrap long rationale lines for readability (<100 chars) without introducing awkward breaks.

If user supplies partial updates (e.g., one principle revision only), still perform full validation and version decision.

If critical info is missing (e.g., ratification date on first creation), insert `TODO(<FIELD_NAME>): explanation` and include it in the Sync Impact Report.
