#!/usr/bin/env bash
# SessionStart hook — loads the plugin playbook and all always-on rules into context.
# CLAUDE_PLUGIN_ROOT is set by Claude Code to this plugin's absolute path.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
PLAYBOOK="${PLUGIN_ROOT}/rules/playbook.md"

if [ ! -f "$PLAYBOOK" ]; then
  exit 0
fi

# --- helpers ---
json_escape() {
  sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | \
    awk '{ if (NR > 1) printf "\\n"; printf "%s", $0 }'
}

resolve_plugin_root() {
  sed "s|{{PLUGIN_ROOT}}|${PLUGIN_ROOT}|g"
}

# --- build context ---

# 1. Start with the playbook (table of all rules)
CONTEXT=$(cat "$PLAYBOOK" | resolve_plugin_root | json_escape)

# 2. Append full content of every always-on rule
#    Convention: grep the playbook table for rows ending with "| Yes |"
#    and extract the rule path from the first column.
ALWAYS_ON_PATHS=$(cat "$PLAYBOOK" | resolve_plugin_root | \
  grep -i '|\s*yes\s*|' | \
  sed 's/.*`\([^`]*\)`.*/\1/' )

for rule_path in $ALWAYS_ON_PATHS; do
  if [ -f "$rule_path" ]; then
    RULE_CONTENT=$(cat "$rule_path" | json_escape)
    CONTEXT="${CONTEXT}\\n\\n---\\n\\n${RULE_CONTENT}"
  fi
done

cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${CONTEXT}"
  }
}
ENDJSON

exit 0
