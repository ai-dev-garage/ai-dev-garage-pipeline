#!/usr/bin/env python3
"""Fetch a Jira epic and its direct child issues, emit normalized JSON.

Stateless helper for the `jira-epic-walker` skill. The skill orchestrator owns
rendering; this script owns the HTTP round-trips and normalization.

Exit codes:
    0  success
    2  credentials missing
    3  epic not found (HTTP 404)
    4  unauthorized (HTTP 401/403)
    5  other HTTP / transport error
    6  bad usage
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


TICKET_KEY_RE = re.compile(r"[A-Za-z]+-\d+")
DONE_CATEGORY_KEY = "done"


def _env_file_candidates(project_root: str | None) -> list[tuple[Path, bool]]:
    home = Path.home()
    candidates: list[tuple[Path, bool]] = [
        (home / ".ai-dev-garage" / "secrets.env", False),
        (home / ".config" / "ai-garage" / "jira.env", True),
    ]
    if project_root:
        root = Path(project_root)
        candidates.extend(
            [
                (root / ".ai-dev-garage" / "secrets.env", False),
                (root / ".config" / "ai-garage" / "jira.env", True),
            ]
        )
    return candidates


def _load_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return values
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            values[key] = value
    return values


def resolve_credentials(
    project_root: str | None,
    cli_base_url: str | None,
    cli_token: str | None,
) -> tuple[str, str, str | None]:
    """Apply the credential overlay documented in references/REFERENCE.md.

    Returns (base_url, token, user_email_or_none).
    """
    resolved: dict[str, str] = {}
    for path, is_legacy in _env_file_candidates(project_root):
        if not path.exists():
            continue
        if is_legacy:
            print(
                f"jira-epic-walker: reading legacy env file {path}; "
                "migrate to ~/.ai-dev-garage/secrets.env",
                file=sys.stderr,
            )
        resolved.update(_load_env_file(path))

    for key in ("JIRA_BASE_URL", "JIRA_API_TOKEN", "JIRA_USER_EMAIL"):
        env_val = os.environ.get(key)
        if env_val:
            resolved[key] = env_val
    if not resolved.get("JIRA_API_TOKEN"):
        for alt in ("ATLASSIAN_API_TOKEN", "CONFLUENCE_API_TOKEN"):
            env_val = os.environ.get(alt)
            if env_val:
                resolved["JIRA_API_TOKEN"] = env_val
                break

    if cli_base_url:
        resolved["JIRA_BASE_URL"] = cli_base_url
    if cli_token:
        resolved["JIRA_API_TOKEN"] = cli_token

    base_url = (resolved.get("JIRA_BASE_URL") or "").rstrip("/")
    token = resolved.get("JIRA_API_TOKEN") or ""
    email = resolved.get("JIRA_USER_EMAIL") or None

    if not base_url or not token:
        missing = []
        if not base_url:
            missing.append("JIRA_BASE_URL")
        if not token:
            missing.append("JIRA_API_TOKEN")
        print(
            "jira-epic-walker: missing credentials ("
            + ", ".join(missing)
            + "). See plugins/ai-garage-jira/skills/jira-epic-walker/"
            "references/REFERENCE.md for setup.",
            file=sys.stderr,
        )
        sys.exit(2)

    return base_url, token, email


def _auth_header(token: str, email: str | None) -> str:
    if email:
        pair = f"{email}:{token}".encode("utf-8")
        return "Basic " + base64.b64encode(pair).decode("ascii")
    return f"Bearer {token}"


def _http_get_json(url: str, token: str, email: str | None) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": _auth_header(token, email),
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        body = err.read().decode("utf-8", errors="replace")
        if err.code == 404:
            print(f"jira-epic-walker: 404 not found at {url}", file=sys.stderr)
            sys.exit(3)
        if err.code in (401, 403):
            print(
                f"jira-epic-walker: {err.code} unauthorized — rotate "
                "JIRA_API_TOKEN or confirm JIRA_USER_EMAIL matches the token "
                f"owner. Response: {body[:200]}",
                file=sys.stderr,
            )
            sys.exit(4)
        print(
            f"jira-epic-walker: HTTP {err.code} at {url}: {body[:400]}",
            file=sys.stderr,
        )
        sys.exit(5)
    except urllib.error.URLError as err:
        print(f"jira-epic-walker: transport error at {url}: {err}", file=sys.stderr)
        sys.exit(5)


def extract_key(raw: str) -> str:
    match = TICKET_KEY_RE.search(raw)
    if not match:
        print(
            f"jira-epic-walker: could not extract a Jira key from {raw!r}",
            file=sys.stderr,
        )
        sys.exit(6)
    return match.group(0).upper()


def _status_category(fields: dict) -> str:
    status = fields.get("status") or {}
    category = status.get("statusCategory") or {}
    return (category.get("key") or "").lower()


def _status_name(fields: dict) -> str:
    return ((fields.get("status") or {}).get("name")) or ""


def _issue_summary(issue: dict) -> dict:
    fields = issue.get("fields") or {}
    assignee = fields.get("assignee") or {}
    priority = fields.get("priority") or {}
    issuetype = fields.get("issuetype") or {}
    return {
        "key": issue.get("key"),
        "summary": fields.get("summary"),
        "status_name": _status_name(fields),
        "status_category": _status_category(fields),
        "type": issuetype.get("name"),
        "priority": priority.get("name"),
        "assignee": assignee.get("displayName"),
        "rank": fields.get("customfield_10019"),
        "created": fields.get("created"),
        "blocks": _links(fields, "outward", "blocks"),
        "blocked_by": _links(fields, "inward", "is blocked by"),
    }


def _links(fields: dict, direction: str, label: str) -> list[dict]:
    out: list[dict] = []
    for link in fields.get("issuelinks") or []:
        link_type = link.get("type") or {}
        if (link_type.get(direction) or "").lower() != label.lower():
            continue
        target_key = "outwardIssue" if direction == "outward" else "inwardIssue"
        target = link.get(target_key)
        if not target:
            continue
        target_fields = target.get("fields") or {}
        out.append(
            {
                "key": target.get("key"),
                "summary": target_fields.get("summary"),
                "status_name": _status_name(target_fields),
                "status_category": _status_category(target_fields),
            }
        )
    return out


def fetch_epic(base_url: str, token: str, email: str | None, key: str) -> dict:
    fields = (
        "summary,description,status,priority,issuetype,assignee,reporter,"
        "parent,created,updated,issuelinks"
    )
    url = f"{base_url}/rest/api/3/issue/{urllib.parse.quote(key)}?fields={fields}"
    return _http_get_json(url, token, email)


def fetch_children(base_url: str, token: str, email: str | None, key: str) -> list[dict]:
    fields = (
        "summary,status,issuetype,priority,assignee,issuelinks,created,"
        "customfield_10019"
    )
    jql = f"parent={key}"
    params = urllib.parse.urlencode({"jql": jql, "fields": fields})
    url = f"{base_url}/rest/api/3/search/jql?{params}"
    payload = _http_get_json(url, token, email)
    return payload.get("issues") or []


def select_candidates(children: list[dict], include_done: bool, top_n: int) -> list[dict]:
    filtered: list[dict] = []
    for child in children:
        if not include_done and child["status_category"] == DONE_CATEGORY_KEY:
            continue
        if any(
            bl.get("status_category") != DONE_CATEGORY_KEY
            for bl in child.get("blocked_by") or []
        ):
            continue
        filtered.append(child)

    def sort_key(child: dict) -> tuple[int, str, str]:
        rank = child.get("rank")
        has_rank = 0 if rank else 1
        return (has_rank, rank or "", child.get("created") or "")

    filtered.sort(key=sort_key)
    return filtered[:top_n]


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch a Jira epic and its children.")
    parser.add_argument("epic", help="Jira epic key or URL (e.g. AISD-1)")
    parser.add_argument(
        "--include-done",
        action="store_true",
        help="Keep done/closed children in output and candidates",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=3,
        help="Number of next-candidate stories to return (default 3)",
    )
    parser.add_argument(
        "--jira-base-url",
        default=None,
        help="Override base URL (wins over env files and process env)",
    )
    parser.add_argument(
        "--jira-api-token",
        default=None,
        help="Override API token (wins over env files and process env)",
    )
    parser.add_argument(
        "--project-root",
        default=os.environ.get("PROJECT_ROOT"),
        help="Project root for project-level env file lookup",
    )
    args = parser.parse_args()

    base_url, token, email = resolve_credentials(
        args.project_root, args.jira_base_url, args.jira_api_token
    )
    key = extract_key(args.epic)

    epic_raw = fetch_epic(base_url, token, email, key)
    epic_fields = epic_raw.get("fields") or {}
    epic = {
        "key": epic_raw.get("key"),
        "url": f"{base_url}/browse/{epic_raw.get('key')}",
        "summary": epic_fields.get("summary"),
        "status_name": _status_name(epic_fields),
        "status_category": _status_category(epic_fields),
        "type": (epic_fields.get("issuetype") or {}).get("name"),
        "priority": (epic_fields.get("priority") or {}).get("name"),
        "assignee": (epic_fields.get("assignee") or {}).get("displayName"),
        "reporter": (epic_fields.get("reporter") or {}).get("displayName"),
        "created": epic_fields.get("created"),
        "updated": epic_fields.get("updated"),
    }

    children_raw = fetch_children(base_url, token, email, key)
    children = [_issue_summary(c) for c in children_raw]
    for child in children:
        child["url"] = f"{base_url}/browse/{child['key']}"

    def rank_sort_key(child: dict) -> tuple[int, str, str]:
        rank = child.get("rank")
        has_rank = 0 if rank else 1
        return (has_rank, rank or "", child.get("created") or "")

    children.sort(key=rank_sort_key)

    if args.include_done:
        display_children = children
    else:
        display_children = [
            c for c in children if c["status_category"] != DONE_CATEGORY_KEY
        ]

    candidates = select_candidates(children, args.include_done, args.top)

    output = {
        "epic": epic,
        "children": display_children,
        "next_candidates": [c["key"] for c in candidates],
        "next_candidates_detail": candidates,
    }
    json.dump(output, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
