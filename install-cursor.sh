#!/usr/bin/env bash
# Install AI Garage plugins for Cursor (local testing via symlinks)
# Usage: ./install-cursor.sh [plugin-name...]
#   No args = install all plugins
#   With args = install only named plugins
#
# Example:
#   ./install-cursor.sh                              # install all
#   ./install-cursor.sh ai-garage-core               # install core only
#   ./install-cursor.sh ai-garage-core ai-garage-agile  # install core + agile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
CURSOR_PLUGINS_DIR="$HOME/.cursor/plugins/local"

mkdir -p "$CURSOR_PLUGINS_DIR"

if [ $# -eq 0 ]; then
  TARGETS=(ai-garage-core ai-garage-agile ai-garage-dev-workflow ai-garage-jira)
else
  TARGETS=("$@")
fi

for plugin in "${TARGETS[@]}"; do
  src="$PLUGINS_DIR/$plugin"
  dest="$CURSOR_PLUGINS_DIR/$plugin"

  if [ ! -d "$src" ]; then
    echo "⚠ Plugin not found: $src"
    continue
  fi

  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -d "$dest" ]; then
    echo "⚠ $dest exists and is not a symlink — skipping (remove manually if needed)"
    continue
  fi

  ln -s "$src" "$dest"
  echo "✓ Linked: $dest → $src"
done

echo ""
echo "Done. Restart Cursor to load plugins."
