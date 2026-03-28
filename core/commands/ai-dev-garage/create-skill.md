---
name: create-skill
description: Entry only — resolves the target bundle and runs the skill-standard skill in create mode to draft a new pipeline skill.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Creates a new pipeline skill using the **skill-standard** skill. Provide a name or description for the skill. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to control where the skill will be written." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_SKILL_DIR` = `GARAGE_BUNDLE_ROOT/skills/<name>/` (name from user input or TBD in skill).

4. Resolve the **skill-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/skill-standard/SKILL.md`.

5. Apply the skill in **create** mode with: user input as description, `TARGET_SKILL_DIR`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output the proposed skill layout and content. Do not write files until the user confirms.
