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
  manifest.py list-installed-extensions --target <manifest.yaml>
  manifest.py custom-add       --target <manifest.yaml> --category <cat> --entry <name>
  manifest.py custom-remove    --target <manifest.yaml> --category <cat> --entry <name>
  manifest.py custom-list      --target <manifest.yaml>
  manifest.py doctor-check     --target <manifest.yaml> [--pipeline-root <path>]
"""

import sys
import os
import glob
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


CUSTOM_CATEGORIES = ("agents", "commands", "rules", "memory", "skills")


def _normalize_custom_block(raw):
    """Return a clean custom: dict with list values, or None if empty."""
    if not isinstance(raw, dict):
        return None
    out = {}
    for cat in CUSTOM_CATEGORIES:
        v = raw.get(cat)
        if not v:
            continue
        if isinstance(v, str):
            items = [v]
        elif isinstance(v, list):
            items = v
        else:
            continue
        cleaned = []
        for x in items:
            if isinstance(x, str) and x.strip():
                cleaned.append(x.strip())
        if cleaned:
            out[cat] = cleaned
    return out if out else None


def _bundle_root_from_manifest_path(target):
    return os.path.dirname(os.path.abspath(target))


def _expected_asset_sets(pipeline_root, ext_ids):
    """Return dict category -> set of expected keys (basename or commands subpath)."""
    exp = {c: set() for c in CUSTOM_CATEGORIES}

    def add_core():
        core = os.path.join(pipeline_root, "core")
        for f in glob.glob(os.path.join(core, "agents", "*.md")):
            if os.path.isfile(f):
                exp["agents"].add(os.path.basename(f))
        for f in glob.glob(os.path.join(core, "rules", "*")):
            if os.path.isfile(f) and f.endswith((".md", ".mdc")):
                exp["rules"].add(os.path.basename(f))
        for f in glob.glob(os.path.join(core, "memory", "*.md")):
            if os.path.isfile(f):
                exp["memory"].add(os.path.basename(f))
        cdir = os.path.join(core, "commands")
        if os.path.isdir(cdir):
            for f in glob.glob(os.path.join(cdir, "*.md")):
                if os.path.isfile(f):
                    exp["commands"].add(os.path.basename(f))
            adg = os.path.join(cdir, "ai-dev-garage")
            if os.path.isdir(adg):
                for f in glob.glob(os.path.join(adg, "*.md")):
                    if os.path.isfile(f):
                        exp["commands"].add("ai-dev-garage/" + os.path.basename(f))
        sk = os.path.join(core, "skills")
        if os.path.isdir(sk):
            for name in os.listdir(sk):
                p = os.path.join(sk, name)
                if os.path.isdir(p):
                    exp["skills"].add(name)

    def add_extension(ext_id):
        ext = os.path.join(pipeline_root, "extensions", ext_id)
        if not os.path.isdir(ext):
            return
        for f in glob.glob(os.path.join(ext, "agents", "*.md")):
            if os.path.isfile(f):
                exp["agents"].add(os.path.basename(f))
        for f in glob.glob(os.path.join(ext, "rules", "*")):
            if os.path.isfile(f) and f.endswith((".md", ".mdc")):
                exp["rules"].add(os.path.basename(f))
        for f in glob.glob(os.path.join(ext, "memory", "*.md")):
            if os.path.isfile(f):
                exp["memory"].add(os.path.basename(f))
        cdir = os.path.join(ext, "commands")
        if os.path.isdir(cdir):
            for f in glob.glob(os.path.join(cdir, "*.md")):
                if os.path.isfile(f):
                    exp["commands"].add(os.path.basename(f))
        sk = os.path.join(ext, "skills")
        if os.path.isdir(sk):
            for name in os.listdir(sk):
                p = os.path.join(sk, name)
                if os.path.isdir(p):
                    exp["skills"].add(name)

    add_core()
    for eid in ext_ids:
        add_extension(eid)
    return exp


def _disk_asset_sets(bundle_root):
    """Scan runtime bundle on disk."""
    disk = {c: set() for c in CUSTOM_CATEGORIES}
    if not os.path.isdir(bundle_root):
        return disk

    agents = os.path.join(bundle_root, "agents")
    if os.path.isdir(agents):
        for f in glob.glob(os.path.join(agents, "*.md")):
            if os.path.isfile(f):
                disk["agents"].add(os.path.basename(f))

    rules = os.path.join(bundle_root, "rules")
    if os.path.isdir(rules):
        for f in glob.glob(os.path.join(rules, "*")):
            if os.path.isfile(f) and f.endswith((".md", ".mdc")):
                disk["rules"].add(os.path.basename(f))

    mem = os.path.join(bundle_root, "memory")
    if os.path.isdir(mem):
        for f in glob.glob(os.path.join(mem, "*.md")):
            if os.path.isfile(f):
                disk["memory"].add(os.path.basename(f))

    cdir = os.path.join(bundle_root, "commands")
    if os.path.isdir(cdir):
        for f in glob.glob(os.path.join(cdir, "*.md")):
            if os.path.isfile(f):
                disk["commands"].add(os.path.basename(f))
        adg = os.path.join(cdir, "ai-dev-garage")
        if os.path.isdir(adg):
            for f in glob.glob(os.path.join(adg, "*.md")):
                if os.path.isfile(f):
                    disk["commands"].add("ai-dev-garage/" + os.path.basename(f))

    sk = os.path.join(bundle_root, "skills")
    if os.path.isdir(sk):
        for name in os.listdir(sk):
            p = os.path.join(sk, name)
            if os.path.isdir(p):
                disk["skills"].add(name)

    return disk


def _custom_sets(custom_block):
    sets = {c: set() for c in CUSTOM_CATEGORIES}
    block = _normalize_custom_block(custom_block) or {}
    for cat in CUSTOM_CATEGORIES:
        for x in block.get(cat) or []:
            sets[cat].add(x)
    return sets


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_list_extensions(args):
    """Print extension IDs marked enabled in garage.yaml (catalog / docs only)."""
    garage_yaml = os.path.join(args.pipeline_root, "garage.yaml")
    cfg = load_yaml(garage_yaml)
    extensions = cfg.get("extensions") or {}
    for name, opts in extensions.items():
        if isinstance(opts, dict) and opts.get("enabled") is True:
            print(name)


def cmd_list_installed_extensions(args):
    """Print extension IDs present in the master manifest (one per line)."""
    if not os.path.isfile(args.target):
        return
    data = load_yaml(args.target)
    for name in sorted((data.get("extensions") or {}).keys()):
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
    """Create or update the master manifest at --target.

    Extension entries are merged: existing manifest extensions are kept unless this run
    passes --ext for an ID (then version is refreshed; lock state preserved per ID).
    A partial ``garage install --ext foo`` therefore adds/refreshes ``foo`` without removing
    other installed extensions. Omitting ``--ext`` entirely does not drop extension rows.
    """
    target = args.target
    existing = load_yaml(target) if os.path.isfile(target) else {}

    now = now_iso()
    installed_at = existing.get("installed_at", now) if args.preserve_installed_at else now

    # Seed from existing manifest so we never wipe unrelated extension rows on partial install.
    ext_data = {}
    for name, info in (existing.get("extensions") or {}).items():
        if not isinstance(info, dict):
            continue
        ext_data[name] = {
            "version": (info.get("version") or "unknown") or "unknown",
            "locked": bool(info.get("locked", False)),
        }

    for pair in (args.ext or []):
        name, _, version = pair.partition("=")
        name = name.strip()
        version = (version.strip() or "unknown")
        prev = (existing.get("extensions") or {}).get(name, {})
        if not isinstance(prev, dict):
            prev = {}
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

    preserved = _normalize_custom_block(existing.get("custom"))
    if preserved:
        data["custom"] = preserved

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


def cmd_custom_add(args):
    if args.category not in CUSTOM_CATEGORIES:
        print(f"Error: category must be one of: {', '.join(CUSTOM_CATEGORIES)}", file=sys.stderr)
        sys.exit(1)
    bundle = _bundle_root_from_manifest_path(args.target)
    entry = args.entry.strip()
    if not entry:
        print("Error: --entry is required.", file=sys.stderr)
        sys.exit(1)

    if args.category == "skills":
        path = os.path.join(bundle, "skills", entry)
        if not os.path.isdir(path):
            print(f"Error: skill directory not found: {path}", file=sys.stderr)
            sys.exit(1)
    elif args.category == "commands":
        if "/" in entry:
            sub, _, base = entry.partition("/")
            if sub != "ai-dev-garage" or "/" in base:
                print("Error: commands entry must be basename.md or ai-dev-garage/basename.md", file=sys.stderr)
                sys.exit(1)
            path = os.path.join(bundle, "commands", sub, base)
        else:
            path = os.path.join(bundle, "commands", entry)
        if not os.path.isfile(path):
            print(f"Error: command file not found: {path}", file=sys.stderr)
            sys.exit(1)
    else:
        path = os.path.join(bundle, args.category, entry)
        if not os.path.isfile(path):
            print(f"Error: file not found: {path}", file=sys.stderr)
            sys.exit(1)

    data = load_yaml(args.target) if os.path.isfile(args.target) else {}
    custom = dict(data.get("custom") or {})
    lst = list(custom.get(args.category) or [])
    if entry not in lst:
        lst.append(entry)
        custom[args.category] = lst
    norm = _normalize_custom_block(custom)
    if norm:
        data["custom"] = norm
    save_yaml(args.target, data)
    print(f"Registered custom {args.category}: {entry}")


def cmd_custom_remove(args):
    if args.category not in CUSTOM_CATEGORIES:
        print(f"Error: category must be one of: {', '.join(CUSTOM_CATEGORIES)}", file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(args.target):
        print(f"Error: manifest not found: {args.target}", file=sys.stderr)
        sys.exit(1)
    entry = args.entry.strip()
    data = load_yaml(args.target)
    custom = dict(data.get("custom") or {})
    lst = [x for x in (custom.get(args.category) or []) if x != entry]
    if lst:
        custom[args.category] = lst
    else:
        custom.pop(args.category, None)
    norm = _normalize_custom_block(custom)
    if norm:
        data["custom"] = norm
    else:
        data.pop("custom", None)
    save_yaml(args.target, data)
    print(f"Removed custom {args.category}: {entry}")


def cmd_custom_list(args):
    if not os.path.isfile(args.target):
        print(f"Error: manifest not found: {args.target}", file=sys.stderr)
        sys.exit(1)
    data = load_yaml(args.target)
    norm = _normalize_custom_block(data.get("custom"))
    if not norm:
        print("(no custom entries)")
        return
    for cat in CUSTOM_CATEGORIES:
        for x in norm.get(cat) or []:
            print(f"{cat}\t{x}")


def cmd_doctor_check(args):
    if not os.path.isfile(args.target):
        print(f"Error: manifest not found: {args.target}", file=sys.stderr)
        sys.exit(1)
    data = load_yaml(args.target)
    pipeline_root = args.pipeline_root or data.get("pipeline_repo") or ""
    pipeline_root = os.path.abspath(os.path.expanduser(pipeline_root))
    if not os.path.isdir(pipeline_root):
        print(f"Error: pipeline root not found: {pipeline_root}", file=sys.stderr)
        sys.exit(1)

    ext_ids = sorted((data.get("extensions") or {}).keys())
    expected = _expected_asset_sets(pipeline_root, ext_ids)
    bundle = _bundle_root_from_manifest_path(args.target)
    disk = _disk_asset_sets(bundle)
    custom_s = _custom_sets(data.get("custom"))

    untracked_count = 0
    for cat in CUSTOM_CATEGORIES:
        exp = expected[cat]
        dsk = disk[cat]
        cust = custom_s[cat]
        untracked = dsk - exp - cust
        for u in sorted(untracked):
            print(f"UNTRACKED\t{cat}\t{u}")
            untracked_count += 1
        missing_c = cust - dsk
        for m in sorted(missing_c):
            print(f"CUSTOM_MISSING\t{cat}\t{m}")
        missing_e = exp - dsk
        for m in sorted(missing_e):
            print(f"MISSING_EXPECTED\t{cat}\t{m}")

    if untracked_count == 0:
        print("OK\tno untracked paths (see other lines for missing/custom issues)")
    sys.exit(1 if getattr(args, "strict", False) and untracked_count > 0 else 0)


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
    p = sub.add_parser("list-extensions", help="Print extension IDs with enabled: true in garage.yaml")
    p.add_argument("--pipeline-root", required=True)

    # list-installed-extensions
    p = sub.add_parser("list-installed-extensions", help="Print extension IDs from a master manifest")
    p.add_argument("--target", required=True)

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

    # custom-add
    p = sub.add_parser("custom-add", help="Append an entry to manifest custom: (validates path on disk)")
    p.add_argument("--target", required=True)
    p.add_argument("--category", required=True, choices=list(CUSTOM_CATEGORIES))
    p.add_argument("--entry", required=True)

    # custom-remove
    p = sub.add_parser("custom-remove", help="Remove an entry from manifest custom:")
    p.add_argument("--target", required=True)
    p.add_argument("--category", required=True, choices=list(CUSTOM_CATEGORIES))
    p.add_argument("--entry", required=True)

    # custom-list
    p = sub.add_parser("custom-list", help="Print custom entries as category<TAB>entry")
    p.add_argument("--target", required=True)

    # doctor-check
    p = sub.add_parser("doctor-check", help="Compare disk vs pipeline-expected and custom lists")
    p.add_argument("--target", required=True)
    p.add_argument("--pipeline-root", default="", help="Override pipeline repo (default: manifest pipeline_repo)")
    p.add_argument("--strict", action="store_true", help="Exit 1 if any UNTRACKED paths")

    args = parser.parse_args()

    dispatch = {
        "list-extensions": cmd_list_extensions,
        "list-installed-extensions": cmd_list_installed_extensions,
        "get-prefix":      cmd_get_prefix,
        "get-version":     cmd_get_version,
        "write-master":    cmd_write_master,
        "is-locked":       cmd_is_locked,
        "lock":            cmd_lock,
        "unlock":          cmd_unlock,
        "read-status":     cmd_read_status,
        "custom-add":      cmd_custom_add,
        "custom-remove":   cmd_custom_remove,
        "custom-list":     cmd_custom_list,
        "doctor-check":    cmd_doctor_check,
    }
    dispatch[args.command](args)


if __name__ == "__main__":
    main()
