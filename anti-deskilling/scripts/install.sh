#!/bin/bash
# Anti-deskilling hook installer
# Merges hooks into Claude Code settings without clobbering existing config.
#
# Usage:
#   ./install.sh              # Install to project settings (.claude/settings.json)
#   ./install.sh --global     # Install to user settings (~/.claude/settings.json)
#   ./install.sh --uninstall  # Remove hooks (same as running uninstall.sh)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Parse args
SCOPE="project"
if [[ "$1" == "--global" ]]; then
  SCOPE="global"
elif [[ "$1" == "--uninstall" ]]; then
  exec "$SCRIPT_DIR/uninstall.sh" "$@"
fi

# Determine settings file
if [[ "$SCOPE" == "global" ]]; then
  SETTINGS_DIR="$HOME/.claude"
  SETTINGS_FILE="$SETTINGS_DIR/settings.json"
else
  SETTINGS_DIR=".claude"
  SETTINGS_FILE="$SETTINGS_DIR/settings.json"
fi

# Ensure jq is available
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "  macOS:  brew install jq"
  echo "  Linux:  sudo apt-get install jq"
  exit 1
fi

# Make hook scripts executable
chmod +x "$SCRIPT_DIR/engagement-gate.sh"
chmod +x "$SCRIPT_DIR/reset-counter.sh"

# Create settings dir if needed
mkdir -p "$SETTINGS_DIR"

# Start from existing settings or empty object
if [[ -f "$SETTINGS_FILE" ]]; then
  SETTINGS=$(cat "$SETTINGS_FILE")
else
  SETTINGS='{}'
fi

# Check if anti-deskilling hooks already exist
if echo "$SETTINGS" | jq -e '.hooks.PreToolUse[]?.hooks[]?.command' 2>/dev/null | grep -q "engagement-gate.sh"; then
  echo "Anti-deskilling hooks are already installed in $SETTINGS_FILE"
  echo "Run ./uninstall.sh to remove them first if you want to reinstall."
  exit 0
fi

# Build the hook entries using absolute paths
GATE_PATH="$SKILL_DIR/scripts/engagement-gate.sh"
RESET_PATH="$SKILL_DIR/scripts/reset-counter.sh"

# Merge hooks into settings
SETTINGS=$(echo "$SETTINGS" | jq --arg gate "$GATE_PATH" --arg reset "$RESET_PATH" '
  # Ensure hooks object exists
  .hooks //= {} |

  # Add PreToolUse hook (append to existing array or create new)
  .hooks.PreToolUse = (.hooks.PreToolUse // []) + [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": $gate
    }]
  }] |

  # Add UserPromptSubmit hook
  .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": $reset
    }]
  }]
')

echo "$SETTINGS" | jq '.' > "$SETTINGS_FILE"

echo "Anti-deskilling hooks installed successfully."
echo ""
echo "Settings file: $SETTINGS_FILE"
echo "Hooks added:"
echo "  - PreToolUse gate on Write|Edit  -> $GATE_PATH"
echo "  - UserPromptSubmit counter reset -> $RESET_PATH"
echo ""
echo "The hooks will take effect in your next Claude Code session."
echo "To remove: $SCRIPT_DIR/uninstall.sh $(if [[ "$SCOPE" == "global" ]]; then echo "--global"; fi)"
