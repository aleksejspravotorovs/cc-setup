# +==================================================================+
# |  Git Watch -- live status loop for split-pane monitoring          |
# |  Run in a second terminal pane alongside Claude                   |
# +==================================================================+

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

while ($true) {
    Clear-Host
    Write-Host "== GIT WATCH ==" -ForegroundColor Cyan
    Get-Date -Format "HH:mm:ss"
    Write-Host ""

    Write-Host "-- status --" -ForegroundColor Yellow
    git status -sb 2>$null
    Write-Host ""

    Write-Host "-- changed files --" -ForegroundColor Yellow
    git diff --stat 2>$null
    Write-Host ""

    Write-Host "-- recent commits --" -ForegroundColor Yellow
    git log --oneline -5 2>$null

    Start-Sleep 3
}
