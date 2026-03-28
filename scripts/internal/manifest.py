#!/usr/bin/env python3
"""
manifest.py — AI Dev Garage YAML helper.

Replaces the Ruby helpers (extension-prefix.rb, list-enabled-extensions.rb)
and adds master manifest read/write/lock/status capabilities.

Usage:
  manifest.py list-extensions  --pipeline-root <path>
  manifest.py get-prefix       --pipeline-root <path> --ext-id <id>
  manifest.py get-version      --component-path <path>
  manifest.py write-master     --target <manifest.yaml> --pipeline-repo <path>
                               --core <version> [--ext name=version ...]
                               [--preserve-installed-at]
  manifest.py is-locked        --target <manifest.yaml> <core|ext-name>
  manifest.py lock             --target <manifest.yaml> <core|ext-name>
  manifest.py unlock           --target <manifest.yaml> <core|ext-name>
  manifest.py read-status      --target <manifest.yaml>
"""

import sys
import os
import argparse
from datetime import datetime, timezone

try:
    import yaml
except ImportError:
    print("Error: PyYAML is not installed. Run: pip3 install pyyaml", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# YAML helpers
# ---------------------------------------------------------------------------

def load_yaml(path):
    if not os.path.isfile(path):
        return {}
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}


def save_yaml(path, data):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w") as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_list_extensions(args):
    """Print enabled extension IDs (one per line) from garage.yaml."""
    garage_yaml = os.path.join(args.pipeline_root, "garage.yaml")
    cfg = load_yaml(garage_yaml)
    extensions = cfg.get("extensions") or {}
    for name, opts in extensions.items():
        if isinstance(opts, dict) and opts.get("enabled") is True:
            print(name)


def cmd_get_prefix(args):
    """Print the 'name' field from extensions/<id>/manifest.yaml."""
    manifest_path = os.path.join(args.pipeline_root, "extensions", args.ext_id, "manifest.yaml")
    if not os.path.isfile(manifest_path):
        print(f"Error: manifest.yaml not found: {manifest_path}", file=sys.stderr)
        sys.exit(1)
    data = load_yaml(manifest_path)
    name = data.get("name", "").strip()
    if not name:
        print(f"Error: manifest.yaml missing 'name': {manifest_path}", file=sys.stderr)
        sys.exit(1)
    print(name, end="")


def cmd_get_version(args):
    """Print the 'version' field from a component's manifest.yaml."""
    manifest_path = os.path.join(args.component_path, "manifest.yaml")
    if not os.path.isfile(manifest_path):
        print(f"Error: manifest.yaml not found: {manifest_path}", file=sys.stderr)
        sys.exit(1)
    data = load_yaml(manifest_path)
    version = data.get("version", "").strip()
    if not version:
        print(f"Error: manifest.yaml missing 'version': {manifest_path}", file=sys.stderr)
        sys.exit(1)
    print(version, end="")


def cmd_write_master(args):
    """Create or update the master manifest at --target."""
    target = args.target
    existing = load_yaml(target) if os.path.isfile(target) else {}

    now = now_iso()
    installed_at = existing.get("installed_at", now) if args.preserve_installed_at else now

    # Build extensions map preserving existing lock state
    ext_data = {}
    for pair in (args.ext or []):
        name, _, version = pair.partition("=")
        name = name.strip()
        version = version.strip() or "unknown"
        prev = (existing.get("extensions") or {}).get(name, {})
        ext_data[name] = {
            "version": version,
            "locked": bool(prev.get("locked", False)),
        }

    # Preserve lock state for core
    prev_core = existing.get("core", {})
    core_locked = bool(prev_core.get("locked", False))

    data = {
        "pipeline_repo": args.pipeline_repo,
        "installed_at": installed_at,
        "updated_at": now,
        "core": {
            "version": args.core,
            "locked": core_locked,
        },
    }
    if ext_data:
        data["extensions"] = ext_data

    save_yaml(target, data)


def _get_component(target, component):
    """Return (data, comp_dict, is_extension). Exits on error."""
    if not os.path.isfile(target):
        print(f"Error: master manifest not found: {target}", file=sys.stderr)
        sys.exit(1)
    data = load_yaml(target)
    if component == "core":
        comp = data.get("core")
        if not isinstance(comp, dict):
            print("Error: 'core' section missing from master manifest.", file=sys.stderr)
            sys.exit(1)
        return data, comp, False
    else:
        exts = data.get("extensions") or {}
        comp = exts.get(component)
        if not isinstance(comp, dict):
            print(f"Error: extension '{component}' not found in master manifest.", file=sys.stderr)
            sys.exit(1)
        return data, comp, True


