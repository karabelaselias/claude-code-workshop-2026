#!/bin/bash
# Anti-deskilling engagement gate
# PreToolUse hook: gates Write/Edit calls based on change size and
# how many consecutive edits have happened without user input.
#
# Activation rules (gate is SILENT unless all conditions met):
#   1. Not running inside a subagent (agent_id must be empty)
#   2. Permission mode is "default" (acceptEdits / bypassPermissions / plan skip)
#   3. Project has an opt-in signal in cwd or an ancestor directory:
#        .haft/      .quint/      .anti-deskilling/
#        or a CLAUDE.md file containing "anti-deskilling"
#
# Gating tiers (once activated):
#   - Trivial changes (<3 lines edit, <8 lines new file): pass through
#   - New files (8+ lines): always ask — creating files is architecturally significant
#   - Moderate edits (3-20 lines): ask every 2nd consecutive edit
#   - Large edits (20+ lines): always ask
#
# The counter resets every time the user submits a prompt (via reset-counter.sh).

set -e

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# Only gate Write and Edit
if [[ ! "$TOOL" =~ ^(Write|Edit)$ ]]; then
  exit 0
fi

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // "default"')
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$HOOK_CWD" ]] && HOOK_CWD="$PWD"

# --- Activation guards ---

# Subagents have no interactive user to answer "ask" — never gate them.
if [[ -n "$AGENT_ID" ]]; then
  exit 0
fi

# acceptEdits / bypassPermissions / plan: user has explicitly opted out of
# per-edit prompts. Respect the mode.
if [[ "$PERMISSION_MODE" != "default" ]]; then
  exit 0
fi

# Project opt-in signal — walk up from cwd to $HOME looking for any marker.
# This keeps the gate silent in projects where thinking-work isn't the point.
has_signal() {
  local dir="$1"
  [[ -d "$dir/.haft" ]] && return 0
  [[ -d "$dir/.quint" ]] && return 0
  [[ -d "$dir/.anti-deskilling" ]] && return 0
  [[ -f "$dir/CLAUDE.md" ]] && grep -qi 'anti-deskilling' "$dir/CLAUDE.md" 2>/dev/null && return 0
  return 1
}

SIGNAL_FOUND=false
dir="$HOOK_CWD"
while [[ -n "$dir" && "$dir" != "/" && "$dir" != "$HOME/.." ]]; do
  if has_signal "$dir"; then
    SIGNAL_FOUND=true
    break
  fi
  # Stop at $HOME boundary — don't scan outside the user's tree.
  [[ "$dir" == "$HOME" ]] && break
  dir=$(dirname "$dir")
done

if [[ "$SIGNAL_FOUND" != "true" ]]; then
  exit 0
fi

# --- Determine change size ---

CHANGE_LINES=0

if [[ "$TOOL" == "Edit" ]]; then
  OLD=$(echo "$INPUT" | jq -r '.tool_input.old_string // empty')
  NEW=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
  OLD_LINES=$(echo "$OLD" | wc -l | tr -d ' ')
  NEW_LINES=$(echo "$NEW" | wc -l | tr -d ' ')
  CHANGE_LINES=$((OLD_LINES > NEW_LINES ? OLD_LINES : NEW_LINES))
fi

if [[ "$TOOL" == "Write" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
  CHANGE_LINES=$(echo "$CONTENT" | wc -l | tr -d ' ')
fi

# --- Trivial changes: pass through ---

if [[ "$TOOL" == "Edit" && $CHANGE_LINES -lt 3 ]]; then
  exit 0
fi

if [[ "$TOOL" == "Write" && $CHANGE_LINES -lt 8 ]]; then
  exit 0
fi

# --- State tracking ---

STATE_DIR="${TMPDIR:-/tmp}/anti-deskilling"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/session_${SESSION_ID}"

COUNT=0
if [[ -f "$STATE_FILE" ]]; then
  COUNT=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$STATE_FILE"

# --- Gating logic ---

SHOULD_ASK=false
REASON=""

# New files over 10 lines: always ask
if [[ "$TOOL" == "Write" ]]; then
  SHOULD_ASK=true
  REASON="New file: $FILE ($CHANGE_LINES lines). Review the structure before it lands."
fi

# Large edits: always ask
if [[ "$TOOL" == "Edit" && $CHANGE_LINES -gt 20 ]]; then
  SHOULD_ASK=true
  REASON="Large edit: $CHANGE_LINES lines in $FILE. Confirm this is the right approach."
fi

# Moderate edits: ask every 2nd consecutive one
if [[ "$TOOL" == "Edit" && $CHANGE_LINES -ge 3 && $CHANGE_LINES -le 20 ]]; then
  if [[ $((COUNT % 2)) -eq 0 ]]; then
    SHOULD_ASK=true
    REASON="Checkpoint: $COUNT consecutive edits without input. Take a look at where things stand."
  fi
fi

# High consecutive edit count: always ask regardless of size
if [[ $COUNT -ge 5 ]]; then
  SHOULD_ASK=true
  REASON="Drift check: $COUNT consecutive edits without your input. Worth a quick review."
fi

if [[ "$SHOULD_ASK" == "true" ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Anti-deskilling: $REASON"
  }
}
EOF
  exit 0
fi

# Otherwise: allow
exit 0
