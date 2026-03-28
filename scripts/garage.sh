#!/usr/bin/env bash
#
# garage — AI Dev Garage CLI entry point.
#
# Run with no arguments to open the interactive shell (arrow-key menu).
#
# Usage:
#   garage                                          Interactive menu
#   garage install [--ext name,...] [--force]
#   garage install --project <path> [--core] [--ext name,...] [--force]
#   garage update  [--force]
#   garage update  --project <path> [--force]
#   garage lock    <core|ext-name> [--project <path>]
#   garage unlock  <core|ext-name> [--project <path>]
#   garage export  <source-path>   [--project <path>] [--force]
#   garage status  [--project <path>]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export AI_DEV_GARAGE="${AI_DEV_GARAGE:-$PIPELINE_ROOT}"

INTERNAL="$SCRIPT_DIR/internal"
MANIFEST_PY="$INTERNAL/manifest.py"

# shellcheck source=internal/colors.sh
source "$INTERNAL/colors.sh"
# shellcheck source=internal/pipeline-sync.sh
source "$INTERNAL/pipeline-sync.sh"

# ---------------------------------------------------------------------------
# Banner (not shown for -h / --help; see dispatch below)
# ---------------------------------------------------------------------------
show_banner() {
  # shellcheck source=banner.sh
  source "$SCRIPT_DIR/banner.sh"
  garage_banner_print
}

garage_args_contain_help() {
  local _a
  for _a in "$@"; do
    case "$_a" in
      -h|--help) return 0 ;;
    esac
  done
  return 1
}

# Capitalize first letter (bash 3.2 has no ${var^})
_garage_capitalize_word() {
  local w="$1"
  local first rest
  first="${w:0:1}"
  rest="${w:1}"
  printf '%s%s' "$(printf '%s' "$first" | tr '[:lower:]' '[:upper:]')" "$rest"
}

# ---------------------------------------------------------------------------
# Top-level help (no banner — keeps help output compact)
# ---------------------------------------------------------------------------
show_help() {
  echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage${CLR_RST} ${CLR_OPT}[command]${CLR_RST} [options]"
  echo ""
  echo "  Run ${CLR_CMD}garage${CLR_RST} with no arguments to open the interactive menu."
  echo ""
  echo "${CLR_BOLD}Commands:${CLR_RST}"
  echo "  ${CLR_CMD}install${CLR_RST}   Install core and extensions (global or project)"
  echo "  ${CLR_CMD}update${CLR_RST}    Update installed components to latest versions"
  echo "  ${CLR_CMD}lock${CLR_RST}      Lock a component from being updated"
  echo "  ${CLR_CMD}unlock${CLR_RST}    Unlock a previously locked component"
  echo "  ${CLR_CMD}export${CLR_RST}    Import 3rd-party AI configs into garage"
  echo "  ${CLR_CMD}status${CLR_RST}    Show installed components, versions, and lock state"
  echo ""
  echo "${CLR_DIM}Run ${CLR_CMD}garage${CLR_RST} ${CLR_OPT}<command> --help${CLR_RST}${CLR_DIM} for details on a specific command.${CLR_RST}"
  echo ""
}

# ---------------------------------------------------------------------------
# git fetch + optional pull (non-fatal). Interactive TTY: ask before pull; n = skip pull only.
# ---------------------------------------------------------------------------
sync_pipeline() {
  garage_sync_pipeline_from_origin "$PIPELINE_ROOT"
}

# ---------------------------------------------------------------------------
# status helper
# ---------------------------------------------------------------------------
cmd_status() {
  local project_path=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        echo ""
        echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage status${CLR_RST} [${CLR_OPT}--project <path>${CLR_RST}]"
        echo ""
        echo "  Show installed components, versions, and lock state."
        echo ""
        echo "${CLR_BOLD}Options:${CLR_RST}"
        echo "  ${CLR_OPT}--project <path>${CLR_RST}   Show status for a project install"
        echo "  ${CLR_OPT}-h, --help${CLR_RST}         Show this help"
        echo ""
        exit 0 ;;
      --project)
        shift; project_path="${1:-}"
        [ -n "$project_path" ] || { echo "${CLR_ERR}Error: --project requires a path.${CLR_RST}" >&2; exit 1; }
        shift ;;
      *) echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2; exit 1 ;;
    esac
  done

  local target_manifest
  if [ -n "$project_path" ]; then
    target_manifest="$(cd "$project_path" && pwd)/.ai-dev-garage/manifest.yaml"
  else
    target_manifest="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}/manifest.yaml"
  fi

  if [ ! -f "$target_manifest" ]; then
    echo "${CLR_ERR}Error: no manifest found at $target_manifest${CLR_RST}" >&2
    echo "${CLR_DIM}Run 'garage install' first.${CLR_RST}" >&2
    exit 1
  fi

  local raw
  raw="$(python3 "$MANIFEST_PY" read-status --target "$target_manifest")"

  local pipeline_repo installed_at updated_at
  pipeline_repo="$(echo "$raw" | grep '^pipeline_repo=' | cut -d= -f2-)"
  installed_at="$(echo "$raw" | grep '^installed_at=' | cut -d= -f2-)"
  updated_at="$(echo "$raw" | grep '^updated_at=' | cut -d= -f2-)"

  echo ""
  echo "${CLR_BOLD}AI Dev Garage — Status${CLR_RST}"
  echo "${CLR_DIM}  Pipeline:     $pipeline_repo${CLR_RST}"
  echo "${CLR_DIM}  Installed:    $installed_at${CLR_RST}"
  echo "${CLR_DIM}  Last update:  $updated_at${CLR_RST}"
  echo ""
  printf "${CLR_BOLD}  %-20s %-12s %s${CLR_RST}\n" "Component" "Version" "Status"
  echo "${CLR_DIM}  ─────────────────────────────────────────${CLR_RST}"

  while IFS=$'\t' read -r name version locked; do
    [ -z "$name" ] && continue
    local lock_label=""
    [ "$locked" = "locked" ] && lock_label="${CLR_OPT}locked${CLR_RST}"
    printf "  ${CLR_CMD}%-20s${CLR_RST} ${CLR_DIM}%-12s${CLR_RST} %b\n" "$name" "$version" "$lock_label"
  done < <(echo "$raw" | awk '/^---$/{found=1; next} found{print}')

  echo ""
}

