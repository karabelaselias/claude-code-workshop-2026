# Claude Code · haft · Beads — Cheat Sheet

## Install Everything

```bash
# 1. Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# 2. haft (decision engineering)
curl -fsSL https://quint.codes/install.sh | bash

# 3. Beads (issue tracker) — also needs uv
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -sSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

---

## Claude Code

### Essential CLI Flags

| Flag | What it does |
|------|-------------|
| `claude -c` | Continue most recent conversation |
| `claude -r "name"` | Resume a named session |
| `claude -n "name"` | Start session with a display name |
| `claude -p "query"` | One-shot mode (no interactive session) |
| `claude --model opusplan` | Opus for planning, Sonnet for execution (official alias) |
| `claude --model opus` | Specific model: haiku / sonnet / opus / opusplan |
| `claude --effort high` | Reasoning depth: low / medium / high / max (max = Opus 4.6 only, session-scoped) |
| `claude --max-budget-usd 5` | Hard spending cap (print mode `-p` only) |
| `claude --permission-mode plan` | Start read-only in plan mode |
| `claude --allowedTools "Read" "Grep"` | Whitelist specific tools |
| `claude --append-system-prompt-file ./rules.txt` | Add prompt from file |
| `claude --system-prompt "..."` | Replace entire system prompt |
| `claude --bare -p "query"` | Minimal mode, skip all discovery |

### Operating Modes (Shift+Tab to cycle)

| Mode | Behavior |
|------|----------|
| **Normal** (default) | Asks confirmation before every change |
| **Auto-Accept Edits** | Auto-applies file edits, still prompts for shell |
| **Plan Mode** | Read-only exploration, no changes |

Recommended workflow: start in Plan Mode → review → Normal Mode for execution.

### Slash Commands

| Command | What it does |
|---------|-------------|
| `/help` | List all commands and skills |
| `/compact` | Compress conversation context |
| `/clear` | Fresh conversation, same project |
| `/config` | Open settings interface |
| `/init` | Create CLAUDE.md for this project |
| `/plan` | Enter plan mode directly |
| `/agents` | Manage custom subagents |
| `/btw <question>` | Side question — no effect on conversation history |
| `/feedback` | Send feedback to Anthropic |
| `/plugin marketplace add <name>` | Add a plugin marketplace |
| `/plugin install <name>` | Install a plugin |
| `/reload-plugins` | Reload after plugin changes |

### Keyboard Shortcuts

| Shortcut | What it does |
|----------|-------------|
| `Shift+Tab` | Cycle permission modes |
| `Esc + Esc` | Rewind to previous checkpoint (undo Claude's edits) |
| `Option+P` / `Alt+P` | Switch model mid-session |
| `Option+T` / `Alt+T` | Toggle extended thinking |
| `Ctrl+B` | Background current bash command |

### Configuration Scopes (highest priority first)

| Scope | Location | Commit to git? |
|-------|----------|----------------|
| Managed | Org-wide policies | N/A |
| Local | `.claude/settings.local.json` | No (gitignore) |
| Project | `.claude/settings.json` | Yes |
| User | `~/.claude/settings.json` | No (personal) |

Global CLAUDE.md: `~/.claude/CLAUDE.md` — applies to every project.
Project CLAUDE.md: `CLAUDE.md` or `.claude/CLAUDE.md` in repo root.

### Permission Rules (in settings.json)

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(git *)"],
    "deny": ["Bash(rm *)"]
  }
}
```

### Privacy Environment Variables

