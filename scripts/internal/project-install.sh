#!/usr/bin/env bash
#
# project-install.sh — Install AI Dev Garage core and/or extensions into a project,
# create/update the project master manifest, and symlink <project>/.cursor and .claude.
#
# Usage: project-install.sh <project-path> [--core] [--ext name,...] [--force] [--update-mode]
#
# Flags:
#   <project-path>      Path to the project directory (required)
#   --core              Include core in this project install
#   --ext name,...      Comma-separated list of extensions to install
#   --force             Overwrite without prompting
#   --update-mode       Skip locked components (used internally by garage update)
#   -h, --help          Show this help
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$SCRIPT_DIR/colors.sh"
# shellcheck source=check-dirs.sh
source "$SCRIPT_DIR/check-dirs.sh"

MANIFEST_PY="$SCRIPT_DIR/manifest.py"

show_help() {
  echo ""
  echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage install${CLR_RST} ${CLR_OPT}--project <path>${CLR_RST} [options]"
  echo ""
  echo "  Install AI Dev Garage into a specific project."
  echo ""
  echo "${CLR_BOLD}Options:${CLR_RST}"
  echo "  ${CLR_OPT}--core${CLR_RST}              Include core assets in this project install"
  echo "  ${CLR_OPT}--ext name[,name]${CLR_RST}   Extensions to install"
  echo "  ${CLR_OPT}--force${CLR_RST}             Overwrite existing files without prompting"
  echo "  ${CLR_OPT}-h, --help${CLR_RST}          Show this help"
  echo ""
  echo "${CLR_BOLD}Examples:${CLR_RST}"
  echo "  ${CLR_CMD}garage install${CLR_RST} ${CLR_OPT}--project ./myapp --core${CLR_RST}"
  echo "  ${CLR_CMD}garage install${CLR_RST} ${CLR_OPT}--project ./myapp --core --ext agile${CLR_RST}"
  echo "  ${CLR_CMD}garage install${CLR_RST} ${CLR_OPT}--project ./myapp --ext dev-common${CLR_RST}"
  echo ""
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
PROJ_PATH=""
INSTALL_CORE=0
EXT_FILTER=""
FORCE=0
UPDATE_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    --core) INSTALL_CORE=1; shift ;;
    --force) FORCE=1; shift ;;
    --update-mode) UPDATE_MODE=1; shift ;;
    --ext)
      shift
      EXT_FILTER="${1:-}"
      [ -n "$EXT_FILTER" ] || { echo "${CLR_ERR}Error: --ext requires a value.${CLR_RST}" >&2; exit 1; }
      shift
      ;;
    -*)
      echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2
      show_help; exit 1
      ;;
    *)
      if [ -z "$PROJ_PATH" ]; then
        PROJ_PATH="$1"
      else
        echo "${CLR_ERR}Error: unexpected argument: $1${CLR_RST}" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$PROJ_PATH" ]; then
  echo "${CLR_ERR}Error: project path is required.${CLR_RST}" >&2
  show_help; exit 1
fi

if [ ! -d "$PROJ_PATH" ]; then
  echo "${CLR_ERR}Error: not a directory: $PROJ_PATH${CLR_RST}" >&2
  exit 1
fi

if [ "$INSTALL_CORE" -eq 0 ] && [ -z "$EXT_FILTER" ] && [ "$UPDATE_MODE" -eq 0 ]; then
  echo "${CLR_ERR}Error: specify at least --core or --ext <name>.${CLR_RST}" >&2
  show_help; exit 1
fi

# ---------------------------------------------------------------------------
# Validate environment
# ---------------------------------------------------------------------------
if [ -z "${AI_DEV_GARAGE:-}" ]; then
  echo "${CLR_ERR}Error: AI_DEV_GARAGE is not set.${CLR_RST}" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "${CLR_ERR}Error: python3 is required.${CLR_RST}" >&2
  exit 1
fi

PIPELINE_ROOT="$(cd "$AI_DEV_GARAGE" && pwd)"
CORE_DIR="$PIPELINE_ROOT/core"
EXT_ROOT="$PIPELINE_ROOT/extensions"
PROJ="$(cd "$PROJ_PATH" && pwd)"
GARAGE_PROJ="$PROJ/.ai-dev-garage"
MASTER_MANIFEST="$GARAGE_PROJ/manifest.yaml"

mkdir -p "$GARAGE_PROJ"/{agents,commands,skills,rules,memory}
for d in agents commands skills rules memory; do
  touch "$GARAGE_PROJ/$d/.gitkeep" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# Helper: copy a single file
