#Requires -Version 5.1
# +==================================================================+
# |  Claude Code -- Session Launcher (Windows)                       |
# |  VS Code: Claude + git watch tip                                  |
# |  Windows Terminal: Claude (left 60%) + git watch (right 40%)     |
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

# --- Detect VS Code terminal --------------------------------------

$InVSCode = $env:TERM_PROGRAM -eq "vscode" -or $null -ne $env:VSCODE_INJECTION

# --- Launch -------------------------------------------------------

if ($InVSCode) {
    # Inside VS Code: run Claude in the integrated terminal
    Write-Host ""
    Write-Host "+--------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  Git watch split pane:               |" -ForegroundColor Cyan
    Write-Host "|  1. Click the split icon (or Ctrl+Shift+5) in the terminal panel" -ForegroundColor Cyan
    Write-Host "|  2. Run:  .\scripts\git-watch.ps1    |" -ForegroundColor Cyan
    Write-Host "|  3. Click back on the Claude pane    |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    claude --dangerously-skip-permissions
} elseif (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    # Standalone: Windows Terminal split pane -- Claude (left 60%) + git watch (right 40%)
    $gitWatch = "powershell -ExecutionPolicy Bypass -NoProfile -File `"$ProjectDir\scripts\git-watch.ps1`""

    wt --title "CLAUDE [$SessionName]" -d $ProjectDir `
        cmd /c "set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && claude --dangerously-skip-permissions" `
        `; split-pane -V -s 0.4 --title "GIT WATCH" -d $ProjectDir `
        $gitWatch
} else {
    Write-Host "[i] Tip: Install Windows Terminal for split-pane view" -ForegroundColor Cyan
    Write-Host "    winget install Microsoft.WindowsTerminal" -ForegroundColor Cyan
    Write-Host ""
    claude --dangerously-skip-permissions
}
