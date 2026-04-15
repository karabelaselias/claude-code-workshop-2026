# Claude Code Workshop — Starter Kit

Everything you need to replicate the workflow from the workshop. Run the installer and you're up in under two minutes.

```bash
bash install.sh
```

---

## Files

### `install.sh`
One-shot installer. Run it once on a new machine and it handles everything:
- Installs **Claude Code** via the official native installer
- Installs **haft** (decision engineering MCP server)
- Installs **uv** (Python package manager, required by the Beads plugin)
- Installs **Beads** (issue tracker)
- Copies `CLAUDE.md` to `~/.claude/CLAUDE.md` (backs up any existing file first)
- Copies the **anti-deskilling skill** to `~/.claude/skills/anti-deskilling/` and runs its hook installer (requires `jq` — install with `brew install jq` first)
- Tries to install the **Inter font** via Homebrew if available

---

### `CLAUDE.md`
The global agent instructions file — install to `~/.claude/CLAUDE.md` and it applies to **every project on your machine** automatically. This is Elias's actual working file.

It covers:
- **Anti-Deskilling Gate**: forces Claude to invoke `/anti-deskilling` before architecture, algorithm, security, or irreversible decisions. Also hooked on every Write/Edit.
- **Communication style**: peer engineer mode — direct, dry, no cheerleading, no hedge phrases. Includes a calibration table of preferred vs. avoided language.
- **Thinking principles**: Separation of Concerns, Weakest Link Analysis, Explicit Over Hidden, Reversibility Check — applied to every non-trivial problem.
- **Task execution workflow**: 8-step protocol from understanding the problem through investigation, planning, implementation, debugging, and verification.
- **haft (FPF) reference**: full command table, recommended cycle, inline quick-decision framework, and key concepts (R_eff, evidence decay, CL penalties, Transformer Mandate).
- **Critical reminders**: the 9 rules that matter most, always visible at the bottom of context.

Note: Beads auto-generates a project-level `CLAUDE.md` with issue tracking instructions when you run `bd init`. You don't need to add that manually.

---

### `user-settings.json`
Template for `~/.claude/settings.json` — your **personal global defaults** that apply to all projects.

Copy to `~/.claude/settings.json` and adapt:
- Sets default model to Sonnet and effort to medium
- Pre-approves safe read-only tools and common build commands (`git *`, `npm test`, `pytest`)
- Sets `DISABLE_TELEMETRY=1` and `DISABLE_ERROR_REPORTING=1` via the env key

This is the minimum viable config. Add more allowed tools as you learn what you trust.

---

### `project-settings.json`
Template for `.claude/settings.json` inside a project — **shared with your team via git**.

Copy to `.claude/settings.json` in your repo root and adapt:
- Whitelists project-specific safe tools (`make *`, `cmake *`, `ctest *`)
- Includes a `SessionStart` hook that runs `bd prime` to load open Beads issues into context at the start of every session
- This file is committed to version control so the whole team gets the same tool permissions

Unlike `user-settings.json`, this is per-project and should reflect what's actually safe in that codebase.

---

### `anti-deskilling/`
Elias's actual anti-deskilling skill — a complete, working example of a skill with hooks, evals, and a reference guide. The installer copies this to `~/.claude/skills/anti-deskilling/` and wires the hooks globally.

What it does:
- **PreToolUse hook** — intercepts every `Write` and `Edit` call and checks whether Claude is about to implement something you should be reasoning through yourself (architecture choices, algorithm selection, security patterns, irreversible decisions). If so, it gates and asks.
- **UserPromptSubmit hook** — resets the engagement counter at the start of each prompt so the gate doesn't accumulate across unrelated tasks.
- **`/anti-deskilling`** — invoke manually at any time to trigger the engagement check explicitly.

Structure inside the folder:
- `SKILL.md` — the skill instructions Claude reads
- `scripts/install.sh` — hook installer (run with `--global` for user-wide, default is project-level)
- `scripts/uninstall.sh` — cleanly removes hooks from settings.json
- `scripts/engagement-gate.sh` — the PreToolUse hook script
- `scripts/reset-counter.sh` — the UserPromptSubmit hook script
- `evals/evals.json` — test cases for the Skill Creator eval loop
- `references/setup-guide.md` — explains the HITL/HOTL/HOOTL framework

