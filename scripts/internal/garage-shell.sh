#!/usr/bin/env bash
#
# garage-shell.sh — Interactive TUI menu for AI Dev Garage.
#
# Launched by `garage` with no arguments.
# Arrow keys navigate, Enter selects, Esc/q exits.
# Commands that need arguments prompt inline before executing.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GARAGE_SCRIPTS="$(cd "$SCRIPT_DIR/.." && pwd)"
PIPELINE_ROOT="$(cd "$GARAGE_SCRIPTS/.." && pwd)"
export AI_DEV_GARAGE="${AI_DEV_GARAGE:-$PIPELINE_ROOT}"

# shellcheck source=colors.sh
source "$SCRIPT_DIR/colors.sh"

# ---------------------------------------------------------------------------
# Menu definition: (label, description, command-key)
# ---------------------------------------------------------------------------
MENU_LABELS=(
  "install (global)"
  "install (project)"
  "update  (global)"
  "update  (project)"
  "status  (global)"
  "status  (project)"
  "lock    component"
  "unlock  component"
  "export  3rd-party configs"
  "quit"
)
MENU_DESCS=(
  "Install core + extensions to ~/.ai-dev-garage"
  "Install core/extensions into a specific project"
  "Pull latest and update global installation"
  "Pull latest and update a project installation"
  "Show globally installed components and versions"
  "Show components installed in a project"
  "Lock a component against future updates"
  "Unlock a previously locked component"
  "Import skills/agents/rules/commands from another directory"
  "Exit garage"
)
MENU_KEYS=(
  "install-global"
  "install-project"
  "update-global"
  "update-project"
  "status-global"
  "status-project"
  "lock"
  "unlock"
  "export"
  "quit"
)
MENU_LEN="${#MENU_LABELS[@]}"
# 0-based row of first menu line: garage_banner_print (8 lines) + hint + blank (2). Keep in sync with banner.sh.
GARAGE_SHELL_MENU_ROW0=10

# Saved terminal state (restored on exit from interactive menu)
GARAGE_STTY_SAVE=""

_garage_shell_cleanup() {
  [ -n "${GARAGE_STTY_SAVE:-}" ] && stty "$GARAGE_STTY_SAVE" 2>/dev/null || stty sane 2>/dev/null || true
  stty echo 2>/dev/null || true
  _cursor_show
  tput cnorm 2>/dev/null || true
}

# Ctrl+C / SIGTERM — leave the menu like q / Esc (tty + cursor restored, then clear + goodbye).
_garage_shell_on_signal_quit() {
  _garage_shell_cleanup
  _clear_screen
  echo "${CLR_DIM}  Goodbye.${CLR_RST}"
  echo ""
  exit 0
}

# Menu mode: byte-at-a-time input so escape sequences are not merged with line buffering (iTerm-friendly).
_garage_menu_tty_on() {
  stty cbreak -echo 2>/dev/null || stty -icanon min 1 time 0 -echo 2>/dev/null || stty -echo 2>/dev/null || true
}

