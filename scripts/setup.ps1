#Requires -Version 5.1
# +==================================================================+
# |  Claude Code + Agent Teams Setup (Windows)                       |
# |  Equivalent of scripts/setup.sh for Windows / PowerShell         |
# |  Idempotent: safe to run multiple times.                          |
# +==================================================================+

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

# --- Logging helpers ----------------------------------------------

function Log($msg)  { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "  [ii] $msg" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "  [XX] $msg" -ForegroundColor Red }

$ExpectedAgents   = @("lead", "frontend", "backend", "devops", "skeptic", "qa", "researcher")
$ExpectedCommands = @("prime", "build-with-agent-team", "deploy", "research")
$VscodeExtensions = @("dbaeumer.vscode-eslint", "bradlc.vscode-tailwindcss", "esbenp.prettier-vscode")

# ===================================================================
# EXECUTION POLICY -- allow scripts to run (profile, pp, pp-setup)
# ===================================================================

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
    Warn "PowerShell execution policy is '$currentPolicy' -- scripts (including your profile) are blocked"
    Write-Host ""
    $setPolicy = Read-Host "    Set to 'RemoteSigned' for current user? (y/n)"
    if ($setPolicy -eq "y") {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            # Non-fatal: policy is set for future sessions but a Process-level
            # override (e.g. -ExecutionPolicy Bypass) takes precedence right now
        }
        Log "Execution policy set to RemoteSigned (takes effect in new terminals)"
    } else {
        Warn "Skipping -- your PowerShell profile and 'pp' commands may not work"
        Info "Fix manually: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    }
} else {
    Log "Execution policy: $currentPolicy"
}

# ===================================================================
# INSTALL HELPERS
# ===================================================================

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-GitBash {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitDir = Split-Path -Parent (Split-Path -Parent (Get-Command git).Source)
        $bashPath = Join-Path $gitDir "bin\bash.exe"
        if (Test-Path $bashPath) {
            Log "Git Bash found: $bashPath"
            return $true
        }
    }

    $commonPaths = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            Log "Git Bash found: $p"
            Info "If Claude cannot find it, set: `$env:CLAUDE_CODE_GIT_BASH_PATH = '$p'"
            return $true
        }
    }

    Warn "Git for Windows is not installed (required by Claude Code)"
    Write-Host ""
    $install = Read-Host "    Install Git for Windows now? (y/n)"
    if ($install -ne "y") {
        Fail "Git for Windows is required. Install: https://git-scm.com/downloads/win"
        return $false
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Info "Installing Git for Windows via winget..."
        winget install Git.Git --accept-source-agreements --accept-package-agreements
        Refresh-Path
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Log "Git for Windows installed"
            return $true
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Info "Installing Git for Windows via Chocolatey..."
        choco install git -y
        Refresh-Path
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Log "Git for Windows installed"
            return $true
        }
    }

    Fail "Automatic installation failed. Install manually:"
    Write-Host "    https://git-scm.com/downloads/win" -ForegroundColor White
    Write-Host "    or: winget install Git.Git" -ForegroundColor White
    return $false
}

function Install-NodeJS {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Log "Node.js found: $(node --version)"
        return $true
    }

    Warn "Node.js is not installed (required for Claude CLI and npm packages)"
    Write-Host ""
    $install = Read-Host "    Install Node.js LTS now? (y/n)"
    if ($install -ne "y") {
        Fail "Node.js is required. Install manually: https://nodejs.org"
        return $false
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Info "Installing Node.js LTS via winget..."
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        Refresh-Path
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Log "Node.js installed: $(node --version)"
            return $true
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Info "Installing Node.js LTS via Chocolatey..."
        choco install nodejs-lts -y
        Refresh-Path
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Log "Node.js installed: $(node --version)"
            return $true
        }
    }

    Fail "Automatic installation failed. Install manually:"
    Write-Host "    https://nodejs.org/en/download" -ForegroundColor White
    Write-Host "    or: winget install OpenJS.NodeJS.LTS" -ForegroundColor White
    return $false
}

