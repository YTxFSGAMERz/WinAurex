@echo off
:: ==============================================================================
:: WinAurex - Run PC Cleaner Tool (Double-Click Launcher)
:: ==============================================================================
title WinAurex PC Cleaner
cd /d "%~dp0"

:: Check Admin Rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Requesting Administrator Privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c', '\"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Invoke-PCCleaner.ps1"
exit /b
