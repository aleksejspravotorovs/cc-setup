#Requires -Version 5.1
# +==================================================================+
# |  Claude Code -- Session Launcher (Windows)                       |
# |  Launches Claude inside tmux (via WSL) for split-pane agent      |
# |  teams. Teammates auto-appear as tmux panes.                     |
# +==================================================================+

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

$SessionName = (Split-Path -Leaf $ProjectDir).ToLower() -replace '[.\s]', '-'

# --- Pre-flight ---------------------------------------------------

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "[X] WSL not found -- required for tmux split-pane agent teams" -ForegroundColor Red
    Write-Host "    Install: wsl --install" -ForegroundColor White
    Write-Host "    Then restart your computer and re-run: .\scripts\setup.ps1" -ForegroundColor White
    exit 1
}

# Check tmux is available in WSL
$tmuxCheck = wsl bash -c "command -v tmux" 2>$null
if (-not $tmuxCheck) {
    Write-Host "[X] tmux not found in WSL -- run .\scripts\setup.ps1 to install" -ForegroundColor Red
    exit 1
}

# Check claude is available in WSL
$claudeCheck = wsl bash -c "command -v claude" 2>$null
if (-not $claudeCheck) {
    Write-Host "[X] Claude CLI not found in WSL -- run .\scripts\setup.ps1 to install" -ForegroundColor Red
    exit 1
}

# --- Convert Windows path to WSL path -----------------------------

$wslPath = (wsl wslpath -u "$ProjectDir").Trim()

# --- Launch Claude in tmux via WSL --------------------------------

Write-Host ""
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "|  Claude Code -- tmux split-pane mode          |" -ForegroundColor Cyan
Write-Host "|                                              |" -ForegroundColor Cyan
Write-Host "|  Agent teammates auto-appear as tmux panes   |" -ForegroundColor Cyan
Write-Host "|  Alt+Arrow     Navigate between panes        |" -ForegroundColor Cyan
Write-Host "|  Mouse         Click pane to focus            |" -ForegroundColor Cyan
Write-Host "|  Prefix + z    Zoom/unzoom pane              |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# Kill previous session if exists, then create new tmux session with Claude
# The tmux session runs inside WSL with access to the project via /mnt/
$tmuxCmd = @"
cd '$wslPath' && \
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && \
tmux kill-session -t '$SessionName' 2>/dev/null; \
tmux new-session -s '$SessionName' -c '$wslPath' 'claude --dangerously-skip-permissions'
"@

wsl bash -c $tmuxCmd
