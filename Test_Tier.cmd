@echo off
title WinAurex VM Tier Tester
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

:menu
cls
echo ======================================================================
echo                  WinAurex VM Tier Testing & Log Harness
echo ======================================================================
echo.
echo Select the safety tier to test in this Virtual Machine:
echo.
echo  *1.- Test Tier 1 (Safe Suite - Daily Driver)
echo  *2.- Test Tier 2 (Advanced Suite - Power Users)
echo  *3.- Test Tier 3 (Critical / Extreme Suite - Heavy Testers)
echo  *4.- Open Logs / Reports Directory
echo  *5.- Exit
echo.
echo ======================================================================
set /p op=Option [1-5]: 
if "%op%"=="1" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\Testing\Test_WinAurex_Tier.ps1" -Tier 1 & pause & goto :menu
if "%op%"=="2" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\Testing\Test_WinAurex_Tier.ps1" -Tier 2 & pause & goto :menu
if "%op%"=="3" (
    echo.
    echo [!] WARNING: Tier 3 will run aggressive feature stripping.
    set /p conf=Type 'CONFIRM' to run Tier 3: 
    if "!conf!"=="CONFIRM" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\Testing\Test_WinAurex_Tier.ps1" -Tier 3 -RiskAccepted
    ) else (
        echo Aborted.
    )
    pause
    goto :menu
)
if "%op%"=="4" (
    if not exist "%~dp0Logs\TestReports" mkdir "%~dp0Logs\TestReports"
    explorer "%~dp0Logs\TestReports"
    goto :menu
)
if "%op%"=="5" exit /b
goto :menu