To install manually if the main installer skipped it (jq missing):
```bash
brew install jq
bash ~/.claude/skills/anti-deskilling/scripts/install.sh --global
```

---

### `SKILL-template.md`
A blank starting point for writing your own Claude skills. Copy it, rename the folder, and fill it in.

Structure:
- YAML frontmatter with `name` and `description` (the description drives when Claude auto-invokes the skill — write it carefully)
- `Purpose` section explaining what the skill improves
- `Instructions` with numbered steps for what Claude should do when triggered
- `Constraints` for positive rules and trade-offs
- `Examples` with good and bad trigger inputs to calibrate invocation

Place the finished file at:
- `~/.claude/skills/<name>/SKILL.md` — personal, all projects
- `.claude/skills/<name>/SKILL.md` — project-scoped, shared via git

Use the Anthropic Skill Creator (`github.com/anthropics/skills`) to test and iterate with an eval loop.

---

### `paper-reviewer-agent.md`
A ready-to-use custom subagent for journal peer review. Drop it at `~/.claude/agents/paper-reviewer.md`.

Configuration:
- **Model**: Opus — deep reasoning needed for methodology assessment
- **Tools**: Read, Grep, Glob only — read-only, cannot modify files
- **Permission mode**: plan — no changes, exploration only

What it does: reads the full paper, summarizes the contribution, assesses methodology and claims, identifies major/minor/typographical issues, and produces a structured referee report with a recommendation. Good template to adapt for other domain-specific review tasks.

---

### `cpp-dev-agent.md`
A ready-to-use custom subagent for C++ development. Drop it at `~/.claude/agents/cpp-dev.md`.

Configuration:
- **Model**: Sonnet — good balance of speed and capability for implementation
- **Tools**: Read, Edit, Write, Bash, Grep, Glob — full access for implementation

What it does: enforces C++17/20 conventions, RAII, const-correctness, IWYU. Knows the CMake build pattern, how to run tests with ctest, and the debugging protocol (ASan → gdb → perf). Adapt the build commands and conventions section to match your actual project.

Both agent files are examples of the subagent pattern — the frontmatter controls model, tools, and permissions; the body is the system prompt. Build your own using the same structure.

---

### `cheatsheet.md`
A single-page reference covering everything from the workshop:
- Install commands for all three tools
- Full Claude Code CLI flags table
- Operating modes and keyboard shortcuts (including `/btw`, `Esc+Esc`, `Option+P`)
- Configuration scopes and permission rule syntax
- Privacy env vars and data retention table (with the September 2025 opt-out note)
- Skills and subagent frontmatter reference
- Model selection guide
- Full haft `/h-*` command table with the FPF cycle
- Beads `bd` command table with solo vs. team setup
- Key links and research references

Print it or keep it open in a second window.

---

## Per-Project Setup Checklist

Once the tools are installed, for each new project:

```bash
cd your-project

haft init           # decision engineering (.haft/ directory)
bd init --quiet     # issue tracking solo, OR:
bd init --team      # issue tracking with team sync

cp /path/to/starter-kit/project-settings.json .claude/settings.json
# edit to match your project's build commands
```

Then in Claude Code:
```
/plugin marketplace add steveyegge/beads
/plugin install beads
```

---

## Privacy Reminder

Since September 2025, Anthropic trains on **Free/Pro/Max data by default**. If you haven't opted out yet:

`claude.ai/settings/data-privacy-controls`

Team and Enterprise accounts are never used for training.

---

## Disclaimer

These materials are provided for educational purposes only. The author makes no warranties, express or implied, regarding the accuracy, completeness, or fitness for any particular purpose of the information contained herein. Third-party tools referenced (Claude Code, haft, Beads) are subject to their own terms and may change at any time. Use at your own risk.

---

© 2026 Elias Karabelas / numericor. All rights reserved. See LICENSE for terms.
