#!/usr/bin/env bash
#
# verify-install.sh — Dry-run global install into a temp HOME and assert symlinks + manifest.
# Safe to run locally or in CI.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=internal/colors.sh
source "$SCRIPT_DIR/internal/colors.sh"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

export AI_DEV_GARAGE="$ROOT"
export GARAGE_HOME="$TMP/.ai-dev-garage"
export TARGET_HOME="$TMP"

mkdir -p "$TMP/.cursor" "$TMP/.claude"

echo "${CLR_DIM}Running dry-run install into $TMP (core only, then +extensions) ...${CLR_RST}"
bash "$SCRIPT_DIR/internal/global-install.sh" --force 2>&1

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------
FAIL=0

assert_link() {
  local p="$1" expected="$2"
  if [ ! -L "$p" ]; then
    echo "${CLR_ERR}FAIL: not a symlink: $p${CLR_RST}" >&2
    FAIL=1
    return
  fi
  local cur
  cur="$(readlink "$p")"
  if [ "$cur" != "$expected" ]; then
    echo "${CLR_ERR}FAIL: $p -> $cur (expected $expected)${CLR_RST}" >&2
    FAIL=1
  fi
}

assert_file() {
  local p="$1"
  if [ ! -f "$p" ]; then
    echo "${CLR_ERR}FAIL: missing file: $p${CLR_RST}" >&2
    FAIL=1
  fi
}

assert_dir() {
  local p="$1"
  if [ ! -d "$p" ]; then
    echo "${CLR_ERR}FAIL: missing directory: $p${CLR_RST}" >&2
    FAIL=1
  fi
}

# Symlinks: .cursor
for name in agents commands skills rules memory; do
  assert_link "$TMP/.cursor/$name" "$GARAGE_HOME/$name"
done

# Symlinks: .claude
for name in agents commands skills rules; do
  assert_link "$TMP/.claude/$name" "$GARAGE_HOME/$name"
done

# Core assets
assert_file "$GARAGE_HOME/rules/garage-runtime.md"

# Core skills
assert_dir "$GARAGE_HOME/skills/skill-standard"
assert_dir "$GARAGE_HOME/skills/agent-standard"
assert_dir "$GARAGE_HOME/skills/command-standard"
assert_dir "$GARAGE_HOME/skills/rule-standard"

# Self-management commands subfolder
assert_dir "$GARAGE_HOME/commands/ai-dev-garage"
assert_file "$GARAGE_HOME/commands/ai-dev-garage/create-agent.md"
assert_file "$GARAGE_HOME/commands/ai-dev-garage/create-skill.md"

# Default install must not copy extension-prefixed assets
if [ -f "$GARAGE_HOME/agents/agile-define-feature.md" ]; then
  echo "${CLR_ERR}FAIL: expected core-only install; found agile agent${CLR_RST}" >&2
  FAIL=1
fi

# Second pass: install extensions (manifest records them; update path is covered)
bash "$SCRIPT_DIR/internal/global-install.sh" --force --ext agile,dev-common 2>&1

assert_file "$GARAGE_HOME/agents/agile-define-feature.md"
assert_dir  "$GARAGE_HOME/skills/agile-acceptance-criteria-generation"
assert_file "$GARAGE_HOME/commands/dev-common-update-constitution.md"

# Master manifest
assert_file "$GARAGE_HOME/manifest.yaml"

# Verify manifest has core entry
python3 "$SCRIPT_DIR/internal/manifest.py" read-status --target "$GARAGE_HOME/manifest.yaml" | grep -q "^core" \
  || { echo "${CLR_ERR}FAIL: master manifest missing 'core' entry${CLR_RST}" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 1 ]; then
  echo "${CLR_ERR}verify-install: FAILED${CLR_RST}" >&2
  exit 1
else
  echo "${CLR_CMD}verify-install: OK${CLR_RST}"
fi
