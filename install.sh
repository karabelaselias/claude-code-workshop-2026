#!/usr/bin/env bash
# numericor Claude Code Workshop — Starter Kit Installer
# Installs: Claude Code, haft, Beads, anti-deskilling skill
# Run: bash install.sh

set -e

GREEN='\033[0;32m'
GRAY='\033[0;37m'
NC='\033[0m'

step() { echo -e "\n${GREEN}==>${NC} $1"; }
info() { echo -e "${GRAY}    $1${NC}"; }

echo ""
echo "numericor · Claude Code Workshop · Starter Kit"
echo "-----------------------------------------------"

# ── 1. Claude Code ────────────────────────────────────────────────────────────
step "Installing Claude Code"
curl -fsSL https://claude.ai/install.sh | bash
info "After install, run: claude"
info "Authenticate on first launch via your Anthropic account."

# ── 2. haft ───────────────────────────────────────────────────────────────────
step "Installing haft (decision engineering)"
curl -fsSL https://quint.codes/install.sh | bash
info "Initialize in a project with: haft init"
info "Verify connection with: /h-status"

# ── 3. Beads ──────────────────────────────────────────────────────────────────
step "Installing uv (required by Beads plugin)"
curl -LsSf https://astral.sh/uv/install.sh | sh

step "Installing Beads (issue tracker)"
curl -sSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
info "Solo project:  cd your-project && bd init --quiet"
info "Team project:  cd your-project && bd init --team"

# ── 4. Global CLAUDE.md ───────────────────────────────────────────────────────
step "Installing global CLAUDE.md"
CLAUDE_DIR="$HOME/.claude"
DEST="$CLAUDE_DIR/CLAUDE.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/CLAUDE.md"

mkdir -p "$CLAUDE_DIR"

if [ -f "$DEST" ]; then
  BACKUP="$DEST.backup.$(date +%Y%m%d_%H%M%S)"
  mv "$DEST" "$BACKUP"
  info "Existing CLAUDE.md backed up to: $BACKUP"
fi

cp "$SOURCE" "$DEST"
info "Installed to: $DEST"

# ── 5. Anti-deskilling skill ──────────────────────────────────────────────────
step "Installing anti-deskilling skill"
SKILL_SRC="$SCRIPT_DIR/anti-deskilling"
SKILL_DEST="$HOME/.claude/skills/anti-deskilling"

mkdir -p "$HOME/.claude/skills"

if [ -d "$SKILL_DEST" ]; then
  SKILL_BACKUP="$SKILL_DEST.backup.$(date +%Y%m%d_%H%M%S)"
  mv "$SKILL_DEST" "$SKILL_BACKUP"
  info "Existing skill backed up to: $SKILL_BACKUP"
fi

cp -r "$SKILL_SRC" "$SKILL_DEST"
info "Skill copied to: $SKILL_DEST"

if command -v jq &>/dev/null; then
  bash "$SKILL_DEST/scripts/install.sh" --global
  info "Hooks wired into ~/.claude/settings.json"
else
  echo ""
  echo "  ⚠️  jq not found — skipping hook installation."
  info "Install jq first (brew install jq), then run:"
  info "  bash ~/.claude/skills/anti-deskilling/scripts/install.sh --global"
fi

# ── 6. Inter font (optional) ──────────────────────────────────────────────────
step "Inter font (optional — needed for presentation slides)"
if command -v brew &>/dev/null; then
  brew install --cask font-inter 2>/dev/null && info "Inter installed via Homebrew." \
    || info "Inter may already be installed."
else
  info "Homebrew not found. Download Inter manually from: https://rsms.me/inter"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "-----------------------------------------------"
echo -e "${GREEN}Done.${NC} Next steps:"
echo "  1. Run 'claude' in your project directory"
echo "  2. Run 'haft init' in each project you want decision tracking"
echo "  3. Run 'bd init --quiet' (solo) or 'bd init --team' (team) for issue tracking"
echo "  4. Opt out of AI training: claude.ai/settings/data-privacy-controls"
echo "  5. Anti-deskilling hooks are active — /anti-deskilling to invoke manually"
echo ""
