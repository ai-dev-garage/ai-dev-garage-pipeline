---
name: doctor
description: Sanity-check the assistant integration for this workspace. Validates `integrations.assistant.*`, locates the Notion MCP connector, and read-only-probes the configured Notion database + optional parent page. Never writes pages and never prompts for a token.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Reports on `integrations.assistant.*` config, Notion MCP availability, and reachability of the configured database (and parent page, if set). Each finding is `OK | WARN | FAIL`.

   **When:** After `/ai-garage-assistant:configure`, or when `/assistant:capture` / `session-summarizer` report publish failures.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root.

2. **Resolve target project**
   - Parse `project=<path>`. Otherwise use the workspace root.
   - Resolve `CONFIG_PATH` via **`ai-garage-core:config-merger`** with `path --scope project`.

3. **Schema validation (fast path)**
   - Run `config-merger validate`. Surface errors whose key begins with `integrations.assistant.` as FAIL items; stop further assistant checks on FAIL.

4. **MCP connector resolution**

   Read `integrations.assistant.notion-mcp-connector`.

   - **Configured** (non-null): verify a tool matching `mcp__<connector>__API-post-page` is actually available in the current Claude session. If not available → `FAIL: configured MCP connector "<name>" not reachable — add the Notion MCP in Claude settings or update config`. If available → `OK: MCP connector <name> reachable`.
   - **Unset** (null): enumerate currently available tools matching `mcp__*__API-post-page`, filter to names containing `notion` (case-insensitive).
     - 0 matches → `FAIL: no Notion MCP installed — see assistant README, then run /ai-garage-assistant:configure`.
     - 1 match → `OK: auto-detect will pick <name>; consider pinning it via /ai-garage-assistant:configure`.
     - ≥2 matches → `WARN: multiple Notion MCPs available (<list>) — pin one via /ai-garage-assistant:configure to avoid runtime prompt`.

5. **Database reachability**

   Read `integrations.assistant.notion-database-id`.

   - **Unset**: `WARN: notion-database-id not configured — /ai-garage-assistant:setup-claude-project bootstraps one under notion-parent-page-id`.
   - **Set**: call `mcp__<connector>__API-retrieve-a-database` (read-only) with the id.
     - success → `OK: database reachable (title: "<title>")`
     - 404 / not found → `FAIL: database id <id> not found — it may have been deleted or the MCP connector lacks access`
     - 403 → `FAIL: MCP connector cannot access this database — share the DB with the integration in Notion`
     - other → `FAIL: database probe returned <error>`

   If step 4 produced no usable connector, skip this step and print `WARN: cannot probe database without a resolved MCP connector`.

6. **Parent page sanity** (optional)

   Read `integrations.assistant.notion-parent-page-id`.

   - If `notion-database-id` is already set and this is null → `OK: parent page not needed (database already exists)`.
   - If both are null → `WARN: set notion-parent-page-id so /assistant:setup-claude-project can bootstrap a database`.
   - If set → call `mcp__<connector>__API-retrieve-a-page` (read-only):
     - success → `OK: parent page reachable (title: "<title>")`
     - 404 → `FAIL: parent page id <id> not found`
     - 403 → `FAIL: MCP connector cannot access this page — share it with the integration`
     - other → `FAIL: parent page probe returned <error>`

7. **Shape checks (non-fatal)**

   | Check | Rule | Status |
   |---|---|---|
   | `default-tags` | list of non-empty strings (validator already enforced) | length info only |
   | `session-prefix` | non-empty string or null | present → `OK: session prefix "<prefix>"`; null → `OK: no session prefix (Session property left as-is)` |

8. **plugins.installed sanity**
   - If `ai-garage-assistant` is not in `plugins.installed`, print `WARN: plugin not registered — run /ai-garage-assistant:configure`.

9. **Summary**

   ```
   Assistant doctor: <N> OK / <M> WARN / <K> FAIL
   ```

## Rules

- **Read-only.** Never create a page, never mutate the database, never write config. All MCP calls used here are `retrieve-*` endpoints.
- **Never prompt for a Notion token.** Auth lives in the MCP connector configuration in the host (Claude Code / Cursor / Desktop). This command never touches tokens.
- **No network beyond the configured MCP.** Do not call the Notion REST API directly; always go through the resolved connector.
- **Single probe per resource.** One database retrieve, at most one page retrieve. Do not list database rows, search pages, or paginate.
- **Graceful without a connector.** If no Notion MCP is available at all, degrade to config-only checks and emit one clear FAIL about MCP availability — never fabricate results.
