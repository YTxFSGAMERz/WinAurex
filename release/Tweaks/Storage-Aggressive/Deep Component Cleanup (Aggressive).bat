@echo off
:: ==============================================================================
:: SCRIPT: Deep Component Store Cleanup (Aggressive)
:: TARGET SYSTEM: Windows 10 & Windows 11
:: DESCRIPTION: Compresses the Windows component store and deletes all historical 
::              backups of previously installed updates. 
:: WARNING: This operation is IRREVERSIBLE. Once complete, currently installed 
::          updates CANNOT be uninstalled or rolled back!
:: SAFETY LEVEL: Aggressive (Requires Confirmation)
:: ==============================================================================
title Deep Component Store Cleanup
setlocal enabledelayedexpansion

:: Check Admin Rights
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: This script must be run as Administrator.
    echo Please right-click the script and select 'Run as Administrator'.
    echo.
    exit /b
)

cls
echo ======================================================================
echo             CRITICAL WARNING: AGGRESSIVE COMPONENT CLEANUP
echo ======================================================================
echo.
echo  [!] WARNING: This script performs a deep system store purge using:
echo      DISM.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
echo.
echo  [*] WHAT THIS ACTUALLY CHANGES:
echo      - Deletes all historical update versions from the component store (WinSxS).
echo      - Reclaims significant gigabytes of wasted hard drive space.
echo.
echo  [!] CRITICAL DRAWBACKS / RISK:
echo      - This operation is IRREVERSIBLE.
echo      - Once run, currently installed Windows updates CANNOT be uninstalled.
echo      - You will NOT be able to roll back to previous updates if a bug occurs.
echo.
echo ======================================================================
echo.

set /p confirm=To confirm and proceed, please type "AGREE" (case-sensitive): 

if not "!confirm!"=="AGREE" (
    echo.
    echo [x] Confirmation failed. Exiting without making changes...
    echo.
    timeout /t 5
    exit /b
)

echo.
echo --------------------------------------------------
echo [*] Confirmation successful! Starting deep cleanup...
echo [*] Please do NOT turn off your PC during this time.
echo --------------------------------------------------
echo.

echo [*] Compressing and purging older Windows components...
dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

echo.
echo --------------------------------------------------
echo [+] Deep Component Store Cleanup finished successfully!
echo [+] Gigabytes of disk space have been reclaimed.
echo --------------------------------------------------
echo.
exit /b
