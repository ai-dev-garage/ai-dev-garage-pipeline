#!/usr/bin/env bash
#
# garage-doctor.sh — Compare runtime bundle vs pipeline-expected + manifest custom:
#
# Usage:
#   garage-doctor.sh [--project <path>] [--pipeline-root <path>] [--strict]
#   garage-doctor.sh [--project <path>] --fix   # prompt to delete UNTRACKED paths only
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$SCRIPT_DIR/colors.sh"

MANIFEST_PY="$SCRIPT_DIR/manifest.py"

TARGET_MANIFEST="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}/manifest.yaml"
PIPELINE_ROOT_OVERRIDE=""
STRICT=0
FIX=0
PROJECT_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project)
      shift; PROJECT_PATH="${1:-}"; shift ;;
    --pipeline-root)
      shift; PIPELINE_ROOT_OVERRIDE="${1:-}"; shift ;;
    --strict) STRICT=1; shift ;;
    --fix) FIX=1; shift ;;
    -h|--help)
      echo ""
      echo "${CLR_BOLD}Usage:${CLR_RST} ${CLR_CMD}garage doctor${CLR_RST} [options]"
      echo ""
      echo "  Compare files on disk to what core + installed extensions ship, plus manifest ${CLR_DIM}custom:${CLR_RST}."
      echo "  Lines: ${CLR_DIM}UNTRACKED${CLR_RST} (not pipeline, not custom), ${CLR_DIM}CUSTOM_MISSING${CLR_RST}, ${CLR_DIM}MISSING_EXPECTED${CLR_RST}."
      echo ""
      echo "${CLR_BOLD}Options:${CLR_RST}"
      echo "  ${CLR_OPT}--project <path>${CLR_RST}      Project manifest and bundle"
      echo "  ${CLR_OPT}--pipeline-root <path>${CLR_RST}  Override pipeline repo (default: manifest pipeline_repo)"
      echo "  ${CLR_OPT}--strict${CLR_RST}                Exit 1 if any UNTRACKED lines"
      echo "  ${CLR_OPT}--fix${CLR_RST}                   Prompt to delete UNTRACKED files / skill dirs (destructive)"
      echo ""
      exit 0 ;;
    *)
      echo "${CLR_ERR}Error: Unknown option: $1${CLR_RST}" >&2
      exit 1 ;;
  esac
done

if [ -n "$PROJECT_PATH" ]; then
  TARGET_MANIFEST="$(cd "$PROJECT_PATH" && pwd)/.ai-dev-garage/manifest.yaml"
fi

BUNDLE_ROOT="$(cd "$(dirname "$TARGET_MANIFEST")" && pwd)"

if [ ! -f "$TARGET_MANIFEST" ]; then
  echo "${CLR_ERR}Error: manifest not found: $TARGET_MANIFEST${CLR_RST}" >&2
  exit 1
fi

# Build argv in one array (always non-empty) so "${…[@]}" is safe with set -u on bash 3.2+.
DOC_ARGS=(python3 "$MANIFEST_PY" doctor-check --target "$TARGET_MANIFEST")
[ "$STRICT" -eq 1 ] && DOC_ARGS+=(--strict)
[ -n "$PIPELINE_ROOT_OVERRIDE" ] && DOC_ARGS+=(--pipeline-root "$PIPELINE_ROOT_OVERRIDE")

REPORT="$(mktemp)"
"${DOC_ARGS[@]}" 2>&1 | tee "$REPORT"
DOC_EXIT="${PIPESTATUS[0]}"

if [ "$FIX" -ne 1 ]; then
  rm -f "$REPORT"
  exit "$DOC_EXIT"
fi

UNTRACKED=()
while IFS=$'\t' read -r kind cat name; do
  [ "$kind" = "UNTRACKED" ] || continue
  [ -n "$cat" ] && [ -n "$name" ] || continue
  UNTRACKED+=("$cat:$name")
done < "$REPORT"
rm -f "$REPORT"

if [ "${#UNTRACKED[@]}" -eq 0 ]; then
  echo "${CLR_DIM}Nothing to fix (no UNTRACKED paths).${CLR_RST}"
  exit 0
fi

echo ""
echo "${CLR_WARN}UNTRACKED paths (not from pipeline, not in custom:):${CLR_RST}"
for _u in "${UNTRACKED[@]}"; do
  echo "  ${CLR_DIM}$_u${CLR_RST}"
done
printf "  ${CLR_OPT}Delete all of these from the bundle? [y/N]: ${CLR_RST}"
read -r ans </dev/tty || read -r ans
ans="${ans:-N}"
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  echo "${CLR_DIM}Aborted.${CLR_RST}"
  exit 0
fi

for _u in "${UNTRACKED[@]}"; do
  cat="${_u%%:*}"
  name="${_u#*:}"
  case "$cat" in
    agents|rules|memory)
      f="$BUNDLE_ROOT/$cat/$name"
      if [ -f "$f" ]; then
        rm -f "$f"
        echo "${CLR_CMD}  removed $f${CLR_RST}"
      fi
      ;;
    commands)
      if [[ "$name" == ai-dev-garage/* ]]; then
        f="$BUNDLE_ROOT/commands/$name"
      else
        f="$BUNDLE_ROOT/commands/$name"
      fi
      if [ -f "$f" ]; then
        rm -f "$f"
        echo "${CLR_CMD}  removed $f${CLR_RST}"
      fi
      ;;
    skills)
      d="$BUNDLE_ROOT/skills/$name"
      if [ -d "$d" ]; then
        rm -rf "$d"
        echo "${CLR_CMD}  removed $d${CLR_RST}"
      fi
      ;;
  esac
done

echo "${CLR_CMD}Done.${CLR_RST}"