function Ensure-Npm {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log "npm found: $(npm --version)"
        return $true
    }

    # npm should come with Node.js -- try refreshing PATH first
    Refresh-Path
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log "npm found: $(npm --version)"
        return $true
    }

    # Try common Node.js install locations
    $nodePaths = @(
        "$env:ProgramFiles\nodejs",
        "$env:LOCALAPPDATA\Programs\nodejs",
        "$env:APPDATA\npm"
    )
    foreach ($p in $nodePaths) {
        if (Test-Path "$p\npm.cmd") {
            $env:Path = "$p;$env:Path"
            Log "npm found at $p"
            return $true
        }
    }

    if (Get-Command node -ErrorAction SilentlyContinue) {
        Warn "Node.js is installed but npm was not found"
        Info "This usually means you need to close and reopen your terminal after Node.js install"
        Info "If the problem persists, reinstall Node.js from https://nodejs.org"
    } else {
        Warn "npm not available -- install Node.js first (npm is bundled with it)"
    }
    return $false
}

function Install-ClaudeCLI {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $v = (claude --version 2>$null | Select-Object -First 1) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
        Log "Claude CLI found: $v"
        return $true
    }

    Warn "Claude CLI is not installed"
    Write-Host ""
    $install = Read-Host "    Install Claude CLI now? (y/n)"
    if ($install -ne "y") {
        Fail "Claude CLI is required. Install: npm install -g @anthropic-ai/claude-code"
        return $false
    }

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Fail "npm not available -- install Node.js first"
        return $false
    }

    Info "Installing Claude CLI via npm..."
    npm install -g @anthropic-ai/claude-code
    Refresh-Path

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $v = (claude --version 2>$null | Select-Object -First 1) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
        Log "Claude CLI installed: $v"
        return $true
    }

    Fail "Installation failed. Try manually: npm install -g @anthropic-ai/claude-code"
    return $false
}

# ===================================================================
# WSL + TMUX -- required for split-pane agent teams on Windows
# ===================================================================

function Ensure-WSL {
    # wsl.exe exists as a stub on Windows even when WSL isn't installed,
    # so we can't trust Get-Command. Try running it and check the result.
    $wslInstalled = $false
    try {
        $wslStatus = wsl --status 2>&1 | Out-String
        # If --status succeeds without "not installed" message, WSL is enabled
        if ($wslStatus -notmatch "not installed" -and $wslStatus -notmatch "is not") {
            $wslInstalled = $true
        }
    } catch {
        $wslInstalled = $false
    }

    if (-not $wslInstalled) {
        Warn "WSL is not installed (required for tmux split-pane agent teams)"
        Write-Host ""
        $install = Read-Host "    Install WSL now? (y/n)"
        if ($install -eq "y") {
            Info "Installing WSL with Ubuntu (this may take a few minutes)..."
            # wsl --install enables WSL and installs Ubuntu by default
            try { wsl --install 2>&1 | Out-Null } catch {}
            Write-Host ""
            Warn "WSL installed. You MUST restart your computer before continuing."
            Info "After restart, re-run: .\scripts\setup.ps1"
            Read-Host "Press Enter to exit"
            exit 0
        } else {
            Fail "WSL is required for tmux split-pane agent teams."
            Info "Install manually: wsl --install"
            return $false
        }
    }

    # Check a distro is actually installed
    $hasDistro = $false
    try {
        $distros = (wsl --list --quiet 2>&1 | Out-String).Trim()
        if ($distros -and $distros -notmatch "not installed" -and $distros -notmatch "is not") {
            $hasDistro = $true
        }
    } catch {}

    if (-not $hasDistro) {
        Warn "WSL is enabled but no Linux distribution found"
        Write-Host ""
        $install = Read-Host "    Install Ubuntu distro now? (y/n)"
        if ($install -eq "y") {
            Info "Installing Ubuntu..."
            try { wsl --install -d Ubuntu 2>&1 | Out-Null } catch {}
            Warn "Distro installed. You may need to restart your terminal."
            Info "After restart, re-run: .\scripts\setup.ps1"
            Read-Host "Press Enter to exit"
            exit 0
        } else {
            Fail "A WSL distro is required. Install: wsl --install -d Ubuntu"
            return $false
        }
    }

    Log "WSL found"
    return $true
}