# Restore saved tty before prompts / subprocesses that expect canonical line input.
_garage_menu_tty_off() {
  [ -n "${GARAGE_STTY_SAVE:-}" ] && stty "$GARAGE_STTY_SAVE" 2>/dev/null || stty sane 2>/dev/null || stty echo icanon 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Terminal helpers
# ---------------------------------------------------------------------------
_cursor_hide()  { tput civis 2>/dev/null || true; }
_cursor_show()  { tput cnorm 2>/dev/null || true; }
_clear_screen() { tput clear 2>/dev/null || clear; }
_clear_line_end() { tput el 2>/dev/null || true; }
_move()         { tput cup "$1" "$2" 2>/dev/null || true; }  # row col (0-based)
_bold()         { tput bold  2>/dev/null || true; }
_rst()          { tput sgr0  2>/dev/null || true; }

_term_rows() { tput lines 2>/dev/null || echo 24; }
_term_cols() { tput cols  2>/dev/null || echo 80; }

# ---------------------------------------------------------------------------
# Draw the full menu screen (first paint, after a command, or resize — not every arrow)
# ---------------------------------------------------------------------------
# Optional trailing newline: full layout needs \n; cursor-addressed redraw must not (avoids scroll + cup drift).
_print_menu_line_content() {
  local idx="$1" is_sel="$2"
  local label="${MENU_LABELS[$idx]}"
  local desc="${MENU_DESCS[$idx]}"
  if [ "$is_sel" -eq 1 ]; then
    printf "  ${CLR_CMD}$(_bold)▶  %-28s${CLR_RST}  ${CLR_DIM}%s${CLR_RST}" "$label" "$desc"
  else
    printf "     ${CLR_DIM}%-28s  %s${CLR_RST}" "$label" "$desc"
  fi
}

_print_menu_line() {
  _print_menu_line_content "$1" "$2"
  printf '\n'
}

# Redraw only the two rows that change when selection moves (no clear — avoids scrollback spam).
_redraw_menu_rows() {
  local old_idx="$1" new_idx="$2"
  [ "$old_idx" -eq "$new_idx" ] && return
  _move $((GARAGE_SHELL_MENU_ROW0 + old_idx)) 0
  _clear_line_end
  _print_menu_line_content "$old_idx" 0
  _move $((GARAGE_SHELL_MENU_ROW0 + new_idx)) 0
  _clear_line_end
  _print_menu_line_content "$new_idx" 1
}

_draw_menu_full() {
  local sel="$1"
  _clear_screen

  garage_banner_print

  echo "${CLR_DIM}  Use ${CLR_OPT}↑ ↓${CLR_DIM} to navigate, ${CLR_OPT}Enter${CLR_DIM} to select, ${CLR_OPT}q${CLR_DIM} to quit.${CLR_RST}"
  echo ""

  local i
  for (( i=0; i<MENU_LEN; i++ )); do
    if [ "$i" -eq "$sel" ]; then
      _print_menu_line "$i" 1
    else
      _print_menu_line "$i" 0
    fi
  done

  echo ""
}

# ---------------------------------------------------------------------------
# Read a single keypress (including arrow keys)
# Returns via global KEY variable:
#   "UP", "DOWN", "ENTER", "ESC", or the literal character
#
# iTerm (and others) may send:
#   CSI:  ESC [ A / ESC [ B  (plain arrows)
#   CSI:  ESC [ 1 ; 2 B      (modifiers / application mode — extended)
#   SS3:  ESC O A / ESC O B
#
# A fixed-width read (-sn2) misses extended sequences or splits delivery; leftover
# bytes then echo as "[B".  We read one byte at a time after ESC until the
# sequence is recognizable (requires cbreak set in _interactive_menu).
#
# After ESC, use integer read -t only (bash 3.2 on macOS rejects fractional -t).
# Do not use read -t 0 here: on macOS it often misses buffered CSI bytes, so arrows
# were misread as lone ESC (exits). Blocking read -t 1 per byte is fine for arrows;
# lone Esc waits up to 1s on the first continuation read.
# ---------------------------------------------------------------------------
_read_key() {
  local k1 c seq i
  IFS= read -rsn1 k1 </dev/tty || true
  KEY="$k1"
  if [[ "$k1" != $'\x1b' ]]; then
    if [[ "$k1" == $'\n' ]] || [[ "$k1" == $'\r' ]] || [[ -z "$k1" ]]; then
      KEY="ENTER"
    fi
    return
  fi

  seq=""
  for (( i=0; i<20; i++ )); do
    IFS= read -rsn1 -t 1 c </dev/tty || break
    [[ -z "$c" ]] && break
    seq+="$c"

    # SS3 (two bytes after ESC): O then A/B
    case "$seq" in
      OA) KEY="UP"; return ;;
      OB) KEY="DOWN"; return ;;
    esac
    # Minimal CSI (quote patterns so [ is not a glob class)
    case "$seq" in
      '[A') KEY="UP"; return ;;
      '[B') KEY="DOWN"; return ;;
    esac
    # Extended CSI … A / … B (digits, semicolons, then A or B)
    if [[ "$seq" =~ \[.*A$ ]]; then
      KEY="UP"
      return
    fi
    if [[ "$seq" =~ \[.*B$ ]]; then
      KEY="DOWN"
      return
    fi
  done

  KEY="ESC"
}

# ---------------------------------------------------------------------------
# Prompt helpers (run after menu exits, so terminal is in normal mode)
# ---------------------------------------------------------------------------
_prompt() {
  local msg="$1" default="${2:-}"
  local hint=""
  [ -n "$default" ] && hint=" ${CLR_DIM}[${default}]${CLR_RST}"
  printf "  ${CLR_OPT}%s${CLR_RST}%b: " "$msg" "$hint"
  local val
  IFS= read -r val </dev/tty
  [ -z "$val" ] && val="$default"
  echo "$val"
}

_prompt_yn() {
  local msg="$1" default="${2:-y}"
  local hint="Y/n"
  [[ "$default" == "n" ]] && hint="y/N"
  printf "  ${CLR_OPT}%s${CLR_RST} [%s]: " "$msg" "$hint"
  local val
  IFS= read -r val </dev/tty
  val="${val:-$default}"
  [[ "$val" =~ ^[Yy]$ ]]
}

# ---------------------------------------------------------------------------
# Collect args and execute for each command
# ---------------------------------------------------------------------------
_run_command() {
  local key="$1"
  _cursor_show
  _clear_screen
  echo ""

  case "$key" in

    install-global)
      echo "${CLR_BOLD}  Install — Global${CLR_RST}"
      echo ""
      echo "${CLR_DIM}  Installs core + selected extensions to ~/.ai-dev-garage.${CLR_RST}"
      echo ""
      local ext_input
      ext_input="$(_prompt "Extensions to install (comma-separated, blank = all enabled)" "")"
      local force_flag=""
      _prompt_yn "Overwrite existing files (--force)?" "n" && force_flag="--force" || true
      echo ""
      local args=()
      [ -n "$ext_input" ] && args+=(--ext "$ext_input")
      [ -n "$force_flag" ] && args+=("$force_flag")
      bash "$GARAGE_SCRIPTS/internal/global-install.sh" "${args[@]}"
      ;;

    install-project)
      echo "${CLR_BOLD}  Install — Project${CLR_RST}"
      echo ""
      echo "${CLR_DIM}  Installs into a specific project directory.${CLR_RST}"
      echo ""
      local proj_path
      proj_path="$(_prompt "Project path" ".")"
      local install_core="--core"
      _prompt_yn "Include core?" "y" || install_core=""
      local ext_input
      ext_input="$(_prompt "Extensions to install (comma-separated, blank = none)" "")"
      local force_flag=""
      _prompt_yn "Overwrite existing files (--force)?" "n" && force_flag="--force" || true
      echo ""
      local args=("$proj_path")
      [ -n "$install_core" ] && args+=("$install_core")
      [ -n "$ext_input" ] && args+=(--ext "$ext_input")
      [ -n "$force_flag" ] && args+=("$force_flag")
      bash "$GARAGE_SCRIPTS/internal/project-install.sh" "${args[@]}"
      ;;

    update-global)
      echo "${CLR_BOLD}  Update — Global${CLR_RST}"
      echo ""
      echo "${CLR_DIM}  Pulls latest pipeline changes and re-installs non-locked components.${CLR_RST}"
      echo ""
      _prompt_yn "Proceed?" "y" || { echo "${CLR_DIM}  Cancelled.${CLR_RST}"; return; }
      echo ""
      bash "$GARAGE_SCRIPTS/internal/global-install.sh" --update-mode
      ;;

    update-project)
      echo "${CLR_BOLD}  Update — Project${CLR_RST}"
      echo ""
      local proj_path
      proj_path="$(_prompt "Project path" ".")"
      echo ""
      bash "$GARAGE_SCRIPTS/internal/project-install.sh" "$proj_path" --update-mode
      ;;

    status-global)
      echo "${CLR_BOLD}  Status — Global${CLR_RST}"
      echo ""
      local manifest="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}/manifest.yaml"
      if [ ! -f "$manifest" ]; then
        echo "${CLR_ERR}  No global installation found. Run 'install (global)' first.${CLR_RST}"
      else
        python3 "$SCRIPT_DIR/manifest.py" read-status --target "$manifest" | \
          awk -v CMD="$CLR_CMD" -v DIM="$CLR_DIM" -v OPT="$CLR_OPT" -v RST="$CLR_RST" -v BOLD="$CLR_BOLD" '
          /^pipeline_repo=/ { print DIM "  Pipeline:    " RST substr($0, index($0,"=")+1); next }
          /^installed_at=/  { print DIM "  Installed:   " RST substr($0, index($0,"=")+1); next }
          /^updated_at=/    { print DIM "  Updated:     " RST substr($0, index($0,"=")+1); next }
          /^---$/           { print ""; printf BOLD "  %-22s %-12s %s\n" RST, "Component", "Version", "State"; next }
          NF>0 {
            split($0, f, "\t")
            lock = (f[3] == "locked") ? OPT "locked" RST : DIM "—" RST
            printf "  " CMD "%-22s" RST " " DIM "%-12s" RST " %s\n", f[1], f[2], lock
          }'
      fi
      ;;

    status-project)
      echo "${CLR_BOLD}  Status — Project${CLR_RST}"
      echo ""
      local proj_path
      proj_path="$(_prompt "Project path" ".")"
      local manifest
      manifest="$(cd "$proj_path" && pwd)/.ai-dev-garage/manifest.yaml"
      if [ ! -f "$manifest" ]; then
        echo "${CLR_ERR}  No project installation found at $proj_path/.ai-dev-garage/${CLR_RST}"
      else
        python3 "$SCRIPT_DIR/manifest.py" read-status --target "$manifest" | \
          awk -v CMD="$CLR_CMD" -v DIM="$CLR_DIM" -v OPT="$CLR_OPT" -v RST="$CLR_RST" -v BOLD="$CLR_BOLD" '
          /^pipeline_repo=/ { print DIM "  Pipeline:    " RST substr($0, index($0,"=")+1); next }
          /^installed_at=/  { print DIM "  Installed:   " RST substr($0, index($0,"=")+1); next }
          /^updated_at=/    { print DIM "  Updated:     " RST substr($0, index($0,"=")+1); next }
          /^---$/           { print ""; printf BOLD "  %-22s %-12s %s\n" RST, "Component", "Version", "State"; next }
          NF>0 {
            split($0, f, "\t")
            lock = (f[3] == "locked") ? OPT "locked" RST : DIM "—" RST
            printf "  " CMD "%-22s" RST " " DIM "%-12s" RST " %s\n", f[1], f[2], lock
          }'
      fi
      ;;

    lock|unlock)
      local action="$key"
      echo "${CLR_BOLD}  ${action^} Component${CLR_RST}"
      echo ""
      local component
      component="$(_prompt "Component name (e.g. core, agile)" "")"
      [ -z "$component" ] && { echo "${CLR_DIM}  Cancelled.${CLR_RST}"; return; }
      local proj_path
      proj_path="$(_prompt "Project path (blank = global)" "")"
      local manifest
      if [ -n "$proj_path" ]; then
        manifest="$(cd "$proj_path" && pwd)/.ai-dev-garage/manifest.yaml"
      else
        manifest="${GARAGE_HOME:-"$HOME/.ai-dev-garage"}/manifest.yaml"
      fi
      echo ""
      python3 "$SCRIPT_DIR/manifest.py" "$action" --target "$manifest" "$component"
      echo "${CLR_CMD}  Done.${CLR_RST}"
      ;;

    export)
      echo "${CLR_BOLD}  Export — Import 3rd-party AI configs${CLR_RST}"
      echo ""
      echo "${CLR_DIM}  Reads skills/, agents/, rules/, commands/ from a source directory.${CLR_RST}"
      echo ""
      local src_path
      src_path="$(_prompt "Source directory path" "")"
      [ -z "$src_path" ] && { echo "${CLR_DIM}  Cancelled.${CLR_RST}"; return; }
      local proj_path
      proj_path="$(_prompt "Project path (blank = global)" "")"
      local force_flag=""
      _prompt_yn "Overwrite conflicts without prompting (--force)?" "n" && force_flag="--force" || true
      echo ""
      local args=("$src_path")
      [ -n "$proj_path" ] && args+=(--project "$proj_path")
      [ -n "$force_flag" ] && args+=("$force_flag")
      bash "$GARAGE_SCRIPTS/internal/export-extension.sh" "${args[@]}"
      ;;

    quit)
      echo "${CLR_DIM}  Goodbye.${CLR_RST}"
      echo ""
      return
      ;;
  esac

  echo ""
  echo "${CLR_DIM}  Press any key to return to menu...${CLR_RST}"
  IFS= read -rsn1 </dev/tty || true
}

