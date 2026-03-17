@echo off
:: ╔══════════════════════════════════════════════════════════════════╗
:: ║  Claude Code + Agent Teams Setup (Windows launcher)             ║
:: ║  Runs setup.ps1 with execution policy bypass so scripts work    ║
:: ║  even on fresh Windows installs where scripts are disabled.     ║
:: ╚══════════════════════════════════════════════════════════════════╝

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0setup.ps1" %*
if %ERRORLEVEL% neq 0 pause
