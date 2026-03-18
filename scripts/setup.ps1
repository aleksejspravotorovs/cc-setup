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

# Windows Terminal (recommended, not required)
if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
    Log "Windows Terminal found"
} else {
    Info "Windows Terminal not found (recommended for split-pane view outside VS Code)"
    Write-Host "      winget install Microsoft.WindowsTerminal" -ForegroundColor White
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
    $entries = @(".env", ".env.*", ".cleo/")
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
    Log "VS Code CLI found: $(code --version 2>$null | Select-Object -First 1)"

    $installedExt = code --list-extensions 2>$null
    $missingExt = @()
    foreach ($ext in $VscodeExtensions) {
        if ($installedExt -notcontains $ext) { $missingExt += $ext }
    }

    if ($missingExt.Count -eq 0) {
        Log "VS Code extensions: all recommended installed"
    } else {
        Write-Host ""
        Info "Missing $($missingExt.Count) recommended VS Code extension(s):"
        foreach ($ext in $missingExt) {
            Write-Host "    $ext" -ForegroundColor White
        }
        Write-Host ""
        $installExt = Read-Host "    Install missing VS Code extensions? (y/n)"
        if ($installExt -eq "y") {
            foreach ($ext in $missingExt) {
                Info "Installing: $ext"
                code --install-extension $ext --force 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Log "Installed: $ext"
                } else {
                    Warn "Failed to install $ext"
                }
            }
            Log "VS Code extensions installed"
        } else {
            Info "Skipping. Install later:"
            foreach ($ext in $missingExt) {
                Write-Host "    code --install-extension $ext" -ForegroundColor White
            }
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
    "" | Set-Content $psProfile
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
            $profileContent | Set-Content $psProfile -Encoding UTF8
        }

        $cmdBlock = @"

# Claude Code -- quick commands (added by setup.ps1)
function pp { Set-Location "$ProjectDir"; & ".\scripts\start.ps1" @args }
function pp-setup { Set-Location "$ProjectDir"; & powershell -ExecutionPolicy Bypass -File ".\scripts\setup.ps1" @args }
"@
        Add-Content $psProfile $cmdBlock
        Log "Added 'pp' and 'pp-setup' to $psProfile"
        Info "Restart PowerShell or run '. `$PROFILE' to use them"
    } else {
        Info "Skipping quick commands. Add manually later."
    }
}

# --- Clean up leftover files --------------------------------------

if (Test-Path ".cleo") {
    Remove-Item -Recurse -Force ".cleo"
    Log "Removed leftover .cleo directory"
}

# --- Summary ------------------------------------------------------

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Setup Complete                      |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Agent Teams (Official Mechanism):"
Write-Host "    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1  Enabled in settings"
Write-Host "    teammateMode: tmux                      Teammates auto-create split panes"
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
Write-Host "  To start:  .\scripts\start.ps1   (or just type 'pp')" -ForegroundColor Green
Write-Host ""
