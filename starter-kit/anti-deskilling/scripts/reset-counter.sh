#!/bin/bash
# Anti-deskilling counter reset
# UserPromptSubmit hook: resets the consecutive edit counter when the user
# submits a prompt. This proves the user is engaged, so the gate relaxes.

set -e

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')

STATE_DIR="${TMPDIR:-/tmp}/anti-deskilling"
STATE_FILE="$STATE_DIR/session_${SESSION_ID}"

# Reset counter to 0
if [[ -f "$STATE_FILE" ]]; then
  echo "0" > "$STATE_FILE"
fi

exit 0
