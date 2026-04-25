#!/usr/bin/env python3
"""
AI Dev Garage — Jira REST API CLI.

Subcommands: fetch, search, create-issue, get-transitions, transition, auth-test.

Exit codes:
  0 — success (JSON on stdout)
  1 — API or network error (JSON on stderr)
  2 — credentials missing (JSON on stderr with hint)
"""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

# ---------------------------------------------------------------------------
# Env-file parser
# ---------------------------------------------------------------------------

def _parse_env_file(path):
    """Read KEY=value lines from an env file. Skip comments and blank lines."""
    result = {}
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" not in line:
                    continue
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip()
                # Strip optional surrounding quotes
                if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
                    value = value[1:-1]
                if key and value:
                    result[key] = value
    except FileNotFoundError:
        pass
    return result


# ---------------------------------------------------------------------------
# Credential resolution (4-layer overlay)
# ---------------------------------------------------------------------------

_LEGACY_WARNING = "WARN: using legacy path %s — migrate to %s"


def _resolve_credentials(cli_base_url, cli_token, cli_email, project_root):
    """
    Resolve JIRA_BASE_URL, JIRA_API_TOKEN, and optional JIRA_USER_EMAIL
    through a 4-layer overlay.  Returns (base_url, token, email_or_none).
    Exits with code 2 if base_url or token cannot be resolved.
    """
    base_url = None
    token = None
    email = None

    home = str(Path.home())

    # Layer 1: Global env file
    canonical = os.path.join(home, ".ai-dev-garage", "secrets.env")
    legacy = os.path.join(home, ".config", "ai-garage", "jira.env")

    env = _parse_env_file(canonical)
    if not env and os.path.isfile(legacy):
        env = _parse_env_file(legacy)
        if env:
            print(_LEGACY_WARNING % (legacy, canonical), file=sys.stderr)

    base_url = env.get("JIRA_BASE_URL", base_url)
    token = env.get("JIRA_API_TOKEN", token)
    email = env.get("JIRA_USER_EMAIL", email)

    # Layer 2: Project env file (if project_root set)
    if project_root:
        p_canonical = os.path.join(project_root, ".ai-dev-garage", "secrets.env")
        p_legacy = os.path.join(project_root, ".config", "ai-garage", "jira.env")

        p_env = _parse_env_file(p_canonical)
        if not p_env and os.path.isfile(p_legacy):
            p_env = _parse_env_file(p_legacy)
            if p_env:
                print(_LEGACY_WARNING % (p_legacy, p_canonical), file=sys.stderr)

        if p_env.get("JIRA_BASE_URL"):
            base_url = p_env["JIRA_BASE_URL"]
        if p_env.get("JIRA_API_TOKEN"):
            token = p_env["JIRA_API_TOKEN"]
        if p_env.get("JIRA_USER_EMAIL"):
            email = p_env["JIRA_USER_EMAIL"]

    # Layer 3: Process environment
    if os.environ.get("JIRA_BASE_URL"):
        base_url = os.environ["JIRA_BASE_URL"]
    if os.environ.get("JIRA_API_TOKEN"):
        token = os.environ["JIRA_API_TOKEN"]
    elif os.environ.get("ATLASSIAN_API_TOKEN"):
        token = os.environ["ATLASSIAN_API_TOKEN"]
    elif token is None and os.environ.get("CONFLUENCE_API_TOKEN"):
        token = os.environ["CONFLUENCE_API_TOKEN"]
    if os.environ.get("JIRA_USER_EMAIL"):
        email = os.environ["JIRA_USER_EMAIL"]

    # Layer 4: CLI args (wins over all)
    if cli_base_url:
        base_url = cli_base_url
    if cli_token:
        token = cli_token
    if cli_email:
        email = cli_email

    # Strip trailing slash from base URL
    if base_url:
        base_url = base_url.rstrip("/")

    # Validate
    missing = []
    if not base_url:
        missing.append("JIRA_BASE_URL")
    if not token:
        missing.append("JIRA_API_TOKEN")
    if missing:
        err = {
            "error": "credentials missing",
            "missing": missing,
            "hint": (
                "Set JIRA_BASE_URL and JIRA_API_TOKEN in env or place them in "
                "~/.ai-dev-garage/secrets.env (or <project>/.ai-dev-garage/secrets.env). "
                "See ai-garage-jira README."
            ),
        }
        print(json.dumps(err), file=sys.stderr)
        sys.exit(2)

    return base_url, token, email


# ---------------------------------------------------------------------------
# Auth header
# ---------------------------------------------------------------------------

