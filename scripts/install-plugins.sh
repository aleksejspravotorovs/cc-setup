#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code — User-scope plugins + hooks + settings installer  ║
# ║                                                                  ║
# ║  Installs the 6 plugins I use daily, the 5 GSD hook scripts,    ║
# ║  and a sanitized ~/.claude/settings.json template.               ║
# ║                                                                  ║
# ║  Idempotent. Backs up existing ~/.claude/settings.json.          ║
# ╚══════════════════════════════════════════════════════════════════╝

# Locate repo root (this script lives in cc-setup/scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
CFG_SRC="$REPO_DIR/claude-user-config"

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS_FILE="$CLAUDE_HOME/settings.json"
HOOKS_DIR="$CLAUDE_HOME/hooks"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Claude Code — user-scope plugins installer         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  CLAUDE_HOME : $CLAUDE_HOME"
echo "  Source      : $CFG_SRC"
echo ""

# 1) Pre-flight — require claude CLI
if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' CLI not found in PATH."
  echo "Install first: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# 2) Directories
mkdir -p "$HOOKS_DIR"
mkdir -p "$CLAUDE_HOME/plugins"

# 3) Install hook scripts (overwrites — scripts are version-controlled)
echo "→ Copying hook scripts..."
for f in "$CFG_SRC"/hooks/*.js; do
  name="$(basename "$f")"
  cp "$f" "$HOOKS_DIR/$name"
  chmod +x "$HOOKS_DIR/$name"
  echo "    $name"
done

# 4) Install settings.json
# If existing settings.json present and different → back up, then install.
if [[ -f "$SETTINGS_FILE" ]]; then
  BACKUP="$SETTINGS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$SETTINGS_FILE" "$BACKUP"
  echo "→ Backed up existing settings to: $BACKUP"
fi

# Substitute __HOME__ placeholder with actual $HOME
echo "→ Installing settings.json..."
sed "s|__HOME__|$HOME|g" "$CFG_SRC/settings.template.json" > "$SETTINGS_FILE"
echo "    Written to $SETTINGS_FILE"

# 5) Install plugins via claude CLI
# The settings.json already lists `enabledPlugins` + `extraKnownMarketplaces`,
# which Claude Code will auto-install on next launch. But we also explicitly
# add marketplaces + install each plugin so first-run is clean.
echo ""
echo "→ Registering marketplaces..."

MARKETPLACES=(
  "anthropics/claude-plugins-official"
  "thedotmack/claude-mem"
  "vercel/vercel-plugin"
)

for repo in "${MARKETPLACES[@]}"; do
  echo "    Adding $repo"
  claude plugin marketplace add "$repo" 2>/dev/null || \
    echo "      (already registered or CLI unsupported — will fall back to settings.json auto-install)"
done

echo ""
echo "→ Installing plugins..."

PLUGINS=(
  "superpowers@claude-plugins-official"
  "context7@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "code-review@claude-plugins-official"
  "claude-mem@thedotmack"
  "vercel-plugin@vercel-vercel-plugin"
)

for p in "${PLUGINS[@]}"; do
  echo "    $p"
  claude plugin install "$p" 2>/dev/null || \
    echo "      (CLI install failed — settings.json enabledPlugins will install on first launch)"
done

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✓ Done.                                             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Launch Claude: 'claude' (in any project dir)"
echo "  2. First launch downloads any plugins that didn't install above."
echo "  3. Verify with: /plugin (lists installed plugins)."
echo ""
echo "If you use MCP servers (Supabase, context7, Gmail, etc.), add them"
echo "per-project in .mcp.json or via 'claude mcp add' — NOT checked into"
echo "this repo (they contain auth tokens)."
echo ""