def cmd_is_locked(args):
    """Exit 0 if locked, 1 if not."""
    data, comp, is_ext = _get_component(args.target, args.component)
    sys.exit(0 if comp.get("locked") else 1)


def cmd_lock(args):
    """Set locked=true for the given component."""
    data, comp, is_ext = _get_component(args.target, args.component)
    comp["locked"] = True
    save_yaml(args.target, data)
    print(f"Locked: {args.component}")


def cmd_unlock(args):
    """Set locked=false for the given component."""
    data, comp, is_ext = _get_component(args.target, args.component)
    comp["locked"] = False
    save_yaml(args.target, data)
    print(f"Unlocked: {args.component}")


def cmd_read_status(args):
    """Print a human-readable status table from the master manifest."""
    if not os.path.isfile(args.target):
        print(f"Error: master manifest not found: {args.target}", file=sys.stderr)
        sys.exit(1)
    data = load_yaml(args.target)

    pipeline_repo = data.get("pipeline_repo", "unknown")
    installed_at  = data.get("installed_at", "—")
    updated_at    = data.get("updated_at", "—")

    rows = []
    core = data.get("core") or {}
    rows.append(("core", core.get("version", "—"), "locked" if core.get("locked") else ""))

    for name, info in (data.get("extensions") or {}).items():
        locked = "locked" if (isinstance(info, dict) and info.get("locked")) else ""
        version = info.get("version", "—") if isinstance(info, dict) else "—"
        rows.append((name, version, locked))

    # Print (shell consumers parse this output)
    print(f"pipeline_repo={pipeline_repo}")
    print(f"installed_at={installed_at}")
    print(f"updated_at={updated_at}")
    print("---")
    for name, version, locked in rows:
        print(f"{name}\t{version}\t{locked}")


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        prog="manifest.py",
        description="AI Dev Garage YAML helper.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # list-extensions
    p = sub.add_parser("list-extensions", help="Print enabled extension IDs from garage.yaml")
    p.add_argument("--pipeline-root", required=True)

    # get-prefix
    p = sub.add_parser("get-prefix", help="Print name from extensions/<id>/manifest.yaml")
    p.add_argument("--pipeline-root", required=True)
    p.add_argument("--ext-id", required=True)

    # get-version
    p = sub.add_parser("get-version", help="Print version from a component manifest.yaml")
    p.add_argument("--component-path", required=True)

    # write-master
    p = sub.add_parser("write-master", help="Create or update the master manifest")
    p.add_argument("--target", required=True)
    p.add_argument("--pipeline-repo", required=True)
    p.add_argument("--core", required=True, help="Core version string")
    p.add_argument("--ext", action="append", metavar="name=version",
                   help="Extension entry (repeat for multiple)")
    p.add_argument("--preserve-installed-at", action="store_true",
                   help="Keep existing installed_at (for updates)")

    # is-locked
    p = sub.add_parser("is-locked", help="Exit 0 if component is locked, 1 otherwise")
    p.add_argument("--target", required=True)
    p.add_argument("component")

    # lock
    p = sub.add_parser("lock", help="Lock a component against updates")
    p.add_argument("--target", required=True)
    p.add_argument("component")

    # unlock
    p = sub.add_parser("unlock", help="Unlock a previously locked component")
    p.add_argument("--target", required=True)
    p.add_argument("component")

    # read-status
    p = sub.add_parser("read-status", help="Print human-readable status from master manifest")
    p.add_argument("--target", required=True)

    args = parser.parse_args()

    dispatch = {
        "list-extensions": cmd_list_extensions,
        "get-prefix":      cmd_get_prefix,
        "get-version":     cmd_get_version,
        "write-master":    cmd_write_master,
        "is-locked":       cmd_is_locked,
        "lock":            cmd_lock,
        "unlock":          cmd_unlock,
        "read-status":     cmd_read_status,
    }
    dispatch[args.command](args)


if __name__ == "__main__":
    main()
