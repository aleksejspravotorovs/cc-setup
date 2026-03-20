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

# --- Helper: safe WSL command execution ---------------------------

function Invoke-WSL {
    param([string]$Command)
    try {
        $result = wsl bash -c $Command 2>&1 | Out-String
        return $result.Trim()
    } catch {
        return ""
    }
}

# --- Pre-flight: WSL with a distro --------------------------------

# Check WSL has a working distro
$distroCheck = ""
try { $distroCheck = wsl echo "ok" 2>&1 | Out-String } catch {}

if ($distroCheck.Trim() -ne "ok") {
    Write-Host "[!!] WSL has no Linux distribution installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Installing Ubuntu (this takes a few minutes)..." -ForegroundColor Cyan
    Write-Host "    You will be asked to create a Unix username and password." -ForegroundColor Cyan
    Write-Host ""

    # Install Ubuntu -- this is interactive (user creates username/password)
    wsl --install -d Ubuntu

    Write-Host ""
    Write-Host "[i] Ubuntu installed. Re-run 'pp' or '.\scripts\start.ps1' to continue." -ForegroundColor Cyan
    exit 0
}

# --- Pre-flight: tmux in WSL -------------------------------------

$tmuxCheck = Invoke-WSL "command -v tmux"
if ($tmuxCheck -notmatch "tmux") {
    Write-Host "[i] Installing tmux in WSL..." -ForegroundColor Cyan
    wsl bash -c "sudo apt-get update -qq && sudo apt-get install -y tmux"
}

# --- Pre-flight: UTF-8 locale in WSL (Cyrillic support) -----------

$localeCheck = Invoke-WSL "locale 2>/dev/null | head -1"
if ($localeCheck -notmatch "UTF-8") {
    Write-Host "[!!] WSL locale is not UTF-8 -- Cyrillic characters will break" -ForegroundColor Yellow
    Write-Host "[i] Installing UTF-8 locale in WSL..." -ForegroundColor Cyan
    wsl bash -c "sudo apt-get update -qq && sudo apt-get install -y locales && sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && sudo sed -i 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && sudo locale-gen && sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
    Write-Host "[OK] UTF-8 locale installed (Cyrillic supported)" -ForegroundColor Green
}

# --- Pre-flight: Claude CLI in WSL --------------------------------

$claudeVer = Invoke-WSL "claude --version 2>/dev/null | head -1"
if ($claudeVer -notmatch "\d+\.\d+") {
    Write-Host "[i] Claude CLI not working in WSL -- installing..." -ForegroundColor Cyan

    # Ensure Node.js
    $nodeCheck = Invoke-WSL "command -v node"
    if ($nodeCheck -notmatch "node") {
        Write-Host "[i] Installing Node.js in WSL..." -ForegroundColor Cyan
        wsl bash -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
    }

    wsl bash -c "sudo npm install -g @anthropic-ai/claude-code"

    # Verify it actually runs
    $claudeVer = Invoke-WSL "claude --version 2>/dev/null | head -1"
    if ($claudeVer -notmatch "\d+\.\d+") {
        Write-Host "[X] Claude CLI installation failed in WSL" -ForegroundColor Red
        Write-Host "    Try manually: wsl bash -c 'sudo npm install -g @anthropic-ai/claude-code'" -ForegroundColor White
        exit 1
    }
}
Write-Host "[OK] Claude CLI in WSL: $claudeVer" -ForegroundColor Green

# --- Convert Windows path to WSL path -----------------------------

$wslPath = (Invoke-WSL "wslpath -u '$ProjectDir'")

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
# Verify the path works
$pathCheck = Invoke-WSL "test -d '$wslPath' && echo ok"
if ($pathCheck -ne "ok") {
    Write-Host "[X] WSL cannot access project path: $wslPath" -ForegroundColor Red
    Write-Host "    Make sure your project is on a Windows drive (C:, D:, etc.)" -ForegroundColor White
    exit 1
}

# Launch tmux -- if claude crashes, keep the pane open to show the error
$tmuxCmd = @"
cd '$wslPath' && \
export LANG=en_US.UTF-8 && \
export LC_ALL=en_US.UTF-8 && \
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && \
tmux kill-session -t '$SessionName' 2>/dev/null; \
tmux -u new-session -s '$SessionName' -c '$wslPath' \
  'claude --dangerously-skip-permissions; echo; echo \"[Claude exited. Press Enter to close.]\"; read'
"@

wsl bash -c $tmuxCmd
