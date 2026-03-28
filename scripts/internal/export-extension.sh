#!/usr/bin/env bash
#
# export-extension.sh — Import 3rd-party AI configs (skills, agents, rules, commands)
# into a Garage bundle (global ~/.ai-dev-garage or a project's .ai-dev-garage).
#
# Usage: export-extension.sh <source-path> [--project <path>] [--force]
#
# Flags:
#   <source-path>       Path to folder containing skills/, agents/, rules/, commands/
#   --project <path>    Install into project .ai-dev-garage (default: global)
#   --force             Overwrite all conflicts without prompting
#   -h, --help          Show this help
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$SCRIPT_DIR/colors.sh"

show_help() {
  echo ""
  echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage export${CLR_RST} ${CLR_OPT}<source-path>${CLR_RST} [options]"
  echo ""
  echo "  Import AI configs from a 3rd-party directory into AI Dev Garage."
  echo "  Reads skills/, agents/, rules/, commands/ from the source path."
  echo ""
  echo "${CLR_BOLD}Options:${CLR_RST}"
  echo "  ${CLR_OPT}--project <path>${CLR_RST}   Install into a project's .ai-dev-garage (default: global)"
  echo "  ${CLR_OPT}--force${CLR_RST}            Overwrite all conflicts without prompting"
  echo "  ${CLR_OPT}-h, --help${CLR_RST}         Show this help"
  echo ""
  echo "${CLR_BOLD}Examples:${CLR_RST}"
  echo "  ${CLR_CMD}garage export${CLR_RST} ${CLR_OPT}~/my-ai-configs${CLR_RST}"
  echo "  ${CLR_CMD}garage export${CLR_RST} ${CLR_OPT}~/my-ai-configs --project ./myapp${CLR_RST}"
  echo "  ${CLR_CMD}garage export${CLR_RST} ${CLR_OPT}~/my-ai-configs --force${CLR_RST}"
  echo ""
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
SOURCE_PATH=""
PROJECT_PATH=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    --force) FORCE=1; shift ;;
    --project)
      shift
      PROJECT_PATH="${1:-}"
      [ -n "$PROJECT_PATH" ] || { echo "${CLR_ERR}Error: --project requires a path.${CLR_RST}" >&2; exit 1; }
      shift
      ;;
    -*)
      echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2
      show_help; exit 1
      ;;
    *)
      if [ -z "$SOURCE_PATH" ]; then
        SOURCE_PATH="$1"
      else
        echo "${CLR_ERR}Error: unexpected argument: $1${CLR_RST}" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$SOURCE_PATH" ]; then
  echo "${CLR_ERR}Error: source path is required.${CLR_RST}" >&2
  show_help; exit 1
fi

if [ ! -d "$SOURCE_PATH" ]; then
  echo "${CLR_ERR}Error: source path is not a directory: $SOURCE_PATH${CLR_RST}" >&2
  exit 1
fi

SOURCE="$(cd "$SOURCE_PATH" && pwd)"

# ---------------------------------------------------------------------------
# Resolve target
# ---------------------------------------------------------------------------
if [ -n "$PROJECT_PATH" ]; then
  if [ ! -d "$PROJECT_PATH" ]; then
    echo "${CLR_ERR}Error: project path is not a directory: $PROJECT_PATH${CLR_RST}" >&2
    exit 1
  fi
  TARGET="$(cd "$PROJECT_PATH" && pwd)/.ai-dev-garage"
else
  TARGET="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}"
fi

if [ ! -d "$TARGET" ]; then
  echo "${CLR_ERR}Error: target Garage bundle not found: $TARGET${CLR_RST}" >&2
  echo "${CLR_DIM}Run 'garage install' first.${CLR_RST}" >&2
  exit 1
fi

echo "${CLR_DIM}Exporting from: ${CLR_OPT}$SOURCE${CLR_RST}"
echo "${CLR_DIM}  Into target:  ${CLR_OPT}$TARGET${CLR_RST}"
echo ""

COPIED=0
SKIPPED=0
OVERWRITTEN=0

# ---------------------------------------------------------------------------
# Helper: copy one item (file or directory) with collision check
# ---------------------------------------------------------------------------
copy_item() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      rm -rf "$dest"
      cp -r "$src" "$dest"
      echo "${CLR_CMD}  ~ $label (overwritten)${CLR_RST}"
      OVERWRITTEN=$((OVERWRITTEN + 1))
    else
      echo "${CLR_WARN}  Conflict: ${CLR_OPT}$label${CLR_RST}"
      printf "  ${CLR_OPT}[Y]${CLR_RST}es overwrite / ${CLR_OPT}[n]${CLR_RST}o skip: "
      local ans
      read -r ans </dev/tty
      ans="${ans:-Y}"
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -rf "$dest"
        cp -r "$src" "$dest"
        echo "${CLR_CMD}  ~ $label (overwritten)${CLR_RST}"
        OVERWRITTEN=$((OVERWRITTEN + 1))
      else
        echo "${CLR_DIM}  Skipped: $label${CLR_RST}"
        SKIPPED=$((SKIPPED + 1))
      fi
    fi
  else
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    echo "${CLR_CMD}  + $label${CLR_RST}"
    COPIED=$((COPIED + 1))
  fi
}

# ---------------------------------------------------------------------------
# Export flat asset dirs: agents, rules, commands (files)
# ---------------------------------------------------------------------------
for asset_type in agents rules commands; do
  src_dir="$SOURCE/$asset_type"
  [ -d "$src_dir" ] || continue

  dest_dir="$TARGET/$asset_type"
  mkdir -p "$dest_dir"

  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    copy_item "$f" "$dest_dir/$base" "$asset_type/$base"
  done < <(find "$src_dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
done

# ---------------------------------------------------------------------------
# Export skills (directories)
# ---------------------------------------------------------------------------
src_skills="$SOURCE/skills"
if [ -d "$src_skills" ]; then
  dest_skills="$TARGET/skills"
  mkdir -p "$dest_skills"

  for d in "$src_skills"/*/; do
    [ -d "$d" ] || continue
    skill_name="$(basename "$d")"
    copy_item "$d" "$dest_skills/$skill_name" "skills/$skill_name/"
  done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "${CLR_BOLD}Export complete.${CLR_RST}"
echo "  ${CLR_CMD}Copied:${CLR_RST}      $COPIED"
echo "  ${CLR_OPT}Overwritten:${CLR_RST} $OVERWRITTEN"
echo "  ${CLR_DIM}Skipped:${CLR_RST}     $SKIPPED"
