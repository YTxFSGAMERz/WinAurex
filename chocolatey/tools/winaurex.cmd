@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%app\Core\CLI\WinAurex.CLI.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%app\Core\CLI\WinAurex.CLI.ps1" %*
) else if exist "%SCRIPT_DIR%..\..\..\Core\CLI\WinAurex.CLI.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%..\..\..\Core\CLI\WinAurex.CLI.ps1" %*
) else (
    echo [WinAurex Error] Cannot find WinAurex.CLI.ps1
    exit /b 1
)
exit /b %ERRORLEVEL%
