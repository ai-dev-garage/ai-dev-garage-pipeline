#!/usr/bin/env bash
#
# check-dirs.sh — Detect pre-existing real data in .cursor/.claude subdirectories
# and prompt the user what to do before symlinking.
#
# Exports one function: check_and_link_dir
#
# Usage (source this file, then call the function):
#   source "$(dirname "$0")/internal/check-dirs.sh"
#   check_and_link_dir <tool-root> <subdir-name> <garage-target-dir>
#
#   tool-root        e.g. ~/.cursor or /project/.cursor
#   subdir-name      e.g. agents, skills, rules, commands, memory
#   garage-target    e.g. ~/.ai-dev-garage/agents (the actual directory to link to)
#
# Returns 0 always; skipping a dir is not an error.
#

# Ensure colors are available (safe to re-source)
_CHECK_DIRS_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$_CHECK_DIRS_SCRIPT/colors.sh"

# ---------------------------------------------------------------------------
# _dir_has_real_content <dir>
#   Returns 0 (true) if the directory contains anything besides .gitkeep
# ---------------------------------------------------------------------------
_dir_has_real_content() {
  local dir="$1"
  [ -d "$dir" ] || return 1
  local count
  count=$(find "$dir" -mindepth 1 -not -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -gt 0 ]
}

# ---------------------------------------------------------------------------
# check_and_link_dir <tool-root> <subdir-name> <garage-target-dir>
# ---------------------------------------------------------------------------
check_and_link_dir() {
  local tool_root="$1"
  local name="$2"
  local garage_target="$3"
  local linkpath="$tool_root/$name"

  mkdir -p "$tool_root"

  # Case 1: already a symlink
  if [ -L "$linkpath" ]; then
    local cur
    cur="$(readlink "$linkpath" || true)"
    if [ "$cur" = "$garage_target" ]; then
      echo "${CLR_DIM}  Symlink OK: $linkpath${CLR_RST}"
      return 0
    else
      echo "${CLR_WARN}  Warning: $linkpath is a symlink pointing elsewhere ($cur).${CLR_RST}"
      printf "  ${CLR_OPT}[R]${CLR_RST}e-link to $garage_target  ${CLR_OPT}[S]${CLR_RST}kip? [R/s]: "
      local ans
      read -r ans </dev/tty
      ans="${ans:-R}"
      if [[ "$ans" =~ ^[Ss]$ ]]; then
        echo "${CLR_DIM}  Skipped: $linkpath${CLR_RST}"
        return 0
      fi
      rm -f "$linkpath"
      ln -sfn "$garage_target" "$linkpath"
      echo "${CLR_CMD}  Re-linked: $linkpath -> $garage_target${CLR_RST}"
      return 0
    fi
  fi

  # Case 2: real directory with content
  if [ -d "$linkpath" ] && _dir_has_real_content "$linkpath"; then
    local count
    count=$(find "$linkpath" -mindepth 1 -not -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
    echo ""
    echo "${CLR_WARN}  Warning: ${CLR_OPT}$linkpath${CLR_WARN} is not empty (${count} item(s)).${CLR_RST}"
    echo "${CLR_DIM}  We will symlink this directory to $garage_target.${CLR_RST}"
    echo ""
    echo "  What should we do with the existing contents?"
    echo "  ${CLR_OPT}[T]${CLR_RST}ransfer — move contents into $garage_target, then symlink"
    echo "  ${CLR_OPT}[W]${CLR_RST}ipe     — delete contents, then symlink"
    echo "  ${CLR_OPT}[S]${CLR_RST}kip     — leave as-is, do NOT symlink"
    echo ""
    printf "  Choice [T/w/s]: "
    local ans
    read -r ans </dev/tty
    ans="${ans:-T}"

    case "$ans" in
      [Tt]*)
        echo "${CLR_DIM}  Transferring contents of $linkpath → $garage_target ...${CLR_RST}"
        mkdir -p "$garage_target"
        # Move all files (including hidden, excluding . and ..)
        find "$linkpath" -mindepth 1 -maxdepth 1 | while IFS= read -r item; do
          local base
          base="$(basename "$item")"
          if [ -e "$garage_target/$base" ]; then
            echo "${CLR_WARN}  Skipping existing: $garage_target/$base${CLR_RST}"
          else
            mv "$item" "$garage_target/$base"
            echo "${CLR_CMD}  Moved: $base${CLR_RST}"
          fi
        done
        rm -rf "$linkpath"
        ln -sfn "$garage_target" "$linkpath"
        echo "${CLR_CMD}  Linked: $linkpath -> $garage_target${CLR_RST}"
        ;;
      [Ww]*)
        echo "${CLR_WARN}  Wiping $linkpath ...${CLR_RST}"
        rm -rf "$linkpath"
        ln -sfn "$garage_target" "$linkpath"
        echo "${CLR_CMD}  Linked: $linkpath -> $garage_target${CLR_RST}"
        ;;
      *)
        echo "${CLR_DIM}  Skipped: $linkpath${CLR_RST}"
        ;;
    esac
    return 0
  fi

  # Case 3: directory is empty or doesn't exist — safe to replace/create
  [ -d "$linkpath" ] && rm -rf "$linkpath"
  ln -sfn "$garage_target" "$linkpath"
  echo "${CLR_CMD}  Linked: $linkpath -> $garage_target${CLR_RST}"
}
