#!/usr/bin/env bash
# stop.sh - cleanly tear down this project's agent-team tmux session.
# Kills the session created by scripts/start.sh (same name derivation), which
# terminates the lead + all teammate panes. Use at session end or to clear
# orphaned panes (Claude Code issue #29787).
set -uo pipefail
WORK_DIR="${1:-$(pwd)}"
SESSION="$(basename "$WORK_DIR" | tr '[:upper:].' '[:lower:]-')"
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Killing agent-team session: $SESSION"
  tmux kill-session -t "$SESSION"
  echo "Done - lead + all teammate panes for '$SESSION' terminated."
else
  echo "No active agent-team session named '$SESSION'."
  echo "Active tmux sessions:"; tmux ls 2>/dev/null || echo "  (none)"
fi
