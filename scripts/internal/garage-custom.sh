#!/usr/bin/env bash
#
# garage-custom.sh — manifest custom: add / remove / list
#
# Usage:
#   garage-custom.sh add    --category <agents|commands|skills|rules|memory> --entry <name> [--project <path>]
#   garage-custom.sh remove --category <...> --entry <name> [--project <path>]
#   garage-custom.sh list   [--project <path>]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$SCRIPT_DIR/colors.sh"

MANIFEST_PY="$SCRIPT_DIR/manifest.py"

TARGET_MANIFEST="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}/manifest.yaml"
ACTION=""
CATEGORY=""
ENTRY=""
PROJECT_PATH=""

for _a in "$@"; do
  case "$_a" in -h|--help)
    echo ""
    echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage custom${CLR_RST} ${CLR_OPT}add|remove|list${CLR_RST} [options]"
    echo ""
    echo "  Register or list user-owned assets under manifest ${CLR_DIM}custom:${CLR_RST} (global or project)."
    echo ""
    echo "${CLR_BOLD}Subcommands:${CLR_RST}"
    echo "  ${CLR_CMD}add${CLR_RST}     ${CLR_OPT}--category${CLR_RST} ${CLR_DIM}<agents|commands|skills|rules|memory>${CLR_RST} ${CLR_OPT}--entry${CLR_RST} ${CLR_DIM}<name>${CLR_RST}"
    echo "  ${CLR_CMD}remove${CLR_RST}  same flags"
    echo "  ${CLR_CMD}list${CLR_RST}    print registered entries"
    echo ""
    echo "${CLR_BOLD}Options:${CLR_RST}"
    echo "  ${CLR_OPT}--project <path>${CLR_RST}   Use <path>/.ai-dev-garage/manifest.yaml"
    echo ""
    echo "${CLR_DIM}commands: basename.md or ai-dev-garage/foo.md; skills: top-level folder name only.${CLR_RST}"
    echo ""
    exit 0 ;;
  esac
done

while [ $# -gt 0 ]; do
  case "$1" in
    add|remove|list) ACTION="$1"; shift ;;
    --category)
      shift; CATEGORY="${1:-}"; shift ;;
    --entry)
      shift; ENTRY="${1:-}"; shift ;;
    --project)
      shift; PROJECT_PATH="${1:-}"; shift ;;
    *)
      echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2
      exit 1 ;;
  esac
done

if [ -n "$PROJECT_PATH" ]; then
  TARGET_MANIFEST="$(cd "$PROJECT_PATH" && pwd)/.ai-dev-garage/manifest.yaml"
fi

[ -n "$ACTION" ] || { echo "${CLR_ERR}Error: specify add, remove, or list.${CLR_RST}" >&2; exit 1; }

case "$ACTION" in
  add)
    [ -n "$CATEGORY" ] && [ -n "$ENTRY" ] || { echo "${CLR_ERR}Error: add requires --category and --entry.${CLR_RST}" >&2; exit 1; }
    python3 "$MANIFEST_PY" custom-add --target "$TARGET_MANIFEST" --category "$CATEGORY" --entry "$ENTRY"
    ;;
  remove)
    [ -n "$CATEGORY" ] && [ -n "$ENTRY" ] || { echo "${CLR_ERR}Error: remove requires --category and --entry.${CLR_RST}" >&2; exit 1; }
    python3 "$MANIFEST_PY" custom-remove --target "$TARGET_MANIFEST" --category "$CATEGORY" --entry "$ENTRY"
    ;;
  list)
    python3 "$MANIFEST_PY" custom-list --target "$TARGET_MANIFEST"
    ;;
esac
