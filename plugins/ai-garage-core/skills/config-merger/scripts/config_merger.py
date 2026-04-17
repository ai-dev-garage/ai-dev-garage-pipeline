#!/usr/bin/env python3
"""
AI Dev Garage — unified config helper.

Subcommands: get, set, merge-fragment, validate, path.

Reads and writes the canonical YAML config file with comment + unknown-key
preservation. Callers are configure/doctor commands and plugin skills that
need deterministic config operations without hand-editing YAML.

Exit codes:
  0 — success
  1 — error (see stderr)
  2 — miss (get: key not present)

See SKILL.md and references/REFERENCE.md in the sibling directories.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any

# ---- YAML backend selection ----------------------------------------------

_YAML_BACKEND = None
_YAML_PRESERVES_COMMENTS = False


def _load_yaml_backend() -> None:
    global _YAML_BACKEND, _YAML_PRESERVES_COMMENTS
    try:
        from ruamel.yaml import YAML  # type: ignore
        y = YAML()
        y.preserve_quotes = True
        y.indent(mapping=2, sequence=4, offset=2)
        _YAML_BACKEND = ("ruamel", y)
        _YAML_PRESERVES_COMMENTS = True
        return
    except ImportError:
        pass
    try:
        import yaml  # type: ignore
        _YAML_BACKEND = ("pyyaml", yaml)
        _YAML_PRESERVES_COMMENTS = False
        print(
            "config-merger: ruamel.yaml not installed; falling back to PyYAML "
            "(comments in the config file may be reformatted on write). "
            "Install ruamel.yaml to preserve comments: pip install ruamel.yaml",
            file=sys.stderr,
        )
        return
    except ImportError:
        pass
    print(
        "config-merger: no YAML library available. Install one of:\n"
        "  pip install ruamel.yaml   # preferred (preserves comments)\n"
        "  pip install pyyaml        # fallback",
        file=sys.stderr,
    )
    sys.exit(1)


def _yaml_load(path: Path) -> Any:
    name, backend = _YAML_BACKEND
    with path.open("r", encoding="utf-8") as f:
        text = f.read()
    if not text.strip():
        return {}
    if name == "ruamel":
        return backend.load(text) or {}
    return backend.safe_load(text) or {}


def _yaml_loads(text: str) -> Any:
    name, backend = _YAML_BACKEND
    if not text.strip():
        return None
    if name == "ruamel":
        return backend.load(text)
    return backend.safe_load(text)


def _yaml_dump(data: Any, path: Path) -> None:
    name, backend = _YAML_BACKEND
    tmp = tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=str(path.parent),
        prefix=path.name + ".", suffix=".tmp", delete=False,
    )
    try:
        if name == "ruamel":
            backend.dump(data, tmp)
        else:
            backend.safe_dump(data, tmp, sort_keys=False, default_flow_style=False)
        tmp.flush()
        os.fsync(tmp.fileno())
        tmp.close()
        os.replace(tmp.name, path)
    except Exception:
        try:
            os.unlink(tmp.name)
        except OSError:
            pass
        raise

# ---- Path resolution -----------------------------------------------------


def _project_root(cli_root: str | None) -> Path | None:
    if cli_root:
        return Path(cli_root).expanduser().resolve()
    env = os.environ.get("PROJECT_ROOT")
    if env:
        return Path(env).expanduser().resolve()
    # Fallback: assume current working directory if it looks like a project.
    cwd = Path.cwd()
    if (cwd / ".ai-dev-garage").exists() or (cwd / ".git").exists():
        return cwd
    return None


def _canonical_path(scope: str, project_root: Path | None, cli_file: str | None) -> Path:
    """Return the canonical path for (scope, project_root), regardless of
    whether it exists on disk. CLI file and AI_GARAGE_CONFIG env overrides
    short-circuit the lookup."""
    if cli_file:
        return Path(cli_file).expanduser().resolve()

    env_override = os.environ.get("AI_GARAGE_CONFIG")
    if env_override:
        return Path(env_override).expanduser().resolve()

    if scope == "global":
        return Path.home() / ".ai-dev-garage" / "config.yaml"

    if project_root is None:
        print("config-merger: project root not found. Set PROJECT_ROOT or pass --project-root.", file=sys.stderr)
        sys.exit(1)
    return project_root / ".ai-dev-garage" / "project-config.yaml"


def _legacy_path(scope: str, project_root: Path | None) -> Path | None:
    """Return the legacy fallback path, or None when no legacy location exists
    for the given scope."""
    if scope == "global":
        return Path.home() / ".config" / "ai-garage" / "config.yaml"
    if project_root is None:
        return None
    return project_root / ".ai-dev-garage" / "config.yaml"


def _resolve_path(scope: str, project_root: Path | None, cli_file: str | None) -> tuple[Path, bool]:
    """
    Resolve the config file path to read.

    Returns (path, is_legacy). is_legacy == True means the path was picked from
    a legacy location; callers should treat it as read-only and migrate writes
    to the canonical path.
    """
    canonical = _canonical_path(scope, project_root, cli_file)

    # Explicit overrides skip legacy fallback — trust the caller.
    if cli_file or os.environ.get("AI_GARAGE_CONFIG"):
        return canonical, False

    if canonical.exists():
        return canonical, False

    legacy = _legacy_path(scope, project_root)
    if legacy is not None and legacy.exists():
        print(
            f"config-merger: reading legacy config at {legacy}. "
            f"Migrate to {canonical} — writes will target the canonical path.",
            file=sys.stderr,
        )
        return legacy, True
    return canonical, False

# ---- Key-path operations -------------------------------------------------


def _split_keypath(kp: str) -> list[tuple[str, int | None]]:
    parts: list[tuple[str, int | None]] = []
    for chunk in kp.split("."):
        if "[" in chunk and chunk.endswith("]"):
            name, idx = chunk[:-1].split("[", 1)
            parts.append((name, int(idx)))
        else:
            parts.append((chunk, None))
    return parts


def _get_keypath(data: Any, kp: str) -> Any:
    cur: Any = data
    for name, idx in _split_keypath(kp):
        if cur is None:
            return None
        if not isinstance(cur, dict) or name not in cur:
            return None
        cur = cur[name]
        if idx is not None:
            if not isinstance(cur, list) or idx >= len(cur):
                return None
            cur = cur[idx]
    return cur


def _set_keypath(data: Any, kp: str, value: Any) -> Any:
    if data is None:
        data = {}
    parts = _split_keypath(kp)
    cur = data
    for i, (name, idx) in enumerate(parts):
        is_last = i == len(parts) - 1
        if is_last and idx is None:
            cur[name] = value
            return data
        if name not in cur or not isinstance(cur[name], (dict, list)):
            cur[name] = {} if idx is None else []
        nxt = cur[name]
        if idx is not None:
            while len(nxt) <= idx:
                nxt.append(None)
            if is_last:
                nxt[idx] = value
                return data
            if not isinstance(nxt[idx], dict):
                nxt[idx] = {}
            cur = nxt[idx]
        else:
            cur = nxt
    return data


def _deep_merge(base: Any, overlay: Any) -> Any:
    """Deep-merge `overlay` into `base`. Existing keys in `base` win; `overlay`
    only fills keys missing from `base`. This is the semantics needed for
    plugin/template fragments: re-applying a template must never clobber
    values a user has already customized."""
    if isinstance(base, dict) and isinstance(overlay, dict):
        out = dict(base)
        for k, v in overlay.items():
            if k in out:
                out[k] = _deep_merge(out[k], v)
            else:
                out[k] = v
        return out
    if base is None:
        return overlay
    return base

# ---- Validation ----------------------------------------------------------


_MODEL_VALUES = {"haiku", "sonnet", "opus", "inherit"}


def _validate(data: Any) -> list[dict]:
    errors: list[dict] = []

    def err(key: str, msg: str) -> None:
        errors.append({"key": key, "message": msg})

    def val(key: str) -> Any:
        return _get_keypath(data, key)

    name = val("project.name")
    if name is not None and not (isinstance(name, str) and name.strip()):
        err("project.name", "must be a non-empty string")

    stack = val("project.stack")
    if stack is not None:
        if not isinstance(stack, list) or not all(isinstance(s, str) and s == s.lower() for s in stack):
            err("project.stack", "must be a list of lowercase identifiers")

    docs_path = val("project.docs-path")
    if docs_path:
        if not isinstance(docs_path, str) or not Path(docs_path).expanduser().exists():
            err("project.docs-path", f"path does not exist: {docs_path}")

    for k in ("project.build-command", "project.test-command", "project.base-branch", "project.branch-prefix"):
        v = val(k)
        if v is not None and not (isinstance(v, str) and v.strip()):
            err(k, "must be a non-empty string")

    for k in ("models.low", "models.medium", "models.high"):
        v = val(k)
        if v is None:
            continue
        if not isinstance(v, str) or (v not in _MODEL_VALUES and "/" not in v and "-" not in v):
            err(k, f"must be one of {sorted(_MODEL_VALUES)} or a full model ID")

    base_url = val("integrations.jira.base-url")
    if base_url is not None and base_url != "":
        if not isinstance(base_url, str) or not base_url.startswith("https://"):
            err("integrations.jira.base-url", "must start with https://")

    sp = val("integrations.jira.sync-phases")
    if sp is not None and not isinstance(sp, bool):
        err("integrations.jira.sync-phases", "must be a boolean")

    for tk in (
        "integrations.jira.transitions.phase-started",
        "integrations.jira.transitions.phase-implemented",
        "integrations.jira.transitions.review-started",
        "integrations.jira.transitions.phase-ready",
    ):
        v = val(tk)
        if v is not None and not isinstance(v, str):
            err(tk, "must be a string or null")

    ndbid = val("integrations.assistant.notion-database-id")
    if ndbid is not None and ndbid != "":
        if not isinstance(ndbid, str) or not ndbid.strip():
            err("integrations.assistant.notion-database-id", "must be a non-empty string")

    for k in (
        "integrations.assistant.notion-mcp-connector",
        "integrations.assistant.notion-parent-page-id",
        "integrations.assistant.session-prefix",
    ):
        v = val(k)
        if v is not None and not (isinstance(v, str) and v.strip()):
            err(k, "must be a non-empty string or null")

    tags = val("integrations.assistant.default-tags")
    if tags is not None:
        if not isinstance(tags, list) or not all(isinstance(s, str) and s.strip() for s in tags):
            err("integrations.assistant.default-tags", "must be a list of non-empty strings")

    sources = val("integrations.architect.doc-sources")
    if sources is not None:
        if not isinstance(sources, list):
            err("integrations.architect.doc-sources", "must be a list")
        else:
            for i, s in enumerate(sources):
                if not isinstance(s, dict):
                    err(f"integrations.architect.doc-sources[{i}]", "must be a mapping")
                    continue
                t = s.get("type")
                if t not in ("local", "github", "confluence"):
                    err(f"integrations.architect.doc-sources[{i}].type", "must be one of: local, github, confluence")
                if t == "local":
                    p = s.get("path")
                    if not isinstance(p, str) or not p.strip():
                        err(f"integrations.architect.doc-sources[{i}].path", "must be a non-empty string")

    fmt = val("integrations.architect.default-output.format")
    if fmt is not None and fmt not in ("adoc", "md"):
        err("integrations.architect.default-output.format", "must be 'adoc' or 'md' or null")

    for k in (
        "integrations.architect.default-output.adr-path",
        "integrations.architect.default-output.diagram-path",
        "integrations.architect.verification-command",
    ):
        v = val(k)
        if v is not None and not (isinstance(v, str) and v.strip()):
            err(k, "must be a non-empty string or null")

    installed = val("plugins.installed")
    if installed is not None:
        if not isinstance(installed, list) or not all(isinstance(s, str) and s.strip() for s in installed):
            err("plugins.installed", "must be a list of non-empty plugin-name strings")

    return errors

# ---- Command implementations --------------------------------------------


def cmd_get(args) -> int:
    path, _ = _resolve_path(args.scope, _project_root(args.project_root), args.file)
    if not path.exists():
        return 2
    data = _yaml_load(path)
    value = _get_keypath(data, args.key_path)
    if value is None and not _contains_keypath(data, args.key_path):
        return 2
    if isinstance(value, (dict, list)):
        print(json.dumps(value, default=str))
    elif value is None:
        print("null")
    elif isinstance(value, bool):
        print("true" if value else "false")
    else:
        print(value)
    return 0


def _contains_keypath(data: Any, kp: str) -> bool:
    cur: Any = data
    for name, idx in _split_keypath(kp):
        if not isinstance(cur, dict) or name not in cur:
            return False
        cur = cur[name]
        if idx is not None:
            if not isinstance(cur, list) or idx >= len(cur):
                return False
            cur = cur[idx]
    return True


def cmd_set(args) -> int:
    read_path, is_legacy = _resolve_path(args.scope, _project_root(args.project_root), args.file)
    write_path = _canonical_path(args.scope, _project_root(args.project_root), args.file)
    if is_legacy:
        print(
            f"config-merger: migrating write target to canonical path {write_path}",
            file=sys.stderr,
        )
    write_path.parent.mkdir(parents=True, exist_ok=True)
    data = _yaml_load(read_path) if read_path.exists() else {}
    if args.raw_string:
        parsed: Any = args.value
    else:
        parsed = _yaml_loads(args.value)
    data = _set_keypath(data, args.key_path, parsed)
    _yaml_dump(data, write_path)
    return 0


def cmd_merge_fragment(args) -> int:
    read_path, is_legacy = _resolve_path(args.scope, _project_root(args.project_root), args.file)
    write_path = _canonical_path(args.scope, _project_root(args.project_root), args.file)
    if is_legacy:
        print(
            f"config-merger: migrating write target to canonical path {write_path}",
            file=sys.stderr,
        )
    write_path.parent.mkdir(parents=True, exist_ok=True)
    fragment_path = Path(args.fragment_file).expanduser().resolve()
    if not fragment_path.exists():
        print(f"config-merger: fragment not found: {fragment_path}", file=sys.stderr)
        return 1
    fragment = _yaml_load(fragment_path)
    base = _yaml_load(read_path) if read_path.exists() else {}
    merged = _deep_merge(base, fragment)
    _yaml_dump(merged, write_path)
    return 0


def cmd_add_to_list(args) -> int:
    """Idempotently append `value` to the list at `key_path`. Creates the list
    (and any missing parent maps) if absent. No-op if `value` is already in the
    list. Value is parsed as YAML so scalars, strings, and structured entries
    all work; use `--raw-string` to force a literal string."""
    read_path, is_legacy = _resolve_path(args.scope, _project_root(args.project_root), args.file)
    write_path = _canonical_path(args.scope, _project_root(args.project_root), args.file)
    if is_legacy:
        print(
            f"config-merger: migrating write target to canonical path {write_path}",
            file=sys.stderr,
        )
    write_path.parent.mkdir(parents=True, exist_ok=True)
    data = _yaml_load(read_path) if read_path.exists() else {}

    if args.raw_string:
        parsed: Any = args.value
    else:
        parsed = _yaml_loads(args.value)

    existing = _get_keypath(data, args.key_path)
    if existing is None:
        new_list = [parsed]
    elif isinstance(existing, list):
        if parsed in existing:
            return 0  # idempotent no-op
        new_list = list(existing) + [parsed]
    else:
        print(
            f"config-merger: cannot add-to-list at '{args.key_path}' — existing value is not a list "
            f"(type={type(existing).__name__}).",
            file=sys.stderr,
        )
        return 1

    data = _set_keypath(data, args.key_path, new_list)
    _yaml_dump(data, write_path)
    return 0


def cmd_validate(args) -> int:
    path, _ = _resolve_path(args.scope, _project_root(args.project_root), args.file)
    data = _yaml_load(path) if path.exists() else {}
    errors = _validate(data)
    print(json.dumps({"ok": not errors, "errors": errors}))
    return 0


def cmd_path(args) -> int:
    # Always print the canonical path so callers know where writes will land,
    # even if only a legacy file currently exists on disk.
    path = _canonical_path(args.scope, _project_root(args.project_root), args.file)
    print(str(path))
    return 0

# ---- CLI -----------------------------------------------------------------


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="AI Dev Garage config helper")
    p.add_argument("--file", help="Override target file path.")
    p.add_argument("--project-root", help="Override PROJECT_ROOT.")
    p.add_argument("--scope", choices=["project", "global"], default="project")
    p.add_argument("--quiet", action="store_true")

    # Shared parent so common flags (--scope, --file, --project-root, --quiet)
    # are accepted both BEFORE and AFTER the subcommand.  LLM callers
    # frequently write `path --scope project` instead of `--scope project path`.
    # SUPPRESS default so subparser values only appear when explicitly passed,
    # never overwriting values the main parser already set.
    _shared = argparse.ArgumentParser(add_help=False)
    _shared.add_argument("--file", default=argparse.SUPPRESS, help=argparse.SUPPRESS)
    _shared.add_argument("--project-root", default=argparse.SUPPRESS, help=argparse.SUPPRESS)
    _shared.add_argument("--scope", choices=["project", "global"], default=argparse.SUPPRESS)
    _shared.add_argument("--quiet", action="store_true", default=argparse.SUPPRESS)

    sub = p.add_subparsers(dest="subcommand", required=True)

    g = sub.add_parser("get", parents=[_shared])
    g.add_argument("key_path")
    g.set_defaults(func=cmd_get)

    s = sub.add_parser("set", parents=[_shared])
    s.add_argument("key_path")
    s.add_argument("value")
    s.add_argument("--raw-string", action="store_true", help="Force string interpretation of value.")
    s.set_defaults(func=cmd_set)

    m = sub.add_parser("merge-fragment", parents=[_shared])
    m.add_argument("fragment_file")
    m.set_defaults(func=cmd_merge_fragment)

    a = sub.add_parser("add-to-list", parents=[_shared], help="Idempotent append to a YAML list.")
    a.add_argument("key_path")
    a.add_argument("value")
    a.add_argument("--raw-string", action="store_true", help="Force string interpretation of value.")
    a.set_defaults(func=cmd_add_to_list)

    v = sub.add_parser("validate", parents=[_shared])
    v.set_defaults(func=cmd_validate)

    pa = sub.add_parser("path", parents=[_shared])
    pa.set_defaults(func=cmd_path)

    return p


def main(argv: list[str] | None = None) -> int:
    _load_yaml_backend()
    parser = _build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except SystemExit:
        raise
    except Exception as exc:
        print(f"config-merger: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
