#!/usr/bin/env bash
#
# colors.sh — Shared terminal color definitions for all AI Dev Garage scripts.
#
# Source this file: source "$(dirname "$0")/internal/colors.sh"
# (adjust path depending on caller location)
#
# Color convention:
#   CLR_CMD   green   — command names, script names, success messages, installed assets
#   CLR_OPT   orange  — option names, flag values, extension names, locked indicators
#   CLR_ERR   red     — errors, fatal messages
#   CLR_WARN  yellow  — warnings (non-fatal)
#   CLR_DIM   grey    — neutral descriptive text, paths, explanations
#   CLR_BOLD  bold    — section headers
#   CLR_RST          — reset all attributes
#
# Falls back to empty strings when stdout is not a terminal (piped, CI, etc.)
#

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  CLR_CMD=$(tput setaf 2)    # green
  CLR_OPT=$(tput setaf 3)    # yellow/orange
  CLR_ERR=$(tput setaf 1)    # red
  CLR_WARN=$(tput setaf 3)   # yellow (same as OPT)
  CLR_DIM=$(tput setaf 7)    # grey/white
  CLR_BOLD=$(tput bold)      # bold
  CLR_RST=$(tput sgr0)       # reset
else
  CLR_CMD=""
  CLR_OPT=""
  CLR_ERR=""
  CLR_WARN=""
  CLR_DIM=""
  CLR_BOLD=""
  CLR_RST=""
fi
