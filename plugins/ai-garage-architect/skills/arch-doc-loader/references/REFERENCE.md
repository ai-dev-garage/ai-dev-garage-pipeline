# Arch doc loader — reference

## Return bundle shape

```
{
  "greenfield": false,
  "docs":     [ { "path": "<abs>", "content": "<raw>", "format": "md|adoc|txt" } ],
  "diagrams": [ { "path": "<abs>", "content": "<raw>" } ],
  "adrs":     [ { "path": "<abs>", "id": "ADR-004", "title": "<first heading>", "status": "Accepted|Proposed|Superseded|null" } ]
}
```

## ADR detection

- **Filename pattern:** `adr-NNN-*` (case-insensitive). `NNN` is 1+ digits.
- **Extensions:** `.md` or `.adoc`.
- **`id`:** uppercase of the matched prefix, e.g. `adr-004-foo.adoc` → `ADR-004`.
- **`title`:** first heading in the file. `.adoc` uses `= Title`; `.md` uses `# Title`.
- **`status`:** first line matching `Status:` (AsciiDoc) or `**Status:**` (Markdown) followed by a value. If absent, `null`.

## Index detection (used by adr-writer, informational here)

An ADR index file is one of:

- `architecture-decisions.adoc`
- `architecture-decisions.md`
- `README.md` / `README.adoc` inside the ADR directory

The loader does not modify the index; it is detected downstream by `adr-writer` / `arch-artifact-publisher`.

## Source types

| Type | v1 | Notes |
|------|----|-------|
| `local` | yes | `path` relative to `PROJECT_ROOT` or absolute. |
| `github` | reserved | future: `repo`, `path`, `ref`; env `GITHUB_TOKEN`. |
| `confluence` | reserved | future: `base-url`, `space`; env `CONFLUENCE_USERNAME` + `CONFLUENCE_PASSWORD` or `ATLASSIAN_API_TOKEN`. |

## Greenfield behaviour

Returns:

```
{ "greenfield": true, "docs": [], "diagrams": [], "adrs": [] }
```

Callers should proceed from user input alone; no error.
