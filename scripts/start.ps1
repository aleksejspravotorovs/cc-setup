#Requires -Version 5.1
# +==================================================================+
# |  Claude Code -- Session Launcher (Windows)                       |
# |  Equivalent of scripts/start.sh for Windows + Windows Terminal   |
# +==================================================================+

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

$SessionName = (Split-Path -Leaf $ProjectDir).ToLower() -replace '[.\s]', '-'

# --- Pre-flight ---------------------------------------------------

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "[X] claude not found -- run .\scripts\setup.ps1 to install" -ForegroundColor Red
    exit 1
}

# --- Set agent teams env var --------------------------------------

$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"

# --- Launch -------------------------------------------------------

if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    # Windows Terminal: split pane with Claude (left 60%) + git watch (right 40%)
    $gitWatch = "while (`$true) { Clear-Host; Get-Date -Format 'HH:mm:ss'; Write-Host '-- git status --'; git status -sb; Write-Host ''; Write-Host '-- changed files --'; git diff --stat; Start-Sleep 3 }"

    wt --title "CLAUDE [$SessionName]" -d $ProjectDir `
        cmd /c "set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && claude --dangerously-skip-permissions" `
        `; split-pane -V -s 0.4 --title "GIT WATCH" -d $ProjectDir `
        powershell -NoExit -Command $gitWatch
} else {
    Write-Host "[i] Tip: Install Windows Terminal for split-pane view" -ForegroundColor Cyan
    Write-Host "    winget install Microsoft.WindowsTerminal" -ForegroundColor Cyan
    Write-Host ""
    claude --dangerously-skip-permissions
}