# ---------------------------------------------------------------------------
copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "${CLR_CMD}  + $(basename "$dest")${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Install core into project
# ---------------------------------------------------------------------------
install_core() {
  if [ "$UPDATE_MODE" -eq 1 ]; then
    if [ -f "$MASTER_MANIFEST" ] && python3 "$MANIFEST_PY" is-locked --target "$MASTER_MANIFEST" core 2>/dev/null; then
      echo "${CLR_WARN}  core is locked — skipping.${CLR_RST}"
      return 0
    fi
  fi

  echo "${CLR_DIM}Installing core into project...${CLR_RST}"

  # agents
  if [ -d "$CORE_DIR/agents" ]; then
    for f in "$CORE_DIR/agents"/*.md; do
      [ -f "$f" ] || continue
      copy_file "$f" "$GARAGE_PROJ/agents/$(basename "$f")"
    done
  fi

  # commands flat
  if [ -d "$CORE_DIR/commands" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/commands/$(basename "$f")"
    done < <(find "$CORE_DIR/commands" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # commands subfolder
  if [ -d "$CORE_DIR/commands/ai-dev-garage" ]; then
    mkdir -p "$GARAGE_PROJ/commands/ai-dev-garage"
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/commands/ai-dev-garage/$(basename "$f")"
    done < <(find "$CORE_DIR/commands/ai-dev-garage" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # rules
  if [ -d "$CORE_DIR/rules" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/rules/$(basename "$f")"
    done < <(find "$CORE_DIR/rules" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdc" \) -print0 2>/dev/null)
  fi

  # memory
  if [ -d "$CORE_DIR/memory" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/memory/$(basename "$f")"
    done < <(find "$CORE_DIR/memory" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # skills
  if [ -d "$CORE_DIR/skills" ]; then
    for d in "$CORE_DIR/skills"/*; do
      [ -d "$d" ] || continue
      local base
      base="$(basename "$d")"
      local dest="$GARAGE_PROJ/skills/$base"
      mkdir -p "$dest"
      while IFS= read -r -d '' f; do
        local rel="${f#$d/}"
        mkdir -p "$dest/$(dirname "$rel")"
        cp "$f" "$dest/$rel"
      done < <(find "$d" -type f -print0 2>/dev/null)
      echo "${CLR_CMD}  + skills/$base/${CLR_RST}"
    done
  fi

  echo "${CLR_CMD}  core installed.${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Install extension into project
# ---------------------------------------------------------------------------
install_extension() {
  local ext_id="$1"

  if [ "$UPDATE_MODE" -eq 1 ] && [ -f "$MASTER_MANIFEST" ]; then
    if python3 "$MANIFEST_PY" is-locked --target "$MASTER_MANIFEST" "$ext_id" 2>/dev/null; then
      echo "${CLR_WARN}  extension ${CLR_OPT}$ext_id${CLR_WARN} is locked — skipping.${CLR_RST}"
      return 0
    fi
  fi

  local ext_dir="$EXT_ROOT/$ext_id"
  if [ ! -d "$ext_dir" ]; then
    echo "${CLR_WARN}  Warning: extension '$ext_id' not found: $ext_dir${CLR_RST}" >&2
    return 0
  fi

  local prefix
  if ! prefix="$(python3 "$MANIFEST_PY" get-prefix --pipeline-root "$PIPELINE_ROOT" --ext-id "$ext_id" 2>/dev/null)"; then
    echo "${CLR_WARN}  Warning: skip extension '$ext_id' (invalid manifest.yaml)${CLR_RST}" >&2
    return 0
  fi
  [ -n "$prefix" ] || return 0

  echo "${CLR_DIM}Installing extension ${CLR_OPT}$ext_id${CLR_DIM} into project...${CLR_RST}"

  if [ -d "$ext_dir/agents" ]; then
    for f in "$ext_dir/agents"/*.md; do
      [ -f "$f" ] || continue
      copy_file "$f" "$GARAGE_PROJ/agents/${prefix}-$(basename "$f")"
    done
  fi

  if [ -d "$ext_dir/commands" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/commands/${prefix}-$(basename "$f")"
    done < <(find "$ext_dir/commands" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  if [ -d "$ext_dir/rules" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/rules/${prefix}-$(basename "$f")"
    done < <(find "$ext_dir/rules" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdc" \) -print0 2>/dev/null)
  fi

  if [ -d "$ext_dir/memory" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_PROJ/memory/${prefix}-$(basename "$f")"
    done < <(find "$ext_dir/memory" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  if [ -d "$ext_dir/skills" ]; then
    for d in "$ext_dir/skills"/*; do
      [ -d "$d" ] || continue
      local skill_base
      skill_base="$(basename "$d")"
      local dest="$GARAGE_PROJ/skills/${prefix}-${skill_base}"
      mkdir -p "$dest"
      while IFS= read -r -d '' f; do
        local rel="${f#$d/}"
        mkdir -p "$dest/$(dirname "$rel")"
        cp "$f" "$dest/$rel"
      done < <(find "$d" -type f -print0 2>/dev/null)
      echo "${CLR_CMD}  + skills/${prefix}-${skill_base}/${CLR_RST}"
    done
  fi

  echo "${CLR_CMD}  extension ${CLR_OPT}$ext_id${CLR_CMD} installed.${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Run installs
# ---------------------------------------------------------------------------
[ "$INSTALL_CORE" -eq 1 ] && install_core

EXT_LIST=()
if [ -n "$EXT_FILTER" ]; then
  IFS=',' read -r -a EXT_LIST <<< "$EXT_FILTER"
fi

for ext_id in "${EXT_LIST[@]}"; do
  [ -n "$ext_id" ] || continue
  install_extension "$ext_id"
done

# ---------------------------------------------------------------------------
# Write project master manifest
# ---------------------------------------------------------------------------
CORE_VERSION="unknown"
if [ "$INSTALL_CORE" -eq 1 ]; then
  CORE_VERSION="$(python3 "$MANIFEST_PY" get-version --component-path "$CORE_DIR" 2>/dev/null || echo "unknown")"
elif [ -f "$MASTER_MANIFEST" ]; then
  # preserve existing core version on ext-only install
  CORE_VERSION="$(python3 -c "
import yaml, sys
d = yaml.safe_load(open('$MASTER_MANIFEST')) or {}
print(d.get('core', {}).get('version', 'unknown'))
" 2>/dev/null || echo "unknown")"
fi

MANIFEST_ARGS=(
  write-master
  --target "$MASTER_MANIFEST"
  --pipeline-repo "$PIPELINE_ROOT"
  --core "$CORE_VERSION"
)
[ "$UPDATE_MODE" -eq 1 ] && MANIFEST_ARGS+=(--preserve-installed-at)

# Collect all previously installed extensions + new ones
ALL_EXTS=()
if [ -f "$MASTER_MANIFEST" ] && [ "$UPDATE_MODE" -eq 1 ]; then
  # On update, re-read existing extension list from manifest
  while IFS= read -r line; do
    [[ "$line" == *$'\t'* ]] || continue
    ext_id="$(echo "$line" | cut -f1)"
    [ "$ext_id" = "core" ] && continue
    ALL_EXTS+=("$ext_id")
  done < <(python3 "$MANIFEST_PY" read-status --target "$MASTER_MANIFEST" 2>/dev/null | tail -n +4 || true)
else
  ALL_EXTS=("${EXT_LIST[@]}")
fi

for ext_id in "${ALL_EXTS[@]}"; do
  [ -n "$ext_id" ] || continue
  local_ext_dir="$EXT_ROOT/$ext_id"
  ext_ver="$(python3 "$MANIFEST_PY" get-version --component-path "$local_ext_dir" 2>/dev/null || echo "unknown")"
  MANIFEST_ARGS+=(--ext "${ext_id}=${ext_ver}")
done

python3 "$MANIFEST_PY" "${MANIFEST_ARGS[@]}"
echo "${CLR_CMD}  Project manifest written: $MASTER_MANIFEST${CLR_RST}"

# ---------------------------------------------------------------------------
# Symlink <project>/.cursor and <project>/.claude
# ---------------------------------------------------------------------------
CURSOR_ROOT="$PROJ/.cursor"
CLAUDE_ROOT="$PROJ/.claude"

echo ""
echo "${CLR_DIM}Setting up project symlinks...${CLR_RST}"

for name in agents commands skills rules memory; do
  check_and_link_dir "$CURSOR_ROOT" "$name" "$GARAGE_PROJ/$name"
done

for name in agents commands skills rules; do
  check_and_link_dir "$CLAUDE_ROOT" "$name" "$GARAGE_PROJ/$name"
done

echo ""
echo "${CLR_CMD}Project install complete: ${CLR_OPT}$PROJ${CLR_RST}"
echo "${CLR_DIM}  Runtime: $GARAGE_PROJ${CLR_RST}"
