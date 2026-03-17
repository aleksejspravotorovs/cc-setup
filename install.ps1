# +==================================================================+
# |  Claude Code -- One-liner bootstrap (Windows)                    |
# |  irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex
# +==================================================================+

$ErrorActionPreference = "Stop"

$repo = "https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main"

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Claude Code -- Downloading files    |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

# Create directory structure
foreach ($dir in @("scripts", ".claude\agents", ".claude\commands", ".claude\snapshots")) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# --- Scripts ---
foreach ($file in @("setup.ps1", "start.ps1", "setup.bat", "start.bat")) {
    Write-Host "  Downloading scripts\$file..."
    Invoke-WebRequest "$repo/scripts/$file" -OutFile "scripts\$file" -UseBasicParsing
}

# --- Agents ---
foreach ($agent in @("lead", "frontend", "backend", "devops", "skeptic", "qa", "researcher")) {
    Write-Host "  Downloading .claude\agents\$agent.md..."
    Invoke-WebRequest "$repo/.claude/agents/$agent.md" -OutFile ".claude\agents\$agent.md" -UseBasicParsing
}

# --- Commands ---
foreach ($cmd in @("prime", "build-with-agent-team", "deploy", "research")) {
    Write-Host "  Downloading .claude\commands\$cmd.md..."
    Invoke-WebRequest "$repo/.claude/commands/$cmd.md" -OutFile ".claude\commands\$cmd.md" -UseBasicParsing
}

# --- Config files (only if not already present) ---
foreach ($file in @(".claude\settings.json", "CLAUDE.md", "AGENTS.md")) {
    if (-not (Test-Path $file)) {
        Write-Host "  Downloading $file..."
        Invoke-WebRequest "$repo/$file" -OutFile $file -UseBasicParsing
    } else {
        Write-Host "  Skipping $file (already exists)"
    }
}

Write-Host ""
Write-Host "  Files downloaded."
Write-Host "  Running setup..."
Write-Host ""

& powershell -ExecutionPolicy Bypass -NoProfile -File ".\scripts\setup.ps1"
