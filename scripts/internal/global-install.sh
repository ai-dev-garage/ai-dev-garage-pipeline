#!/usr/bin/env bash
#
# global-install.sh — Copy AI Dev Garage core + enabled extensions to ~/.ai-dev-garage,
# create/update the master manifest, and symlink ~/.cursor/* and ~/.claude/* into the runtime.
#
# Requires: AI_DEV_GARAGE (pipeline repo root).
# Optional: GARAGE_HOME (default ~/.ai-dev-garage), TARGET_HOME (default $HOME, override for tests).
#
# Flags:
#   --force          Overwrite without prompting
#   --ext name,...   Comma-separated list of extensions to install (default: core only)
#   --update-mode    Skip locked components (used internally by garage update)
#   -h, --help       Show this help
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
  echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage install${CLR_RST} [options]"
  echo ""
  echo "  Install AI Dev Garage core globally under ~/.ai-dev-garage (extensions are opt-in)."
  echo ""
  echo "${CLR_BOLD}Options:${CLR_RST}"
  echo "  ${CLR_OPT}--ext name[,name]${CLR_RST}   Extensions to install (omit for core only)"
  echo "  ${CLR_OPT}--force${CLR_RST}             Overwrite existing files without prompting"
  echo "  ${CLR_OPT}-h, --help${CLR_RST}          Show this help"
  echo ""
  echo "${CLR_BOLD}Examples:${CLR_RST}"
  echo "  ${CLR_CMD}garage install${CLR_RST}                           Core only (default)"
  echo "  ${CLR_CMD}garage install${CLR_RST} ${CLR_OPT}--ext agile,dev-common${CLR_RST}   Core + listed extensions"
  echo ""
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FORCE=0
UPDATE_MODE=0
EXT_FILTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    --force) FORCE=1; shift ;;
    --update-mode) UPDATE_MODE=1; shift ;;
    --ext)
      shift
      EXT_FILTER="${1:-}"
      [ -n "$EXT_FILTER" ] || { echo "${CLR_ERR}Error: --ext requires a value.${CLR_RST}" >&2; exit 1; }
      shift
      ;;
    *)
      echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2
      show_help
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate environment
# ---------------------------------------------------------------------------
if [ -z "${AI_DEV_GARAGE:-}" ]; then
  echo "${CLR_ERR}Error: AI_DEV_GARAGE is not set (pipeline repo root).${CLR_RST}" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "${CLR_ERR}Error: python3 is required.${CLR_RST}" >&2
  exit 1
fi

PIPELINE_ROOT="$(cd "$AI_DEV_GARAGE" && pwd)"
CORE_DIR="$PIPELINE_ROOT/core"
EXT_ROOT="$PIPELINE_ROOT/extensions"

if [ ! -d "$CORE_DIR" ]; then
  echo "${CLR_ERR}Error: core/ not found: $CORE_DIR${CLR_RST}" >&2
  exit 1
fi

GARAGE_HOME="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}"
GARAGE_HOME="$(mkdir -p "$GARAGE_HOME" && cd "$GARAGE_HOME" && pwd)"
TARGET_HOME="${TARGET_HOME:-$HOME}"

# ---------------------------------------------------------------------------
# Resolve extensions to install
#   --ext given: use that list
#   update mode: re-install extensions already recorded in ~/.ai-dev-garage/manifest.yaml
#   fresh install: core only (empty EXT_LIST)
# ---------------------------------------------------------------------------
if [ -n "$EXT_FILTER" ]; then
  IFS=',' read -r -a EXT_LIST <<< "$EXT_FILTER"
elif [ "$UPDATE_MODE" -eq 1 ]; then
  EXT_LIST=()
  while IFS= read -r ext_id; do
    [ -n "$ext_id" ] && EXT_LIST+=("$ext_id")
  done < <(python3 "$MANIFEST_PY" list-installed-extensions --target "$GARAGE_HOME/manifest.yaml" 2>/dev/null || true)
