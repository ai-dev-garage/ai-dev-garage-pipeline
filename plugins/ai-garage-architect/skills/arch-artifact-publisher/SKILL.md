---
name: arch-artifact-publisher
description: Write a rendered architecture artifact (ADR, diagram, spec) to a user-specified local path, update an index file if present, and optionally run a project verification command after the write. Refuses to overwrite existing files without explicit confirmation.
argument-hint: artifact object (filename, content, format) + destination path + optional index_update + optional verification-command
---

# Arch artifact publisher

## When to use

- Called by the **architect** orchestrator at production step 7, immediately after **adr-writer** (or any future writer skill) returns a rendered artifact.
- Any caller that needs a safe, verified write of an architecture artifact into a project's doc tree.

## Input

- `artifact`:
  - `filename` — no path, just the file name.
  - `content` — full file content (string).
  - `format` — `adoc` | `md` | `puml` (informational; does not change the write).
- `destination_dir` — absolute directory path where the artifact lands.
- `index_update` — optional: a string fragment (one row or bullet) to append to the ADR index file if one is detected in `destination_dir` or its parent.
- `verification_command` — optional shell command string from `integrations.architect.verification-command`. Run from `PROJECT_ROOT`.

## Instructions

### 1. Resolve destination

- Ensure `destination_dir` exists (do not silently create more than one missing level; surface an error if the parent is missing).
- Compute `target = {destination_dir}/{filename}`.

### 2. Collision check

- If `target` already exists, **do not overwrite**. Return a `collision` result with the existing file's path; let the caller ask the user whether to replace it. Only on explicit user confirmation passed back in may the caller re-invoke with an `allow_overwrite: true` flag.

### 3. Write the artifact

- Write `artifact.content` to `target`.

### 4. Update the index

- Detect an index file in `destination_dir` (one of: `architecture-decisions.{adoc,md}`, `README.{adoc,md}`). If present and `index_update` is provided, **append** the row/bullet in the right section (the table or bullet list containing existing ADR entries). Do not rewrite unrelated parts of the index.
- If no index is found, skip this step — do not create one.

### 5. Verification

- If `verification_command` is set, run it from `PROJECT_ROOT`. Capture stdout/stderr and exit code.
- On non-zero exit: return `verification: { status: "fail", ... }` — the caller must not report success.

### 6. Return

Return:

- `written_path` — absolute path of the new artifact.
- `index_updated` — path of the index file if updated, else `null`.
- `verification` — `{ status, command, exit_code, output }` or `null` if not run.

## Rules

- **Never overwrite silently.** Collisions surface as a distinct return status; the caller decides.
- **Append-only index updates.** Never rewrite the index file wholesale.
- **Verification gates "done".** If the verification command fails, the caller must treat the operation as incomplete even though the file was written.
- **Local only (v1).** Destinations beyond the local filesystem are reserved for later (`type: notion`, `type: confluence` — not implemented).
- **Secrets:** none required; writes are local. If a future verification command itself requires secrets, it reads them from env / gitignored env files of the project, not from chat.