# ---------------------------------------------------------------------------
# lock / unlock helper
# ---------------------------------------------------------------------------
cmd_lock_unlock() {
  local action="$1"; shift
  local component=""
  local project_path=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        echo ""
        echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage $action${CLR_RST} ${CLR_OPT}<core|extension-name>${CLR_RST} [${CLR_OPT}--project <path>${CLR_RST}]"
        echo ""
        echo "  $(_garage_capitalize_word "$action") a component to prevent (or allow) updates."
        echo ""
        echo "${CLR_BOLD}Options:${CLR_RST}"
        echo "  ${CLR_OPT}--project <path>${CLR_RST}   Target a project manifest instead of global"
        echo "  ${CLR_OPT}-h, --help${CLR_RST}         Show this help"
        echo ""
        echo "${CLR_BOLD}Examples:${CLR_RST}"
        echo "  ${CLR_CMD}garage $action${CLR_RST} ${CLR_OPT}core${CLR_RST}"
        echo "  ${CLR_CMD}garage $action${CLR_RST} ${CLR_OPT}agile${CLR_RST}"
        echo "  ${CLR_CMD}garage $action${CLR_RST} ${CLR_OPT}agile --project ./myapp${CLR_RST}"
        echo ""
        exit 0 ;;
      --project)
        shift; project_path="${1:-}"
        [ -n "$project_path" ] || { echo "${CLR_ERR}Error: --project requires a path.${CLR_RST}" >&2; exit 1; }
        shift ;;
      -*)
        echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2; exit 1 ;;
      *)
        component="$1"; shift ;;
    esac
  done

  [ -n "$component" ] || { echo "${CLR_ERR}Error: component name required (e.g. core, agile).${CLR_RST}" >&2; exit 1; }

  local target_manifest
  if [ -n "$project_path" ]; then
    target_manifest="$(cd "$project_path" && pwd)/.ai-dev-garage/manifest.yaml"
  else
    target_manifest="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}/manifest.yaml"
  fi

  python3 "$MANIFEST_PY" "$action" --target "$target_manifest" "$component"
  echo "${CLR_CMD}  Done.${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
cmd="${1:-}"
[ $# -gt 0 ] && shift || true

case "$cmd" in
  "")
    # No arguments — launch interactive shell (requires a real terminal)
    if [ -t 0 ] && [ -t 1 ]; then
      exec bash "$INTERNAL/garage-shell.sh"
    else
      show_help
      exit 0
    fi
    ;;

  -h|--help)
    show_help
    exit 0
    ;;

  install)
    if garage_args_contain_help "$@"; then
      if printf '%s\n' "$@" | grep -q -- '--project'; then
        exec bash "$INTERNAL/project-install.sh" "$@"
      else
        exec bash "$INTERNAL/global-install.sh" "$@"
      fi
    fi
    show_banner
    sync_pipeline
    if printf '%s\n' "$@" | grep -q -- '--project'; then
      exec bash "$INTERNAL/project-install.sh" "$@"
    else
      exec bash "$INTERNAL/global-install.sh" "$@"
    fi
    ;;

  update)
    if garage_args_contain_help "$@"; then
      if printf '%s\n' "$@" | grep -q -- '--project'; then
        exec bash "$INTERNAL/project-install.sh" --update-mode "$@"
      else
        exec bash "$INTERNAL/global-install.sh" --update-mode "$@"
      fi
    fi
    show_banner
    sync_pipeline
    if printf '%s\n' "$@" | grep -q -- '--project'; then
      exec bash "$INTERNAL/project-install.sh" --update-mode "$@"
    else
      exec bash "$INTERNAL/global-install.sh" --update-mode "$@"
    fi
    ;;

  lock)
    if garage_args_contain_help "$@"; then
      cmd_lock_unlock "lock" "$@"
    fi
    show_banner
    sync_pipeline
    cmd_lock_unlock "lock" "$@"
    ;;

  unlock)
    if garage_args_contain_help "$@"; then
      cmd_lock_unlock "unlock" "$@"
    fi
    show_banner
    sync_pipeline
    cmd_lock_unlock "unlock" "$@"
    ;;

  export)
    if garage_args_contain_help "$@"; then
      exec bash "$INTERNAL/export-extension.sh" "$@"
    fi
    show_banner
    sync_pipeline
    exec bash "$INTERNAL/export-extension.sh" "$@"
    ;;

  status)
    if garage_args_contain_help "$@"; then
      cmd_status "$@"
    fi
    show_banner
    cmd_status "$@"
    ;;

  *)
    echo "${CLR_ERR}Error: Unknown command: ${CLR_OPT}$cmd${CLR_RST}" >&2
    echo "${CLR_DIM}Run ${CLR_CMD}garage --help${CLR_RST}${CLR_DIM} for usage.${CLR_RST}" >&2
    exit 1
    ;;
esac
