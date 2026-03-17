#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code — One-liner bootstrap (macOS / Linux)              ║
# ║  curl -fsSL https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.sh | bash
# ╚══════════════════════════════════════════════════════════════════╝

REPO="https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Claude Code — Downloading scripts   ║"
echo "╚══════════════════════════════════════╝"
echo ""

mkdir -p scripts

for file in setup.sh start.sh; do
  echo "  Downloading scripts/$file..."
  curl -fsSL "$REPO/scripts/$file" -o "scripts/$file"
done

chmod +x scripts/setup.sh scripts/start.sh

echo ""
echo "  Scripts downloaded to scripts/"
echo "  Running setup..."
echo ""

bash scripts/setup.sh
