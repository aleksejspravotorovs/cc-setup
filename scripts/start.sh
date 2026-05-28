#!/usr/bin/env bash
set -euo pipefail

# SCRIPT_DIR = where start.sh lives (cc-setup repo) — used to find tmux config
# WORK_DIR   = where the user wants to work — defaults to $PWD (e.g. folder open in VS Code)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="${1:-$(pwd)}"
SESSION="$(basename "$WORK_DIR" | tr '[:upper:].' '[:lower:]-')"
TMUX_CONF="$SCRIPT_DIR/.tmux.agent.conf"

command -v tmux  >/dev/null 2>&1 || { echo "tmux not found — run ./scripts/setup.sh to install"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "claude not found — run ./scripts/setup.sh to install"; exit 1; }

# Kill previous session if exists
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Build tmux flags — use agent config if present
TMUX_FLAGS=()
if [ -f "$TMUX_CONF" ]; then
  TMUX_FLAGS+=(-f "$TMUX_CONF")
fi

# Prevent VS Code shell integration from conflicting with tmux panes
# (fixes the "extensions want to relaunch the terminal" warning in VS Code)
unset VSCODE_SHELL_INTEGRATION VSCODE_INJECTION 2>/dev/null || true

# Create session in project dir
tmux "${TMUX_FLAGS[@]}" new-session -d -s "$SESSION" -c "$WORK_DIR"

# Set agent teams env var for the session (inherited by teammate panes)
tmux set-environment -t "$SESSION" CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1

# Clean VS Code env vars from session so new panes don't inherit them
tmux set-environment -t "$SESSION" -u VSCODE_SHELL_INTEGRATION 2>/dev/null || true
tmux set-environment -t "$SESSION" -u VSCODE_INJECTION 2>/dev/null || true

# Single full-width Claude pane
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux select-pane -t "$SESSION:0.0" -T "CLAUDE"

# Left pane: launch Claude with agent teams enabled
# Official Agent Teams: teammates auto-appear as tmux split panes
# Requires: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (env) + teammateMode: "tmux" (settings)
tmux send-keys -t "$SESSION:0.0" "export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && claude --dangerously-skip-permissions" C-m

# Focus Claude pane
tmux select-pane -t "$SESSION:0.0"
exec tmux attach -t "$SESSION"
