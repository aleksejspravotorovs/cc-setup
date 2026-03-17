# +==================================================================+
# |  Claude Code -- One-liner bootstrap (Windows)                    |
# |  irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex
# +==================================================================+

$ErrorActionPreference = "Stop"

$repo = "https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main"

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Claude Code -- Downloading scripts  |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

New-Item -ItemType Directory -Path scripts -Force | Out-Null

$files = @("setup.ps1", "setup.bat", "start.ps1", "start.bat")
foreach ($file in $files) {
    Write-Host "  Downloading scripts\$file..."
    Invoke-WebRequest "$repo/scripts/$file" -OutFile "scripts\$file" -UseBasicParsing
}

Write-Host ""
Write-Host "  Scripts downloaded to scripts\"
Write-Host "  Running setup..."
Write-Host ""

& powershell -ExecutionPolicy Bypass -NoProfile -File ".\scripts\setup.bat"