function Ensure-WSLLocale {
    # Check if locale is already UTF-8
    $localeCheck = $null
    try { $localeCheck = wsl bash -c "locale 2>/dev/null | head -1" 2>&1 | Out-String } catch {}
    if ($localeCheck -and $localeCheck.Trim() -match "UTF-8") {
        Log "WSL locale: UTF-8 configured (Cyrillic supported)"
        return $true
    }

    Warn "WSL locale is NOT set to UTF-8 -- Cyrillic characters will break in tmux"
    Info "Configuring UTF-8 locale in WSL (installs en_US.UTF-8 + ru_RU.UTF-8)..."
    $localeScript = @'
set -e
sudo apt-get update -qq
sudo apt-get install -y locales
sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo sed -i 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
# Ensure locale vars are set on every shell login
grep -qF 'export LANG=' ~/.bashrc 2>/dev/null || echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
grep -qF 'export LC_ALL=' ~/.bashrc 2>/dev/null || echo 'export LC_ALL=en_US.UTF-8' >> ~/.bashrc
# Also set in .profile for non-interactive shells
grep -qF 'export LANG=' ~/.profile 2>/dev/null || echo 'export LANG=en_US.UTF-8' >> ~/.profile
grep -qF 'export LC_ALL=' ~/.profile 2>/dev/null || echo 'export LC_ALL=en_US.UTF-8' >> ~/.profile
'@
    try { wsl bash -c $localeScript } catch {
        Fail "Locale installation failed: $_"
    }

    # Verify the locale actually works
    $charmap = ""
    try { $charmap = (wsl bash -c "LANG=en_US.UTF-8 locale charmap 2>/dev/null" 2>&1 | Out-String).Trim() } catch {}
    $testCyrillic = ""
    try { $testCyrillic = (wsl bash -c "LANG=en_US.UTF-8 printf '\xd0\x9f\xd1\x80\xd0\xb8\xd0\xb2\xd0\xb5\xd1\x82' 2>/dev/null" 2>&1 | Out-String).Trim() } catch {}

    if ($charmap -eq "UTF-8") {
        Log "WSL locale configured: en_US.UTF-8 (Cyrillic supported)"
        if ($testCyrillic -match "[A-Za-z]" -or $testCyrillic.Length -eq 0) {
            Warn "Cyrillic render test inconclusive -- verify in tmux after launch"
        }
        return $true
    } else {
        Fail "UTF-8 locale verification FAILED -- Cyrillic WILL NOT work"
        Warn "This MUST be fixed before using Claude with Cyrillic text"
        Info "Run manually:"
        Write-Host "    wsl bash -c 'sudo apt-get install -y locales && sudo locale-gen en_US.UTF-8 ru_RU.UTF-8 && sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8'" -ForegroundColor White
        Info "Then restart WSL: wsl --shutdown"
        return $false
    }
}

function Ensure-TmuxInWSL {
    $tmuxCheck = $null
    try { $tmuxCheck = wsl bash -c "command -v tmux" 2>&1 | Out-String } catch {}
    if ($tmuxCheck -and $tmuxCheck.Trim() -match "tmux") {
        $tmuxVer = ""
        try { $tmuxVer = (wsl bash -c "tmux -V" 2>&1 | Out-String).Trim() } catch {}
        Log "tmux found in WSL: $tmuxVer"
        return $true
    }

    Warn "tmux not found in WSL (required for split-pane agent teams)"
    Write-Host ""
    $install = Read-Host "    Install tmux in WSL now? (y/n)"
    if ($install -eq "y") {
        Info "Installing tmux in WSL..."
        try { wsl bash -c "sudo apt-get update -qq && sudo apt-get install -y tmux" } catch {}
        try { $tmuxCheck = wsl bash -c "command -v tmux" 2>&1 | Out-String } catch {}
        if ($tmuxCheck -and $tmuxCheck.Trim() -match "tmux") {
            Log "tmux installed in WSL"
            return $true
        } else {
            Fail "tmux installation failed"
            return $false
        }
    } else {
        Fail "tmux is required. Install manually: wsl bash -c 'sudo apt install tmux'"
        return $false
    }
}

