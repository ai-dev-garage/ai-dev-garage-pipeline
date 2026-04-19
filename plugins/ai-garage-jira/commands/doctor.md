---
name: doctor
description: Sanity-check Jira integration for this workspace. Validates base URL, resolves the API token through the standard overlay, and tests reachability via GET /rest/api/2/myself. Read-only — never writes.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Reports on `integrations.jira.*` config, credential resolution (from env + env files), and a single authenticated API round-trip (`GET /rest/api/2/myself`). Each finding is `OK | WARN | FAIL`.

   **When:** After `/ai-garage-jira:configure`, or when Jira-related workflows (`/deliver-task`, phase sync) fail silently.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root.

2. **Resolve target project**
   - Parse `project=<path>`. Otherwise use the workspace root.
   - Resolve `CONFIG_PATH` via **`ai-garage-core:config-merger`** with `path --scope project`.

3. **Config checks**

   | Check | Rule | Status mapping |
   |---|---|---|
   | `integrations.jira.base-url` | starts with `https://` | missing → WARN, malformed → FAIL, present → OK |
   | `integrations.jira.subtask-type` | non-empty string | default `"Sub-task"` → OK, empty → FAIL |
   | `integrations.jira.sync-phases` | boolean | null → WARN (opt-out ambiguous), `false`/`true` → OK |
   | `integrations.jira.transitions.*` | string or null | invalid type → FAIL, null → OK (event skipped) |

4. **Credential resolution**

   Use the overlay described in `skills/jira-item-fetcher/references/REFERENCE.md`:

   1. Canonical global env file: `~/.ai-dev-garage/secrets.env`
   2. Legacy global: `~/.config/ai-garage/jira.env` (emit `WARN: using legacy path — migrate to ~/.ai-dev-garage/secrets.env`)
   3. Canonical project env file: `<PROJECT_ROOT>/.ai-dev-garage/secrets.env`
   4. Legacy project: `<PROJECT_ROOT>/.config/ai-garage/jira.env` (same WARN)
   5. Process env: `JIRA_BASE_URL`, `JIRA_API_TOKEN`, fallbacks `ATLASSIAN_API_TOKEN` then `CONFLUENCE_API_TOKEN`.

   Report:
   - `OK: base URL resolved from <source>` — do **not** print the URL if it was only supplied through `secrets.env` (print the source; the URL itself appears in config, so it's fine to print when read from config).
   - `OK: API token resolved from <source>` — **never** print the token itself. Source only.
   - `FAIL: base URL not found — run /ai-garage-jira:configure`.
   - `FAIL: API token not found — see plugin README for secrets placement`.

5. **Live reachability**

   Only if both base URL and token resolved, issue a single authenticated request:

   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/jira_cli.py" auth-test --project-root "$PROJECT_ROOT"
   ```

   Interpret the result by exit code:
   - **Exit 0** with `http_status: 200` → `OK: Jira reachable`.
   - **Exit 1** with `http_status: 401` or `403` → `FAIL: Jira rejected the token — rotate it via Atlassian account settings`.
   - **Exit 1** with `http_status: 404` → `FAIL: /rest/api/2/myself not found — verify JIRA_BASE_URL points at a Jira Cloud site, not a Confluence or root domain`.
   - **Exit 1** (other) → `FAIL: HTTP <status> — <error>`.
   - **Exit 2** → `FAIL: credentials not found` (should not reach here since step 4 already checked).

   Do **not** fetch any tickets in doctor. One round-trip, no PII beyond the authenticated user's display name (optional, do not print).

6. **plugins.installed sanity**
   - If `ai-garage-jira` is not in `plugins.installed`, print `WARN: plugin not registered — run /ai-garage-jira:configure`.

7. **Summary**

   ```
   Jira doctor: <N> OK / <M> WARN / <K> FAIL
   ```

## Rules

- **Read-only.** Never write config or env files.
- **Never print the API token or any secret.** Report its *source* only.
- **Single round-trip.** Do not probe multiple endpoints. `/myself` is the canonical auth probe.
- **Network-tolerant.** If the curl call times out or fails to resolve DNS, report `WARN: Jira unreachable (<reason>)` and exit — do not retry.