| Variable | Effect |
|----------|--------|
| `DISABLE_TELEMETRY=1` | No usage metrics to Statsig |
| `DISABLE_ERROR_REPORTING=1` | No error logs to Sentry |
| `DISABLE_FEEDBACK_COMMAND=1` | Disable /feedback command |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` | All of the above + surveys |

Set in shell profile or in `settings.json` under `"env": {}`.

### Data Retention

| Account type | Retention | Training |
|-------------|-----------|----------|
| Team / Enterprise / API | 30 days | Never (default) |
| Free / Pro / Max (opted out) | 30 days | No |
| Free / Pro / Max (default since Sep 2025) | 5 years | **Yes** |
| Enterprise + ZDR | 0 days | Never |

**Action required:** opt out at `claude.ai/settings/data-privacy-controls`

### Skills

```
~/.claude/skills/<name>/SKILL.md     # Personal (all projects)
.claude/skills/<name>/SKILL.md       # Project (shared via git)
```

```markdown
---
name: my-skill
description: When to trigger this skill
---
Instructions for Claude...
```

### Subagents

```
~/.claude/agents/<name>.md           # Personal
.claude/agents/<name>.md             # Project (shared via git)
```

```yaml
---
name: my-agent
description: When to delegate to this agent
model: sonnet          # haiku / sonnet / opus / inherit
tools: Read, Grep      # Restrict available tools
permissionMode: plan   # default / acceptEdits / plan / dontAsk
---
```

Built-in subagents: Explore (Haiku), Plan (inherits), General-purpose (inherits).

### Model Selection

| Model | Best for | Speed | Cost |
|-------|----------|-------|------|
| Haiku | Exploration, quick lookups, simple edits | Fast | Low |
| Sonnet | General coding, reviews, most tasks | Medium | Medium |
| Opus | Architecture, complex debugging, deep reasoning | Slow | High |

---

## haft — Decision Engineering

```bash
haft init             # Initialize in a project (creates .haft/)
haft init --cursor    # For Cursor
haft init --all       # All supported tools
haft doctor           # Diagnose connection issues
```

### FPF Command Reference

| Command | What it does |
|---------|-------------|
| `/h-frame` | Frame the problem — signal, constraints, acceptance criteria |
| `/h-char` | Define comparison dimensions |
| `/h-explore` | Generate distinct solution variants |
| `/h-compare` | Pareto-front comparison with parity enforcement |
| `/h-decide` | Record decision as contract with invariants and rollback |
| `/h-verify` | Scan for stale artifacts, code drift, pending claims |
| `/h-reason` | Auto-selects depth: quick think, step-by-step, or full cycle |
| `/h-note` | Micro-decision with rationale (auto-expires 90 days) |
| `/h-status` | Dashboard — decisions, problems, module coverage |
| `/h-problems` | Active problems with readiness signals |
| `/h-view` | Audience projections: engineer / manager / audit |
| `/h-search` | Full-text search across all artifacts |
| `/h-onboard` | Scan existing project for architecture knowledge |

**Full cycle:**
```
/h-frame → /h-char → /h-explore → /h-compare → /h-decide → /h-verify
```

**Smart entry point:** `/h-reason` — Claude picks the right depth automatically.

---

## Beads — Issue Tracking

```bash
# Solo setup
bd init --quiet

# Team setup (project owner, run once)
# Wizard asks about protected main, creates beads-metadata branch if needed
bd init --team

# Team members joining — that's all, bd init auto-imports existing issues
git clone https://github.com/org/project && cd project
bd init

# Plugin for Claude Code
/plugin marketplace add steveyegge/beads
/plugin install beads
```

### Key bd Commands

| Command | What it does |
|---------|-------------|
| `bd create "Title" -p 1` | Create issue (priority 0–3) |
| `bd ready` | List unblocked open issues |
| `bd update <id> --claim` | Claim an issue atomically |
| `bd close <id>` | Close an issue |
| `bd list` | List all issues |
| `bd show <id>` | Show issue detail |
| `bd dolt push` | Push issue data to remote |
| `bd dolt pull` | Pull issue data from remote |
| `bd doctor` | Diagnose issues |

Note: Beads auto-generates a project-level CLAUDE.md with issue tracking instructions. No manual setup needed.

---

## Key Links

- Claude Code docs: https://code.claude.com/docs
- CLI reference: https://code.claude.com/docs/en/cli-reference
- Data usage policy: https://code.claude.com/docs/en/data-usage
- Privacy opt-out: https://claude.ai/settings/data-privacy-controls
- haft docs: https://quint.codes/docs
- Beads: https://github.com/steveyegge/beads
- Skill Creator: https://github.com/anthropics/skills
- Inter font: https://rsms.me/inter

## References

- Gloaguen et al. (2026): "Evaluating AGENTS.md" — arxiv.org/abs/2602.11988
- SkillsBench (2026): "Evaluating Agent Skills" — arxiv.org/abs/2602.12670
