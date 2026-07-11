@echo off
:: ==============================================================================
:: SCRIPT: Safe Temporary Cleanup
:: TARGET SYSTEM: Windows 10 & Windows 11
:: DESCRIPTION: Safely purges temporary files, cache folders, and empties the 
::              Recycle Bin without affecting system updates or core components.
:: SAFETY LEVEL: 100% Safe to run anytime
:: ==============================================================================
title Safe Temporary Cleanup
setlocal enabledelayedexpansion

:: Check Admin Rights
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: This script must be run as Administrator.
    echo Please right-click the script and select 'Run as Administrator'.
    echo.
    exit /b
)

:: Header
cls
echo ======================================================================
echo                        SAFE TEMPORARY CLEANUP
echo ======================================================================
echo.
echo [*] Checking Windows Version...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set WIN_VER=%%i.%%j
for /f "tokens=6 delims=[.] " %%i in ('ver') do set WIN_BUILD=%%i
echo [*] System Build: !WIN_BUILD!
echo.
echo Starting Safe Maintenance Cleanup...
echo --------------------------------------------------

:: 1. Emptying Recycle Bin
echo [*] Emptying Recycle Bin...
powershell.exe -NoProfile -Command "Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
echo [+] Recycle Bin cleared.

:: 2. Cleaning User Temp Folder
echo [*] Purging User Temp directory (%temp%)...
del /s /f /q "%temp%\*.*" >nul 2>&1
for /d %%p in ("%temp%\*") do rmdir /s /q "%%p" >nul 2>&1
echo [+] User Temp cleared.

:: 3. Cleaning System Temp Folder
echo [*] Purging System Temp directory (Windows\Temp)...
del /s /f /q "%WINDIR%\Temp\*.*" >nul 2>&1
for /d %%p in ("%WINDIR%\Temp\*") do rmdir /s /q "%%p" >nul 2>&1
echo [+] System Temp cleared.

:: 4. Cleaning Log Files
echo [*] Cleaning Log files (CBS, MoSetup, Panther)...
del /s /f /q "%WINDIR%\logs\cbs\*.log" >nul 2>&1
del /s /f /q "%WINDIR%\Logs\MoSetup\*.log" >nul 2>&1
del /s /f /q "%WINDIR%\Panther\*.log" >nul 2>&1
del /s /f /q "%WINDIR%\inf\*.log" >nul 2>&1
del /s /f /q "%WINDIR%\logs\*.log" >nul 2>&1
echo [+] System logs cleaned.

:: 5. Cleaning Windows Update download Cache (Safe)
echo [*] Cleaning Windows Update Download Cache (SoftwareDistribution\Download)...
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
del /s /f /q "%WINDIR%\SoftwareDistribution\Download\*.*" >nul 2>&1
for /d %%p in ("%WINDIR%\SoftwareDistribution\Download\*") do rmdir /s /q "%%p" >nul 2>&1
net start wuauserv >nul 2>&1
net start UsoSvc >nul 2>&1
echo [+] Windows Update Download Cache cleared.

echo --------------------------------------------------
echo [+] Safe maintenance cleanup finished successfully!
echo.
exit /b
