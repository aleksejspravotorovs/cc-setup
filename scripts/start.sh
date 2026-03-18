#!/usr/bin/env bash
set -euo pipefail

# Derive session name from project directory (portable across projects)
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="$(basename "$PROJECT_DIR" | tr '[:upper:].' '[:lower:]-')"
TMUX_CONF="$PROJECT_DIR/.tmux.agent.conf"

command -v tmux  >/dev/null 2>&1 || { echo "tmux not found — run ./scripts/setup.sh to install"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "claude not found"; exit 1; }

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
tmux "${TMUX_FLAGS[@]}" new-session -d -s "$SESSION" -c "$PROJECT_DIR"

# Set agent teams env var for the session (inherited by teammate panes)
tmux set-environment -t "$SESSION" CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1

# Clean VS Code env vars from session so new panes don't inherit them
tmux set-environment -t "$SESSION" -u VSCODE_SHELL_INTEGRATION 2>/dev/null || true
tmux set-environment -t "$SESSION" -u VSCODE_INJECTION 2>/dev/null || true

# Layout: left 60% (Claude), right 40% (git watch)
tmux split-window -h -p 40 -t "$SESSION:0.0" -c "$PROJECT_DIR"

# Pane labels
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux select-pane -t "$SESSION:0.0" -T "CLAUDE"
tmux select-pane -t "$SESSION:0.1" -T "GIT WATCH"

# Left pane: launch Claude with agent teams enabled
# Official Agent Teams: teammates auto-appear as tmux split panes
# Requires: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (env) + teammateMode: "auto" (settings)
tmux send-keys -t "$SESSION:0.0" "export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && claude --dangerously-skip-permissions" C-m

# Right pane: git status + diff watch loop
tmux send-keys -t "$SESSION:0.1" "while true; do clear; date; echo '── git status ──'; git status -sb; echo; echo '── changed files ──'; git diff --stat; sleep 3; done" C-m

# Focus Claude pane
tmux select-pane -t "$SESSION:0.0"
exec tmux attach -t "$SESSION"