# ---------------------------------------------------------------------------
# Main interactive loop
# ---------------------------------------------------------------------------
_interactive_menu() {
  local sel=0
  local old_sel
  local menu_needs_full=1
  GARAGE_STTY_SAVE="$(stty -g 2>/dev/null || true)"

  _cursor_hide
  trap '_garage_shell_cleanup; echo' EXIT
  trap '_garage_shell_on_signal_quit' INT TERM

  # Byte-at-a-time + no echo: required for reliable arrow keys under iTerm / cbreak
  _garage_menu_tty_on

  while true; do
    if [ "$menu_needs_full" -eq 1 ]; then
      _draw_menu_full "$sel"
      menu_needs_full=0
    fi

    _read_key

    case "$KEY" in
      UP)
        old_sel=$sel
        (( sel-- )) || true
        [ "$sel" -lt 0 ] && sel=$(( MENU_LEN - 1 ))
        _redraw_menu_rows "$old_sel" "$sel"
        ;;
      DOWN)
        old_sel=$sel
        (( sel++ )) || true
        [ "$sel" -ge "$MENU_LEN" ] && sel=0
        _redraw_menu_rows "$old_sel" "$sel"
        ;;
      ENTER)
        local chosen_key="${MENU_KEYS[$sel]}"
        if [ "$chosen_key" = "quit" ]; then
          _cursor_show
          _clear_screen
          echo "${CLR_DIM}  Goodbye.${CLR_RST}"
          echo ""
          exit 0
        fi
        _cursor_show
        _garage_menu_tty_off
        _run_command "$chosen_key"
        _garage_menu_tty_on
        _cursor_hide
        menu_needs_full=1
        ;;
      q|Q|ESC)
        _cursor_show
        _clear_screen
        echo "${CLR_DIM}  Goodbye.${CLR_RST}"
        echo ""
        exit 0
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------

# Banner is drawn inside _draw_menu after clear (see banner.sh garage_banner_print)
source "$GARAGE_SCRIPTS/banner.sh"

# Optional: network sync before menu (adds startup delay). Use update from the menu instead.
if [[ "${GARAGE_SHELL_SYNC:-}" == "1" ]] && git -C "$PIPELINE_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$PIPELINE_ROOT" fetch origin master --quiet 2>/dev/null; then
    behind="$(git -C "$PIPELINE_ROOT" rev-list HEAD..origin/master --count 2>/dev/null || echo 0)"
    if [ "$behind" -gt 0 ]; then
      echo "${CLR_OPT}  Pulling $behind new commit(s) from origin/master...${CLR_RST}"
      git -C "$PIPELINE_ROOT" pull --ff-only origin master --quiet 2>/dev/null || true
      echo ""
    fi
  fi
fi

_interactive_menu
