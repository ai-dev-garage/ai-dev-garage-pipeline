#!/usr/bin/env bash
#
# pipeline-sync.sh — Optional fetch + interactive pull for the pipeline git checkout.
# Caller must have sourced colors.sh. Sets nothing; uses PIPELINE_ROOT or first argument.
#
# When stdin/stdout are TTYs and local HEAD is behind origin/master, prompts:
#   Pull N new commit(s) from origin/master? [Y/n]:
# Answering n skips git pull and continues (local branch / tests). Non-interactive: pull without asking.
#

garage_sync_pipeline_from_origin() {
  local root="${1:-${PIPELINE_ROOT:-}}"
  [ -n "$root" ] || return 0
  root="$(cd "$root" && pwd)"

  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi
  if ! git -C "$root" fetch origin master --quiet 2>/dev/null; then
    return 0
  fi

  local behind
  behind="$(git -C "$root" rev-list HEAD..origin/master --count 2>/dev/null || echo 0)"
  [ "$behind" -gt 0 ] || return 0

  if [ -t 0 ] && [ -t 1 ]; then
    printf "  ${CLR_OPT}Pull %s new commit(s) from origin/master? [Y/n]: ${CLR_RST}" "$behind"
    local val
    IFS= read -r val </dev/tty
    val="${val:-Y}"
    if [[ "$val" =~ ^[Nn]$ ]]; then
      echo "${CLR_DIM}  Skipping git pull; continuing with local checkout.${CLR_RST}"
      return 0
    fi
  fi

  echo "${CLR_OPT}  Pulling $behind new commit(s) from origin/master...${CLR_RST}"
  git -C "$root" pull --ff-only origin master --quiet 2>/dev/null || \
    echo "${CLR_WARN}  Warning: could not fast-forward. Continuing with local version.${CLR_RST}"
}
