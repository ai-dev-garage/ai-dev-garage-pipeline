---
name: doctor
description: Sanity-check the architect integration for this workspace. Validates `integrations.architect.*`, verifies doc-source paths exist, detects the project's ADR format, and confirms the verification command binary is resolvable on PATH. Read-only — never writes, never executes the verification command.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Reports on `integrations.architect.*` config shape, doc-source paths, detected ADR house style, and the verification-command binary. Each finding is `OK | WARN | FAIL`.

   **When:** After `/ai-garage-architect:configure`, or when `/architect` reports path/format issues.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root.

2. **Resolve target project**
   - Parse `project=<path>`. Otherwise use the workspace root.
   - Resolve `CONFIG_PATH` via **`ai-garage-core:config-merger`** with `path --scope project`.

3. **Schema validation (fast path)**
   - Run `config-merger validate`. Surface any errors whose key begins with `integrations.architect.` as FAIL items; stop further architect checks on FAIL (config shape must be valid before we can trust the rest).

4. **Doc-source checks**

   For each entry under `integrations.architect.doc-sources` (list may be empty — greenfield):

   | Check | Rule | Status mapping |
   |---|---|---|
   | `type` | `local` (v1) / `github` / `confluence` (reserved) | `local` → continue; `github`/`confluence` → `WARN: reserved source type — skipped in v1` |
   | `path` (local) | resolve absolute path (relative = relative to `PROJECT_ROOT`); must exist | missing dir → FAIL; dir exists, empty → WARN; dir exists, has matches → OK |
   | glob hit count | count files matching `**/*.{md,adoc,puml,txt}` under each local path | 0 → `WARN: no doc files under <path>`; ≥1 → `OK: <N> doc files, <M> ADRs detected` |

   If the list is empty **and** `default-output.*` is also all null, print one `OK: greenfield mode (no existing docs)` line and skip format detection.

5. **Format detection**
   - If at least one `local` doc source exists, enumerate files matching `adr-NNN-*.{md,adoc}` (case-insensitive) under each doc source.
   - If any are found, record the dominant extension (`adoc` vs `md`) as `detected_format`.
   - Compare `detected_format` to `integrations.architect.default-output.format`:
     - match → `OK: output format matches existing ADRs (<fmt>)`
     - mismatch → `WARN: configured format <configured> ≠ detected <detected> — /architect will match the detected style per-ADR, but configure may want updating`
     - `detected_format` present, configured `null` → `WARN: output format unset — detected <detected> in project, suggest running /ai-garage-architect:configure`
     - no ADRs detected, configured `null` → `OK: no existing ADRs; greenfield default will apply on first produce`

6. **ADR path check**
   - `integrations.architect.default-output.adr-path`: if set, resolve; if absent on disk, `WARN: adr-path does not exist yet — first ADR write will need parent dir created`. Do **not** create it from doctor.
   - If set **and** exists, count ADRs under it (same filename pattern) and report `OK: <N> existing ADRs at <path>`.

7. **Verification command check** (optional)
   - If `integrations.architect.verification-command` is unset → `OK: no verification command configured (skipped post-write)`.
   - If set: split the command on whitespace and take the first token as `BIN`. Resolve it:
     - Absolute path → check the file exists and is executable.
     - `./...` → resolve relative to `PROJECT_ROOT`.
     - Bare name → use `command -v <BIN>` to locate on PATH.
   - Report:
     - resolvable → `OK: verification command binary found: <resolved path>`
     - not found → `FAIL: verification command binary not on PATH — <BIN>`
   - **Never execute the command itself** — doctor is read-only. Running a real build is the publisher's job after an artifact write.

8. **plugins.installed sanity**
   - If `ai-garage-architect` is not in `plugins.installed`, print `WARN: plugin not registered — run /ai-garage-architect:configure`.

9. **Summary**

   ```
   Architect doctor: <N> OK / <M> WARN / <K> FAIL
   ```

## Rules

- **Read-only.** Never write config, never create directories, never run the verification command.
- **No network.** All checks are local — no `gh`, no WebFetch, no Atlassian calls. (`github`/`confluence` source types are schema-reserved only.)
- **Greenfield is not a warning.** Empty doc-sources + all-null defaults is a valid state; report it as one `OK` line and move on.
- **Path safety.** When resolving doc-source paths, do not follow symlinks out of `PROJECT_ROOT` for the `**/*.{md,adoc,puml,txt}` glob; bounded to the resolved source directory.
- **Quiet by default.** Single status line per check; no per-file output unless the user explicitly asked for `--verbose` (future flag; not required in v1).
