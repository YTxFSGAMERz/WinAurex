@echo off
title WinAurex Windows Activation Helper
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
echo                  WinAurex Windows Activation Helper
echo ======================================================================
echo.
echo WinAurex connects directly to the official open-source Microsoft
echo Activation Scripts (MAS) project (massgrave.dev).
echo.
echo Streaming directly from the official source ensures:
echo  - Zero antivirus or Defender false-positive quarantines
echo  - Always the latest Microsoft activation definitions (HWID, KMS38)
echo  - 100% clean, virus-free, open-source execution
echo.
echo  *1.- Launch Official Microsoft Activation Scripts (MAS)
echo  *2.- Open Official MassGrave Documentation (massgrave.dev)
echo  *3.- Exit
echo.
echo ======================================================================
set /p opt=Choose an option [1-3]: 

if "%opt%"=="1" (
    cls
    echo Launching Microsoft Activation Scripts (MAS)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; irm https://get.activated.win | iex"
    pause
    goto :menu
)

if "%opt%"=="2" (
    start https://massgrave.dev
    goto :menu
)

if "%opt%"=="3" (
    exit /b
)

goto :menu