function Ensure-ClaudeInWSL {
    $claudeCheck = $null
    try { $claudeCheck = wsl bash -c "command -v claude" 2>&1 | Out-String } catch {}
    if ($claudeCheck -and $claudeCheck.Trim() -match "claude") {
        $claudeVer = ""
        try { $claudeVer = (wsl bash -c "claude --version 2>/dev/null | head -1" 2>&1 | Out-String).Trim() } catch {}
        Log "Claude CLI found in WSL: $claudeVer"
        return $true
    }

    Warn "Claude CLI not found in WSL (required for tmux split-pane mode)"
    Write-Host ""
    $install = Read-Host "    Install Claude CLI in WSL now? (y/n)"
    if ($install -eq "y") {
        # Ensure Node.js is available in WSL
        $nodeCheck = $null
        try { $nodeCheck = wsl bash -c "command -v node" 2>&1 | Out-String } catch {}
        if (-not $nodeCheck -or $nodeCheck.Trim() -notmatch "node") {
            Info "Installing Node.js in WSL..."
            try { wsl bash -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs" } catch {}
        }

        Info "Installing Claude CLI in WSL (npm install -g)..."
        try { wsl bash -c "sudo npm install -g @anthropic-ai/claude-code" } catch {}

        try { $claudeCheck = wsl bash -c "command -v claude" 2>&1 | Out-String } catch {}
        if ($claudeCheck -and $claudeCheck.Trim() -match "claude") {
            Log "Claude CLI installed in WSL"
            return $true
        } else {
            Fail "Claude CLI installation failed in WSL"
            Info "Try manually: wsl bash -c 'npm install -g @anthropic-ai/claude-code'"
            return $false
        }
    } else {
        Fail "Claude CLI in WSL is required for split-pane mode."
        Info "Install manually: wsl bash -c 'npm install -g @anthropic-ai/claude-code'"
        return $false
    }
}

# ===================================================================
# MAIN SETUP (idempotent -- runs the same whether first or repeat)
# ===================================================================

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Claude Code + Agent Teams Setup     |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

# --- Install tools ------------------------------------------------

$gitOk   = Install-GitBash
$nodeOk  = Install-NodeJS
$npmOk   = Ensure-Npm
$claudeOk = Install-ClaudeCLI

if (-not $gitOk) {
    Fail "Git for Windows is required by Claude Code. Cannot continue."
    Write-Host "    Install: winget install Git.Git" -ForegroundColor White
    Write-Host "    Then close and reopen this terminal." -ForegroundColor White
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not $claudeOk) {
    Fail "Claude CLI is required. Cannot continue."
    exit 1
}

if (-not $nodeOk) {
    Warn "Node.js missing -- some features will not be available."
}

if (-not $npmOk) {
    Warn "npm missing -- try closing and reopening terminal, then re-run setup."
}

# --- WSL + tmux (required for split-pane agent teams) -------------

$wslOk = Ensure-WSL
if ($wslOk) {
    $tmuxOk = Ensure-TmuxInWSL
    Ensure-WSLLocale
    $claudeWslOk = Ensure-ClaudeInWSL
} else {
    Warn "WSL not available -- agent teams will not have split-pane support"
}

Log "Pre-flight passed"
Write-Host ""

# --- User-level settings -----------------------------------------

$userSettingsDir  = "$env:USERPROFILE\.claude"
$userSettingsFile = "$userSettingsDir\settings.json"

if (-not (Test-Path $userSettingsDir)) { New-Item -ItemType Directory -Path $userSettingsDir -Force | Out-Null }

if (Test-Path $userSettingsFile) {
    $content = Get-Content $userSettingsFile -Raw
    $needsUpdate = $false
    if ($content -notmatch "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") { $needsUpdate = $true }
    if ($content -notmatch "teammateMode")                         { $needsUpdate = $true }

    if ($needsUpdate) {
        Info "Updating user settings for agent teams..."
        try {
            $settings = $content | ConvertFrom-Json
            if (-not $settings.env) { $settings | Add-Member -NotePropertyName "env" -NotePropertyValue ([PSCustomObject]@{}) }
            $settings.env | Add-Member -NotePropertyName "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" -NotePropertyValue "1" -Force
            $settings | Add-Member -NotePropertyName "teammateMode" -NotePropertyValue "tmux" -Force
            $settings | ConvertTo-Json -Depth 10 | Set-Content $userSettingsFile -Encoding UTF8
            Log "Updated $userSettingsFile"
        } catch {
            Warn "Could not auto-update user settings. Add manually:"
            Write-Host '    env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' -ForegroundColor White
            Write-Host '    teammateMode = "tmux"' -ForegroundColor White
        }
    } else {
        Log "User settings: agent teams already configured"
    }
} else {
    $settingsJson = @'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
'@
    $settingsJson | Set-Content $userSettingsFile -Encoding UTF8
    Log "Created $userSettingsFile"
}

# --- Project-level settings ---------------------------------------

if (-not (Test-Path ".claude")) { New-Item -ItemType Directory -Path ".claude" -Force | Out-Null }

if (Test-Path ".claude/settings.json") {
    $content = Get-Content ".claude/settings.json" -Raw
    $needsUpdate = $false
    if ($content -notmatch "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") { $needsUpdate = $true }
    if ($content -notmatch "teammateMode")                         { $needsUpdate = $true }

    if ($needsUpdate) {
        try {
            $settings = $content | ConvertFrom-Json
            if (-not $settings.env) { $settings | Add-Member -NotePropertyName "env" -NotePropertyValue ([PSCustomObject]@{}) }
            $settings.env | Add-Member -NotePropertyName "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" -NotePropertyValue "1" -Force
            $settings | Add-Member -NotePropertyName "teammateMode" -NotePropertyValue "tmux" -Force
            $settings | ConvertTo-Json -Depth 10 | Set-Content ".claude/settings.json" -Encoding UTF8
            Log "Updated .claude\settings.json"
        } catch {
            Warn "Could not auto-update project settings"
        }
    } else {
        Log "Project settings already configured"
    }
} else {
    $projSettings = @'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
'@
    $projSettings | Set-Content ".claude/settings.json" -Encoding UTF8
    Log "Created .claude\settings.json"
}

# --- Verify config files ------------------------------------------

foreach ($dir in @(".claude/agents", ".claude/commands", ".claude/snapshots")) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

$missingAgents = @()
foreach ($agent in $ExpectedAgents) {
    if (-not (Test-Path ".claude/agents/$agent.md")) { $missingAgents += $agent }
}

$missingCommands = @()
foreach ($cmd in $ExpectedCommands) {
    if (-not (Test-Path ".claude/commands/$cmd.md")) { $missingCommands += $cmd }
}

if ($missingAgents.Count -gt 0 -or $missingCommands.Count -gt 0) {
    Warn "Missing config files. Run install.ps1 to download them:"
    Write-Host "    irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex" -ForegroundColor White
    if ($missingAgents.Count -gt 0) { Warn "  Missing agents: $($missingAgents -join ', ')" }
    if ($missingCommands.Count -gt 0) { Warn "  Missing commands: $($missingCommands -join ', ')" }
} else {
    Log "Config files verified: $($ExpectedAgents.Count) agents, $($ExpectedCommands.Count) commands"
}

# --- .gitignore additions -----------------------------------------

if (Test-Path ".gitignore") {
    $ignoreContent = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
    $entries = @(".env", ".env.*")
    foreach ($entry in $entries) {
        if ($ignoreContent -notmatch [regex]::Escape($entry)) {
            Add-Content ".gitignore" $entry
        }
    }
    Log "Updated .gitignore"
}

# --- Project dependencies -----------------------------------------

if (Test-Path "package.json") {
    if (Test-Path "node_modules") {
        Log "Project dependencies installed (node_modules)"
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        Info "Installing project dependencies (npm install)..."
        npm install
        if (Test-Path "node_modules") {
            Log "Project dependencies installed"
        } else {
            Warn "npm install failed"
        }
    } else {
        Warn "npm not available -- cannot install project dependencies"
    }
} else {
    Info "No package.json found -- skipping npm install"
}

# --- VS Code extensions -------------------------------------------

if (Get-Command code -ErrorAction SilentlyContinue) {
    Log "VS Code CLI found"

    Write-Host ""
    Info "Recommended VS Code extensions:"
    foreach ($ext in $VscodeExtensions) {
        Write-Host "    $ext" -ForegroundColor White
    }
    Write-Host ""
    $installExt = Read-Host "    Install recommended VS Code extensions? (y/n)"
    if ($installExt -eq "y") {
        foreach ($ext in $VscodeExtensions) {
            Info "Installing: $ext"
            # --force updates if already installed, avoids opening VS Code windows
            code --install-extension $ext --force 2>$null | Out-Null
            Log "Installed: $ext"
        }
    } else {
        Info "Skipping. Install later:"
        foreach ($ext in $VscodeExtensions) {
            Write-Host "    code --install-extension $ext" -ForegroundColor White
        }
    }
} else {
    Info "VS Code 'code' command not in PATH -- skipping extension setup"
    Info "Open VS Code -> Ctrl+Shift+P -> 'Shell Command: Install code command in PATH'"
}

# --- Quick commands (pp, pp-setup) --------------------------------

$psProfile = $PROFILE
if (-not (Test-Path $psProfile)) {
    $profileDir = Split-Path -Parent $psProfile
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    # Create empty profile so we can append to it
    [System.IO.File]::WriteAllText($psProfile, "", (New-Object System.Text.UTF8Encoding($true)))
}

$profileContent = Get-Content $psProfile -Raw -ErrorAction SilentlyContinue
$hasPp      = $profileContent -match 'function pp '
$hasPpSetup = $profileContent -match 'function pp-setup '

if ($hasPp -and $hasPpSetup) {
    Log "Quick commands already registered (pp, pp-setup)"
} else {
    Write-Host ""
    Info "Quick commands:"
    Write-Host "    pp         -- launch Claude session"
    Write-Host "    pp-setup   -- re-run setup for this project"
    Write-Host ""
    $addCmds = Read-Host "    Add 'pp' and 'pp-setup' to PowerShell profile? (y/n)"
    if ($addCmds -eq "y") {
        # Remove old pp function if present but pp-setup is missing
        if ($hasPp -and -not $hasPpSetup) {
            $profileContent = $profileContent -replace '(?m)^# Claude Code -- quick commands.*\r?\n', ''
            $profileContent = $profileContent -replace '(?m)^function pp \{[^}]+\}\r?\n?', ''
            [System.IO.File]::WriteAllText($psProfile, $profileContent, (New-Object System.Text.UTF8Encoding($true)))
        }

        $cmdBlock = @"

# Claude Code -- quick commands (added by setup.ps1)
function pp { Set-Location "$ProjectDir"; & ".\scripts\start.ps1" @args }
function pp-setup { Set-Location "$ProjectDir"; & powershell -ExecutionPolicy Bypass -File ".\scripts\setup.ps1" @args }
"@
        $existingContent = if (Test-Path $psProfile) {
            [System.IO.File]::ReadAllText($psProfile, [System.Text.Encoding]::UTF8)
        } else { "" }
        $newContent = $existingContent + $cmdBlock
        [System.IO.File]::WriteAllText($psProfile, $newContent, (New-Object System.Text.UTF8Encoding($true)))
        Log "Added 'pp' and 'pp-setup' to $psProfile"
        Info "Restart PowerShell or run '. `$PROFILE' to use them"
    } else {
        Info "Skipping quick commands. Add manually later."
    }
}

# --- Clean up leftover files --------------------------------------


# --- Summary ------------------------------------------------------

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Setup Complete                      |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Agent Teams (Official Mechanism):"
Write-Host "    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1  Enabled in settings"
Write-Host "    teammateMode: tmux                      Teammates auto-create split panes via WSL tmux"
Write-Host "    .claude\settings.json                   Project-level settings"
Write-Host "    ~\.claude\settings.json                 User-level settings"
Write-Host "    .claude\agents\              $($ExpectedAgents.Count) agents: $($ExpectedAgents -join ', ')"
Write-Host ""
Write-Host "  Commands:"
Write-Host "    .claude\commands\            $($ExpectedCommands.Count) commands: $($ExpectedCommands -join ', ')"
Write-Host ""
Write-Host "  Quick commands (added to PowerShell profile):"
Write-Host "    pp                           Launch Claude session"
Write-Host "    pp-setup                     Re-run setup for this project"
Write-Host ""
Write-Host "  Inside Claude:"
Write-Host "    /prime                       Prime the session with codebase context"
Write-Host "    /build-with-agent-team       Spawn agent team"
Write-Host "    /research <topic>            Spawn research agent"
Write-Host "    /deploy                      Commit, push, snapshot"
Write-Host ""
Write-Host "  To start:" -ForegroundColor Green
Write-Host "    . `$PROFILE              Reload profile (required once after setup)" -ForegroundColor Green
Write-Host "    pp                       Launch Claude session" -ForegroundColor Green
Write-Host ""
Write-Host "  Or run directly:  .\scripts\start.ps1" -ForegroundColor Green
Write-Host ""
