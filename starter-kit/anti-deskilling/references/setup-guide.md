# Anti-Deskilling Setup Guide

## Prerequisites

- **Claude Code** CLI installed and working
- **jq** installed (`brew install jq` on macOS, `sudo apt-get install jq` on Linux)

## Quick Install

From any project directory:

```bash
# Install to current project (recommended — lets you tune per-project)
/path/to/anti-deskilling/scripts/install.sh

# Or install globally (applies to all projects)
/path/to/anti-deskilling/scripts/install.sh --global
```

The installer:
- Creates hook entries in `.claude/settings.json` (project) or `~/.claude/settings.json` (global)
- Does NOT overwrite existing hooks — it appends alongside them
- Makes the hook scripts executable

## What Gets Installed

Two hooks:

### 1. PreToolUse gate (`engagement-gate.sh`)

Fires before every `Write` or `Edit` tool call — **but only activates
when all three conditions are true**:

1. The call originates from the main session, not a subagent
   (subagents have no interactive human to answer "ask")
2. Permission mode is `default` — `acceptEdits`, `bypassPermissions`,
   and `plan` all skip the gate entirely
3. The cwd (or an ancestor directory up to `$HOME`) has an opt-in
   signal:
   - `.haft/` directory
   - `.quint/` directory
   - `.anti-deskilling/` directory
   - `CLAUDE.md` containing the string `anti-deskilling`

If any condition fails, the hook exits silently and the edit proceeds
normally. This is deliberate: the gate is designed for thinking-work in
projects where you've opted in, not as a global speed bump.

Once the gate is active, it decides whether to pause for confirmation
based on change size:

| Change type | Behavior |
|---|---|
| Trivial edit (<3 lines) | Pass through, no friction |
| Small new file (<8 lines) | Pass through |
| New file (8+ lines) | Always ask — creating files is architecturally significant |
| Moderate edit (3-20 lines) | Ask every 2nd consecutive edit |
| Large edit (20+ lines) | Always ask |
| 5+ consecutive edits without user input | Always ask (drift detection) |

### 2. UserPromptSubmit reset (`reset-counter.sh`)

Fires when you type something. Resets the consecutive edit counter to 0.
This means: every time you engage (type a response, ask a question, give
feedback), the gate relaxes again. It only tightens when Claude is running
on autopilot for a long stretch.

## How It Feels In Practice

**Mechanical tasks** (reformatting, small fixes, boilerplate): you won't
notice the hooks. Changes are small and flow through.

**Medium tasks** (implementing a function, adding a feature): every few
edits, you'll get a confirmation prompt. This is your chance to glance at
what's happening and course-correct. Approve and Claude continues.

**Large changes** (new files, big rewrites): always confirmed. You see
what's about to land before it does.

**Long autonomous runs**: if Claude makes 8+ edits without you saying
anything, you'll get a drift check regardless of edit size. This catches
the "I walked away and Claude rewrote half my codebase" scenario.

## Tuning the Thresholds

The thresholds are in `scripts/engagement-gate.sh`. The relevant lines:

```bash
# Trivial edit threshold (lines)
if [[ "$TOOL" == "Edit" && $CHANGE_LINES -lt 3 ]]; then

# Trivial new file threshold (lines)
if [[ "$TOOL" == "Write" && $CHANGE_LINES -lt 8 ]]; then

# Large edit threshold (lines)
if [[ "$TOOL" == "Edit" && $CHANGE_LINES -gt 20 ]]; then

# Moderate edit frequency (ask every Nth)
if [[ $((COUNT % 2)) -eq 0 ]]; then

# Drift detection threshold (consecutive edits)
if [[ $COUNT -ge 5 ]]; then
```

Adjust these to match your workflow. If you want tighter control, lower
the thresholds. If you find it too chatty, raise them.

## Per-Project Configuration

Install at project level for different thresholds per project:

```bash
cd ~/my-critical-project
/path/to/anti-deskilling/scripts/install.sh
# Then edit .claude/settings.json or the gate script thresholds
```

You can also add a `.anti-deskilling/config.yaml` to classify tasks
(see SKILL.md for the format). The SKILL.md's soft layer uses this to
decide engagement level; the hooks provide the hard enforcement.

## Uninstall

```bash
# Remove from project
/path/to/anti-deskilling/scripts/uninstall.sh

# Remove from global
/path/to/anti-deskilling/scripts/uninstall.sh --global
```

This removes only the anti-deskilling hooks, leaving your other hooks
intact. It also cleans up temporary state files.

## Troubleshooting

**Hooks not firing:**
- Start a new Claude Code session after installing (hooks load at session start)
- Check with `/hooks` in Claude Code to see active hooks
- Verify scripts are executable: `ls -la scripts/*.sh`
- Check activation conditions (see "What Gets Installed" above). The gate
  is silent unless: main session, `default` permission mode, and a project
  signal (`.haft/`, `.quint/`, `.anti-deskilling/`, or `CLAUDE.md`
  mentioning `anti-deskilling`) is present in cwd or an ancestor
- To force the gate on for a project without those markers, create an
  empty `.anti-deskilling/` directory: `mkdir .anti-deskilling`

**Too many prompts:**
- Raise the thresholds in `engagement-gate.sh`
- Or raise the moderate edit frequency from every 3rd to every 5th

**Not enough prompts:**
- Lower the trivial thresholds
- Set drift detection to 4-5 instead of 8

**jq errors:**
- Make sure jq is installed: `which jq`
- Test manually: `echo '{"tool_name":"Edit"}' | ./scripts/engagement-gate.sh`