else
  EXT_LIST=()
fi

# ---------------------------------------------------------------------------
# Helper: copy a single file, respecting lock state in update mode
# ---------------------------------------------------------------------------
copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "${CLR_CMD}  + $(basename "$dest")${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Install core
# ---------------------------------------------------------------------------
install_core() {
  if [ "$UPDATE_MODE" -eq 1 ]; then
    local master_manifest="$GARAGE_HOME/manifest.yaml"
    if python3 "$MANIFEST_PY" is-locked --target "$master_manifest" core 2>/dev/null; then
      echo "${CLR_WARN}  core is locked — skipping.${CLR_RST}"
      return 0
    fi
  fi

  echo "${CLR_DIM}Installing core...${CLR_RST}"

  local subdirs=(agents commands skills rules memory)
  for d in "${subdirs[@]}"; do
    mkdir -p "$GARAGE_HOME/$d"
  done

  # agents
  if [ -d "$CORE_DIR/agents" ]; then
    for f in "$CORE_DIR/agents"/*.md; do
      [ -f "$f" ] || continue
      copy_file "$f" "$GARAGE_HOME/agents/$(basename "$f")"
    done
  fi

  # commands (flat)
  if [ -d "$CORE_DIR/commands" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/commands/$(basename "$f")"
    done < <(find "$CORE_DIR/commands" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # commands/ai-dev-garage/ (preserved as subfolder)
  if [ -d "$CORE_DIR/commands/ai-dev-garage" ]; then
    mkdir -p "$GARAGE_HOME/commands/ai-dev-garage"
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/commands/ai-dev-garage/$(basename "$f")"
    done < <(find "$CORE_DIR/commands/ai-dev-garage" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # rules
  if [ -d "$CORE_DIR/rules" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/rules/$(basename "$f")"
    done < <(find "$CORE_DIR/rules" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdc" \) -print0 2>/dev/null)
  fi

  # memory
  if [ -d "$CORE_DIR/memory" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/memory/$(basename "$f")"
    done < <(find "$CORE_DIR/memory" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # skills (directories)
  if [ -d "$CORE_DIR/skills" ]; then
    for d in "$CORE_DIR/skills"/*; do
      [ -d "$d" ] || continue
      local base
      base="$(basename "$d")"
      local dest="$GARAGE_HOME/skills/$base"
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
# Install one extension
# ---------------------------------------------------------------------------
install_extension() {
  local ext_id="$1"

  if [ "$UPDATE_MODE" -eq 1 ]; then
    local master_manifest="$GARAGE_HOME/manifest.yaml"
    if python3 "$MANIFEST_PY" is-locked --target "$master_manifest" "$ext_id" 2>/dev/null; then
      echo "${CLR_WARN}  extension ${CLR_OPT}$ext_id${CLR_WARN} is locked — skipping.${CLR_RST}"
      return 0
    fi
  fi

  local ext_dir="$EXT_ROOT/$ext_id"
  if [ ! -d "$ext_dir" ]; then
    echo "${CLR_WARN}  Warning: extension '$ext_id' has no directory: $ext_dir${CLR_RST}" >&2
    return 0
  fi

  if [ ! -f "$ext_dir/manifest.yaml" ]; then
    echo "${CLR_WARN}  Warning: skip extension '$ext_id' (no manifest.yaml)${CLR_RST}" >&2
    return 0
  fi

  echo "${CLR_DIM}Installing extension ${CLR_OPT}$ext_id${CLR_DIM}...${CLR_RST}"

  # agents (same basenames as in extension — unique across core + extensions)
  if [ -d "$ext_dir/agents" ]; then
    for f in "$ext_dir/agents"/*.md; do
      [ -f "$f" ] || continue
      copy_file "$f" "$GARAGE_HOME/agents/$(basename "$f")"
    done
  fi

  # commands
  if [ -d "$ext_dir/commands" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/commands/$(basename "$f")"
    done < <(find "$ext_dir/commands" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # rules
  if [ -d "$ext_dir/rules" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/rules/$(basename "$f")"
    done < <(find "$ext_dir/rules" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdc" \) -print0 2>/dev/null)
  fi

  # memory
  if [ -d "$ext_dir/memory" ]; then
    while IFS= read -r -d '' f; do
      copy_file "$f" "$GARAGE_HOME/memory/$(basename "$f")"
    done < <(find "$ext_dir/memory" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
  fi

  # skills
  if [ -d "$ext_dir/skills" ]; then
    for d in "$ext_dir/skills"/*; do
      [ -d "$d" ] || continue
      local skill_base
      skill_base="$(basename "$d")"
      local dest="$GARAGE_HOME/skills/$skill_base"
      mkdir -p "$dest"
      while IFS= read -r -d '' f; do
        local rel="${f#$d/}"
        mkdir -p "$dest/$(dirname "$rel")"
        cp "$f" "$dest/$rel"
      done < <(find "$d" -type f -print0 2>/dev/null)
      echo "${CLR_CMD}  + skills/$skill_base/${CLR_RST}"
    done
  fi

  echo "${CLR_CMD}  extension ${CLR_OPT}$ext_id${CLR_CMD} installed.${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Run installs
# ---------------------------------------------------------------------------
install_core

# bash 3.2 + set -u: "${EXT_LIST[@]}" is an error when the array is empty — use index loops
for (( _i=0; _i<${#EXT_LIST[@]}; _i++ )); do
  ext_id="${EXT_LIST[_i]}"
  [ -n "$ext_id" ] || continue
  install_extension "$ext_id"
done

# ---------------------------------------------------------------------------
# Collision detection
# ---------------------------------------------------------------------------
check_dupes_in_dir() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local dupes
  dupes="$(find "$dir" -maxdepth 1 -type f 2>/dev/null | sed 's/.*\///' | sort | uniq -d)"
  if [ -n "$dupes" ]; then
    echo "${CLR_ERR}Error: duplicate filenames in $(basename "$dir")/:${CLR_RST}" >&2
    echo "$dupes" >&2
    exit 1
  fi
}
check_dupes_in_dir "$GARAGE_HOME/agents"
check_dupes_in_dir "$GARAGE_HOME/commands"
check_dupes_in_dir "$GARAGE_HOME/rules"
check_dupes_in_dir "$GARAGE_HOME/memory"

skill_dupes="$(find "$GARAGE_HOME/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's/.*\///' | sort | uniq -d)"
if [ -n "$skill_dupes" ]; then
  echo "${CLR_ERR}Error: skill directory collision:${CLR_RST}" >&2
  echo "$skill_dupes" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Write master manifest
# ---------------------------------------------------------------------------
MASTER_MANIFEST="$GARAGE_HOME/manifest.yaml"
CORE_VERSION="$(python3 "$MANIFEST_PY" get-version --component-path "$CORE_DIR" 2>/dev/null || echo "unknown")"

MANIFEST_ARGS=(
  write-master
  --target "$MASTER_MANIFEST"
  --pipeline-repo "$PIPELINE_ROOT"
  --core "$CORE_VERSION"
)
[ "$UPDATE_MODE" -eq 1 ] && MANIFEST_ARGS+=(--preserve-installed-at)

for (( _i=0; _i<${#EXT_LIST[@]}; _i++ )); do
  ext_id="${EXT_LIST[_i]}"
  [ -n "$ext_id" ] || continue
  local_ext_dir="$EXT_ROOT/$ext_id"
  ext_ver="$(python3 "$MANIFEST_PY" get-version --component-path "$local_ext_dir" 2>/dev/null || echo "unknown")"
  MANIFEST_ARGS+=(--ext "${ext_id}=${ext_ver}")
done

python3 "$MANIFEST_PY" "${MANIFEST_ARGS[@]}"
echo "${CLR_CMD}  Master manifest written: $MASTER_MANIFEST${CLR_RST}"

# Also copy garage.yaml for reference
cp "$PIPELINE_ROOT/garage.yaml" "$GARAGE_HOME/garage.yaml"

# ---------------------------------------------------------------------------
# Symlink ~/.cursor and ~/.claude
# ---------------------------------------------------------------------------
subdirs=(agents commands skills rules memory)
CURSOR_ROOT="$TARGET_HOME/.cursor"
CLAUDE_ROOT="$TARGET_HOME/.claude"

echo ""
echo "${CLR_DIM}Setting up symlinks...${CLR_RST}"

for name in "${subdirs[@]}"; do
  check_and_link_dir "$CURSOR_ROOT" "$name" "$GARAGE_HOME/$name"
done

for name in agents commands skills rules; do
  check_and_link_dir "$CLAUDE_ROOT" "$name" "$GARAGE_HOME/$name"
done

# ---------------------------------------------------------------------------
# zshrc (only on fresh global install, not update)
# ---------------------------------------------------------------------------
if [ "$UPDATE_MODE" -eq 0 ] && [ "$TARGET_HOME" = "$HOME" ]; then
  ZSH_RC="${ZDOTDIR:-$HOME}/.zshrc"
  MARK="# ai-dev-garage (added by garage install)"
  if [ -f "$ZSH_RC" ] && grep -qF "$MARK" "$ZSH_RC" 2>/dev/null; then
    echo "${CLR_DIM}~/.zshrc already contains AI_DEV_GARAGE block.${CLR_RST}"
  else
    {
      echo ""
      echo "$MARK"
      echo "export AI_DEV_GARAGE=\"$PIPELINE_ROOT\""
      echo "alias garage=\"$PIPELINE_ROOT/scripts/garage.sh\""
    } >>"$ZSH_RC"
    echo "${CLR_CMD}Appended ${CLR_OPT}AI_DEV_GARAGE${CLR_CMD} + ${CLR_OPT}garage${CLR_CMD} alias to $ZSH_RC${CLR_RST}"
  fi
fi

echo ""
echo "${CLR_CMD}Global install complete.${CLR_RST}"
echo "${CLR_DIM}  Runtime: $GARAGE_HOME${CLR_RST}"
echo "${CLR_DIM}  Cursor:  $CURSOR_ROOT/{agents,commands,skills,rules,memory}${CLR_RST}"
echo "${CLR_DIM}  Claude:  $CLAUDE_ROOT/{agents,commands,skills,rules}${CLR_RST}"

if [ "$UPDATE_MODE" -eq 0 ] && [ "${#EXT_LIST[@]}" -eq 0 ]; then
  echo ""
  echo "${CLR_OPT}Next — extensions:${CLR_RST} only ${CLR_CMD}core${CLR_RST} was installed. Add more when you need them:"
  echo "${CLR_DIM}  ${CLR_CMD}garage install --ext <id>${CLR_DIM}   e.g. ${CLR_CMD}garage install --ext agile${CLR_DIM} or ${CLR_CMD}--ext agile,dev-common${CLR_DIM}"
  echo "${CLR_DIM}  ${CLR_CMD}garage update${CLR_DIM}            refresh files for core + already-installed extensions"
  echo "${CLR_DIM}  IDs live under ${CLR_CMD}\$AI_DEV_GARAGE/extensions/${CLR_DIM}; see ${CLR_CMD}~/.ai-dev-garage/garage.yaml${CLR_DIM} after install.${CLR_RST}"
fi

# Reminder: ~/.zshrc is only read at shell startup unless sourced
if [ "$UPDATE_MODE" -eq 0 ] && [ "$TARGET_HOME" = "$HOME" ]; then
  _ZSH_HINT="${ZDOTDIR:-$HOME}/.zshrc"
  echo ""
  echo "${CLR_OPT}  Shell: run ${CLR_CMD}source \"$_ZSH_HINT\"${CLR_OPT} or open a new terminal so the ${CLR_CMD}garage${CLR_OPT} alias loads.${CLR_RST}"
fi