def _build_auth_header(token, email):
    """Basic auth if email is available, otherwise Bearer."""
    if email:
        pair = f"{email}:{token}"
        encoded = base64.b64encode(pair.encode()).decode()
        return f"Basic {encoded}"
    return f"Bearer {token}"


# ---------------------------------------------------------------------------
# HTTP layer
# ---------------------------------------------------------------------------

def _jira_request(method, url, auth_header, data=None, timeout=30):
    """
    Make an HTTP request to the Jira REST API.
    Returns (http_status, parsed_json_or_None).
    On error, prints JSON to stderr and exits with code 1.
    """
    headers = {
        "Authorization": auth_header,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    body = json.dumps(data).encode() if data else None

    req = urllib.request.Request(url, data=body, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status = resp.status
            raw = resp.read()
            if raw:
                return status, json.loads(raw)
            return status, None
    except urllib.error.HTTPError as e:
        status = e.code
        raw = e.read()
        response_body = None
        try:
            response_body = json.loads(raw) if raw else None
        except (json.JSONDecodeError, ValueError):
            response_body = raw.decode(errors="replace") if raw else None

        err = {"error": "API error", "http_status": status}
        if response_body:
            err["response"] = response_body
        print(json.dumps(err), file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        err = {"error": "connection failed", "detail": str(e.reason)}
        print(json.dumps(err), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        err = {"error": "connection failed", "detail": f"{type(e).__name__}: {e}"}
        print(json.dumps(err), file=sys.stderr)
        sys.exit(1)


def _resolve_timeout(args):
    """Resolve timeout: CLI arg > env var > default 30."""
    if hasattr(args, "timeout") and args.timeout is not None:
        return args.timeout
    env_val = os.environ.get("JIRA_TIMEOUT_SECONDS")
    if env_val:
        try:
            return int(env_val)
        except ValueError:
            pass
    return 30


def _resolve_common(args):
    """Resolve credentials, auth header, and timeout from parsed args."""
    project_root = getattr(args, "project_root", None) or os.environ.get("PROJECT_ROOT")
    base_url, token, email = _resolve_credentials(
        getattr(args, "base_url", None),
        getattr(args, "token", None),
        getattr(args, "email", None),
        project_root,
    )
    auth = _build_auth_header(token, email)
    timeout = _resolve_timeout(args)
    return base_url, auth, timeout


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

_DEFAULT_FETCH_FIELDS = (
    "summary,description,status,priority,issuetype,"
    "assignee,reporter,parent,created,updated,"
    "timeoriginalestimate,comment"
)


def cmd_fetch(args):
    base_url, auth, timeout = _resolve_common(args)
    key = args.key.upper()
    fields = args.fields if args.fields else _DEFAULT_FETCH_FIELDS
    url = f"{base_url}/rest/api/3/issue/{key}?fields={urllib.parse.quote(fields, safe=',')}"
    _, data = _jira_request("GET", url, auth, timeout=timeout)
    print(json.dumps(data, indent=2))
    return 0


def cmd_search(args):
    base_url, auth, timeout = _resolve_common(args)
    params = {"jql": args.jql, "maxResults": args.max_results}
    if args.fields:
        params["fields"] = args.fields
    else:
        params["fields"] = "summary,status,issuetype,assignee"
    url = f"{base_url}/rest/api/3/search/jql?{urllib.parse.urlencode(params)}"
    _, data = _jira_request("GET", url, auth, timeout=timeout)
    print(json.dumps(data, indent=2))
    return 0


def cmd_create_issue(args):
    base_url, auth, timeout = _resolve_common(args)
    payload = {
        "fields": {
            "project": {"key": args.project},
            "parent": {"key": args.parent},
            "summary": args.summary,
            "description": args.description,
            "issuetype": {"name": args.type},
        }
    }
    url = f"{base_url}/rest/api/2/issue"
    _, data = _jira_request("POST", url, auth, data=payload, timeout=timeout)
    print(json.dumps(data, indent=2))
    return 0


def cmd_get_transitions(args):
    base_url, auth, timeout = _resolve_common(args)
    key = args.key.upper()
    url = f"{base_url}/rest/api/2/issue/{key}/transitions"
    _, data = _jira_request("GET", url, auth, timeout=timeout)
    print(json.dumps(data, indent=2))
    return 0


def cmd_transition(args):
    base_url, auth, timeout = _resolve_common(args)
    key = args.key.upper()
    payload = {"transition": {"id": args.id}}
    url = f"{base_url}/rest/api/2/issue/{key}/transitions"
    status, _ = _jira_request("POST", url, auth, data=payload, timeout=timeout)
    # HTTP 204 = success (no content)
    result = {"success": True, "key": key, "transition_id": args.id}
    print(json.dumps(result, indent=2))
    return 0


def cmd_auth_test(args):
    base_url, auth, timeout = _resolve_common(args)
    url = f"{base_url}/rest/api/2/myself"
    status, data = _jira_request("GET", url, auth, timeout=timeout)
    result = {"http_status": status}
    if data:
        result["user"] = {
            "displayName": data.get("displayName"),
            "emailAddress": data.get("emailAddress"),
        }
    print(json.dumps(result, indent=2))
    return 0


# ---------------------------------------------------------------------------
# CLI parser
# ---------------------------------------------------------------------------

def _build_parser():
    # Common options shared between the top-level parser and every subparser,
    # so flags like --project-root work whether they appear before OR after
    # the subcommand name (e.g. `jira_cli.py fetch KEY --project-root \u2026`
    # and `jira_cli.py --project-root \u2026 fetch KEY` are both accepted).
    # default=SUPPRESS is critical: subparsers copy a fresh namespace back to
    # the parent, so a regular default=None would overwrite a value the user
    # passed *before* the subcommand. SUPPRESS leaves the attribute unset
    # when the flag is absent, and the cmd_* handlers use getattr(..., None).
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--base-url", dest="base_url", default=argparse.SUPPRESS,
                         help="Jira base URL (overrides env/file)")
    common.add_argument("--token", default=argparse.SUPPRESS,
                         help="API token (overrides env/file)")
    common.add_argument("--email", default=argparse.SUPPRESS,
                         help="User email for Basic auth (overrides env/file)")
    common.add_argument("--project-root", dest="project_root", default=argparse.SUPPRESS,
                         help="Project root for env file resolution")
    common.add_argument("--timeout", type=int, default=argparse.SUPPRESS,
                         help="HTTP timeout in seconds (default: 30)")

    p = argparse.ArgumentParser(
        prog="jira_cli.py",
        description="AI Dev Garage \u2014 Jira REST API CLI",
        parents=[common],
    )

    sub = p.add_subparsers(dest="subcommand")

    # fetch
    f = sub.add_parser("fetch", parents=[common],
                        help="Fetch a single Jira issue")
    f.add_argument("key", help="Jira issue key (e.g. PROJ-123)")
    f.add_argument("--fields", default=None,
                    help="Comma-separated field list")
    f.set_defaults(func=cmd_fetch)

    # search
    s = sub.add_parser("search", parents=[common],
                        help="Search issues via JQL")
    s.add_argument("--jql", required=True, help="JQL query string")
    s.add_argument("--fields", default=None,
                    help="Comma-separated field list")
    s.add_argument("--max-results", dest="max_results", type=int, default=50,
                    help="Maximum results (default: 50)")
    s.set_defaults(func=cmd_search)

    # create-issue
    ci = sub.add_parser("create-issue", parents=[common],
                         help="Create a Jira issue (typically a sub-task)")
    ci.add_argument("--project", required=True, help="Project key")
    ci.add_argument("--parent", required=True, help="Parent issue key")
    ci.add_argument("--summary", required=True, help="Issue summary")
    ci.add_argument("--description", required=True, help="Issue description")
    ci.add_argument("--type", default="Sub-task",
                     help='Issue type name (default: "Sub-task")')
    ci.set_defaults(func=cmd_create_issue)

    # get-transitions
    gt = sub.add_parser("get-transitions", parents=[common],
                         help="List available transitions for an issue")
    gt.add_argument("key", help="Jira issue key")
    gt.set_defaults(func=cmd_get_transitions)

    # transition
    t = sub.add_parser("transition", parents=[common],
                        help="Execute a transition on an issue")
    t.add_argument("key", help="Jira issue key")
    t.add_argument("--id", required=True, help="Transition ID")
    t.set_defaults(func=cmd_transition)

    # auth-test
    at = sub.add_parser("auth-test", parents=[common],
                         help="Test authentication via GET /rest/api/2/myself")
    at.set_defaults(func=cmd_auth_test)

    return p


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv=None):
    parser = _build_parser()
    args = parser.parse_args(argv)

    if not args.subcommand:
        parser.print_help()
        return 1

    try:
        return args.func(args)
    except SystemExit:
        raise
    except Exception as exc:
        print(json.dumps({"error": f"{type(exc).__name__}: {exc}"}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
