@echo off
:: ╔══════════════════════════════════════════════════════════════════╗
:: ║  Claude Code — Session Launcher (Windows)                       ║
:: ║  Runs start.ps1 with execution policy bypass.                   ║
:: ╚══════════════════════════════════════════════════════════════════╝

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0start.ps1" %*
if %ERRORLEVEL% neq 0 pause
