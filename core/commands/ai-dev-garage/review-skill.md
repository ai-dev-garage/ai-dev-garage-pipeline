---
name: review-skill
description: Entry only — resolves the target skill directory and runs the skill-standard skill in review mode to audit an existing pipeline skill.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Reviews an existing pipeline skill using the **skill-standard** skill. Provide the skill name or directory path. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to indicate which bundle to look in." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_SKILL_DIR` from arguments: use the path directly if absolute, or resolve as `GARAGE_BUNDLE_ROOT/skills/<name>/`.

4. Resolve the **skill-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/skill-standard/SKILL.md`.

5. Apply the skill in **review** mode with: `TARGET_SKILL_DIR`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output issues and proposed fixes. Do not apply changes until the user confirms.
