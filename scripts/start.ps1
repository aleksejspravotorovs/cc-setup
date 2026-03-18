#Requires -Version 5.1
# +==================================================================+
# |  Claude Code -- Session Launcher (Windows)                       |
# |  VS Code: in-process mode (Shift+Down to cycle teammates)       |
# |  Windows Terminal: standalone with git watch pane                 |
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
    # VS Code: in-process mode (split panes not supported in VS Code terminal)
    # Teammates run inside the same terminal -- use Shift+Down to cycle
    Write-Host ""
    Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  Agent Teams: in-process mode (VS Code)      |" -ForegroundColor Cyan
    Write-Host "|                                              |" -ForegroundColor Cyan
    Write-Host "|  Shift+Down    Cycle through teammates       |" -ForegroundColor Cyan
    Write-Host "|  Enter         View teammate session         |" -ForegroundColor Cyan
    Write-Host "|  Escape        Interrupt teammate turn       |" -ForegroundColor Cyan
    Write-Host "|  Ctrl+T        Toggle task list              |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    claude --dangerously-skip-permissions
} elseif (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    # Standalone: Windows Terminal -- Claude + git watch side pane
    $gitWatch = "powershell -ExecutionPolicy Bypass -NoProfile -File `"$ProjectDir\scripts\git-watch.ps1`""

    wt --title "CLAUDE [$SessionName]" -d $ProjectDir `
        cmd /c "set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && claude --dangerously-skip-permissions" `
        `; split-pane -V -s 0.4 --title "GIT WATCH" -d $ProjectDir `
        $gitWatch
} else {
    Write-Host "[i] Tip: Install Windows Terminal for git watch split-pane view" -ForegroundColor Cyan
    Write-Host "    winget install Microsoft.WindowsTerminal" -ForegroundColor Cyan
    Write-Host ""
    claude --dangerously-skip-permissions
}
