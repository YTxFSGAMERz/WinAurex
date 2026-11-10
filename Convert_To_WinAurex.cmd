@echo off
title Convert PC to WinAurex
setlocal enabledelayedexpansion

:: Check Admin Rights
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
    >nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

if '%errorlevel%' NEQ '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
)

pushd "%CD%"
CD /D "%~dp0"

cls
echo ======================================================================
echo                  Convert PC to WinAurex (In-Place)
echo ======================================================================
echo.
echo This will convert your existing Windows system into WinAurex Edition:
echo  - 100% In-Place: ZERO file loss, no clean install
echo  - Strips telemetry & bloatware (preserves Microsoft Store)
echo  - Injects WinAurex OEM branding, instant 10ms menus, 1:1 mouse input
echo  - Unlocks Ultimate Performance Plan & enables HAGS
echo  - Adds Desktop shortcuts and global 'winaurex' terminal CLI
echo.
echo ======================================================================
set /p conf=Convert this PC to WinAurex now? (Y/N): 
if /i not "!conf!"=="Y" (
    echo Aborted by user.
    pause
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply.ps1" -Force
pause
