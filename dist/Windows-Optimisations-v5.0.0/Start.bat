@echo off
:: Windows Optimization Framework - Zero Friction Launcher
:: This script safely elevates and launches the PowerShell initialization logic.

echo ==============================================================
echo  Windows Optimization Framework
echo  Preparing Dashboard...
echo ==============================================================
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :RunPowerShell
) else (
    echo [INFO] Requesting Administrator Privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:RunPowerShell
:: Navigate to the directory containing this batch file
cd /d "%~dp0"

:: Launch the initialization script in PowerShell (Bypasses execution policy for this run only)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Launchers\Initialize_Framework.ps1"

exit /b
