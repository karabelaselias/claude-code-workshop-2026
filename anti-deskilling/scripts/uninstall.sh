#!/bin/bash
# Anti-deskilling hook uninstaller
# Removes only the anti-deskilling hooks, leaving other hooks intact.
#
# Usage:
#   ./uninstall.sh            # Remove from project settings
#   ./uninstall.sh --global   # Remove from user settings

set -e

SCOPE="project"
if [[ "$1" == "--global" ]]; then
  SCOPE="global"
fi

if [[ "$SCOPE" == "global" ]]; then
  SETTINGS_FILE="$HOME/.claude/settings.json"
else
  SETTINGS_FILE=".claude/settings.json"
fi

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "No settings file found at $SETTINGS_FILE"
  exit 0
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  exit 1
fi

SETTINGS=$(cat "$SETTINGS_FILE")

# Remove entries whose command contains "engagement-gate.sh" or "reset-counter.sh"
SETTINGS=$(echo "$SETTINGS" | jq '
  if .hooks then
    .hooks |= with_entries(
      .value |= map(
        select(
          (.hooks // []) | all(.command // "" | (contains("engagement-gate.sh") or contains("reset-counter.sh")) | not)
        )
      ) |
      .value |= if length == 0 then empty else . end
    ) |
    if .hooks == {} then del(.hooks) else . end
  else
    .
  end
')

echo "$SETTINGS" | jq '.' > "$SETTINGS_FILE"

# Clean up state files
rm -f "${TMPDIR:-/tmp}"/anti-deskilling/session_* 2>/dev/null

echo "Anti-deskilling hooks removed from $SETTINGS_FILE"
