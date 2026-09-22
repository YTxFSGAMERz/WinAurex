@echo off
:: ==============================================================================
:: WinAurex - Intelligent PC Storage Cleaner (1-Click Double-Click Launcher)
:: Automatically requests Administrator privileges and runs interactive cleanup.
:: ==============================================================================
title WinAurex PC Cleaner Launcher
cd /d "%~dp0"

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Requesting Administrator Privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c', '\"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Run the WinAurex Interactive PC Cleaner
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\Cleaner\Invoke-PCCleaner.ps1"

if %errorLevel% neq 0 (
    echo.
    echo [!] An unexpected error occurred.
    pause
)
exit /b
