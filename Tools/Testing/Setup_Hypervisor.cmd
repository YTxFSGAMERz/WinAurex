@echo off
title WinAurex Hypervisor Setup Helper
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
echo                  WinAurex Hypervisor Setup Helper
echo ======================================================================
echo.
echo Choose which VM hypervisor you would like to set up on your PC:
echo.
echo  *1.- Enable Native Windows Hyper-V (Fastest for Windows Pro, No 3rd Party)
echo  *2.- Install Oracle VM VirtualBox (Universal, Free, Easiest Shared Folders)
echo  *3.- Install VMware Workstation Pro (Free for Personal Use, Best GPU)
echo  *4.- Exit
echo.
echo ======================================================================
set /p op=Select an option [1-4]: 

if "%op%"=="1" (
    cls
    echo ======================================================================
    echo Enabling Native Windows Hyper-V...
    echo ======================================================================
    dism.exe /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V-All
    echo.
    echo [+] Hyper-V feature enabled! A system restart will be required.
    pause
    goto :menu
)

if "%op%"=="2" (
    cls
    echo ======================================================================
    echo Installing Oracle VirtualBox via winget...
    echo ======================================================================
    winget install Oracle.VirtualBox --accept-source-agreements --accept-package-agreements
    echo.
    echo [+] VirtualBox installation finished!
    pause
    goto :menu
)

if "%op%"=="3" (
    cls
    echo ======================================================================
    echo Installing VMware Workstation Pro via winget...
    echo ======================================================================
    winget install Broadcom.WorkstationPro --accept-source-agreements --accept-package-agreements
    echo.
    echo [+] VMware Workstation Pro installation finished!
    pause
    goto :menu
)

if "%op%"=="4" exit /b
goto :menu
