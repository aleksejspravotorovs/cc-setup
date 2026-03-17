#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code — One-liner bootstrap (macOS / Linux)              ║
# ║  curl -fsSL https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.sh | bash
# ╚══════════════════════════════════════════════════════════════════╝

REPO="https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Claude Code — Downloading files     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Create directory structure
mkdir -p scripts .claude/agents .claude/commands .claude/snapshots

# --- Scripts ---
for file in setup.sh start.sh; do
  echo "  Downloading scripts/$file..."
  curl -fsSL "$REPO/scripts/$file" -o "scripts/$file"
done
chmod +x scripts/setup.sh scripts/start.sh

# --- Agents ---
for agent in lead frontend backend devops skeptic qa researcher; do
  echo "  Downloading .claude/agents/$agent.md..."
  curl -fsSL "$REPO/.claude/agents/$agent.md" -o ".claude/agents/$agent.md"
done

# --- Commands ---
for cmd in prime build-with-agent-team deploy research; do
  echo "  Downloading .claude/commands/$cmd.md..."
  curl -fsSL "$REPO/.claude/commands/$cmd.md" -o ".claude/commands/$cmd.md"
done

# --- Config files (only if not already present) ---
for file in .claude/settings.json .tmux.agent.conf CLAUDE.md AGENTS.md; do
  if [ ! -f "$file" ]; then
    echo "  Downloading $file..."
    curl -fsSL "$REPO/$file" -o "$file"
  else
    echo "  Skipping $file (already exists)"
  fi
done

echo ""
echo "  Files downloaded."
echo "  Running setup..."
echo ""

bash scripts/setup.sh
