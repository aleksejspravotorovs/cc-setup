#Requires -Version 5.1
# +==================================================================+
# |  Fix PowerShell Profile -- UTF-8 BOM repair tool                  |
# |  Rewrites pp/pp-setup functions with correct encoding for         |
# |  Cyrillic and Unicode paths.                                      |
# |  Usage: powershell -ExecutionPolicy Bypass -File .\scripts\fix-profile.ps1
# +==================================================================+

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$psProfile = $PROFILE

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Fix PowerShell Profile (UTF-8 BOM)  |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

# Read existing profile content (if any), stripping old Claude Code blocks
$existingContent = ""
if (Test-Path $psProfile) {
    $lines = Get-Content $psProfile -Encoding UTF8 -ErrorAction SilentlyContinue
    $filteredLines = @()
    $skipBlock = $false
    foreach ($line in $lines) {
        if ($line -match '# Claude Code -- quick commands') {
            $skipBlock = $true
            continue
        }
        if ($skipBlock -and ($line -match '^function pp[\s{-]' -or $line -match '^function pp-setup[\s{-]')) {
            continue
        }
        if ($skipBlock -and $line -match '^\s*$') {
            $skipBlock = $false
            continue
        }
        if (-not $skipBlock) {
            $filteredLines += $line
        }
    }
    $existingContent = ($filteredLines -join "`r`n").TrimEnd()
    if ($existingContent.Length -gt 0) {
        $existingContent += "`r`n"
    }
}

# Build the Claude Code block using string concatenation (avoids here-string escaping issues)
$block = "`r`n# Claude Code -- quick commands (added by fix-profile.ps1)`r`n"
$block += 'function pp { Set-Location "' + $ProjectDir + '"; & ".\scripts\start.ps1" @args }' + "`r`n"
$block += 'function pp-setup { Set-Location "' + $ProjectDir + '"; & powershell -ExecutionPolicy Bypass -File ".\scripts\setup.ps1" @args }' + "`r`n"

$newContent = $existingContent + $block

# Write with UTF-8 BOM (required for PowerShell 5.1 to read non-ASCII correctly)
$profileDir = Split-Path -Parent $psProfile
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($psProfile, $newContent, $utf8bom)

Write-Host "  [OK] Profile rewritten with UTF-8 BOM" -ForegroundColor Green
Write-Host "  [OK] Project path: $ProjectDir" -ForegroundColor Green
Write-Host "  [i]  Profile: $psProfile" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Restart PowerShell or run '. `$PROFILE' to reload." -ForegroundColor Cyan
Write-Host ""
