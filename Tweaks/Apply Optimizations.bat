@echo off
title WinAurex Optimizer
setlocal enabledelayedexpansion

:: Elevate to Administrator
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
    >nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

if '%errorlevel%' NEQ '0' (
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"="""%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:start
cls
echo ======================================================================
echo                         WinAurex Optimizer
echo              Safe Optimization, Gaming & Privacy Hub
echo ======================================================================
echo.
echo  --- CHOOSE YOUR SAFETY TIER ---
echo.
echo   *1.- [SAFE] Recommended Optimizations (Tier 1: Daily Driver)
echo        ^> Zero risk, preserves Store, Windows Update, UAC and services.
echo        ^> Strips telemetry, optimizes input/GPU, speeds up menus.
echo.
echo   *2.- [ADVANCED] Power User Tuning (Tier 2: Enthusiasts)
echo        ^> SmartScreen toggles, static pagefile, Edge tweaks, USB suspend.
echo.
echo   *3.- [CRITICAL] Heavy Tester Lab (Tier 3: Test VMs Only)
echo        ^> Aggressive debloats, deep component cleaning, experimental tools.
echo        ^> WARNING: Intended for test environments. Requires confirmation.
echo.
echo   *4.- Explore Modular Tweaks by Category
echo   *5.- Run Safe PC Storage Cleaner
echo   *6.- Create Restore Point / Transaction Snapshot
echo   *7.- Launch WinAurex GUI Dashboard
echo   *8.- Exit
echo.
echo ======================================================================

set /p op=Select an option [1-8]: 
if "%op%"=="" goto :start
if "%op%"=="1" goto :safe_suite
if "%op%"=="2" goto :advanced_menu
if "%op%"=="3" goto :critical_lab
if "%op%"=="4" goto :modulartweaks
if "%op%"=="5" goto :cleaner
if "%op%"=="6" goto :restorepoint
if "%op%"=="7" goto :gui_dashboard
if "%op%"=="8" exit /b
goto :start

:safe_suite
cls
echo ======================================================================
echo          [TIER 1] Applying Recommended Safe Optimizations
echo ======================================================================
echo [*] Telemetry removal (Diagnostic data, DiagTrack, CEIP tasks)
echo [*] UI responsiveness (10ms MenuShowDelay, disable animation delays)
echo [*] Privacy hardening (Disable Bing search in start menu, highlights)
echo [*] Gaming responsiveness (HAGS, Game Mode, raw 1:1 mouse input)
echo [*] Network optimization (Disable P2P Delivery Optimization seeding)
echo [*] Preserves Microsoft Store, Windows Update servicing, and core apps!
echo ======================================================================
echo.
set "curatedRunner=%~dp0..\Apply_Curated_Safe_Suite.ps1"
if not exist "!curatedRunner!" set "curatedRunner=%~dp0Apply_Curated_Safe_Suite.ps1"

if exist "!curatedRunner!" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!curatedRunner!" -Force
) else (
    echo [ERROR] Apply_Curated_Safe_Suite.ps1 not found.
)
echo.
echo Press any key to return to menu...
pause >nul
goto :start

:advanced_menu
cls
echo ======================================================================
echo                  [TIER 2] Advanced Power User Tuning
echo ======================================================================
echo  *1.- Configure SmartScreen (Enable / Disable)
echo  *2.- Optimize Edge Performance (Background Extensions)
echo  *3.- Disable Hibernation (Reclaims hiberfil.sys disk space)
echo  *4.- Optimize Pagefile Configuration
echo  *5.- Disable USB Selective Suspend (Fixes mouse/DAC sleep)
echo  *6.- Uninstall OneDrive Integration
echo  *7.- Go Back
echo ======================================================================
set /p aop=Option [1-7]: 
if "%aop%"=="1" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Security\Configure_SmartScreen.ps1" & goto :advanced_menu
if "%aop%"=="2" regedit.exe /s "%~dp0Browser\Configure Edge Performance.reg" & echo [+] Edge performance applied. & timeout /t 2 >nul & goto :advanced_menu
if "%aop%"=="3" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Power\Disable_Hibernation.ps1" & goto :advanced_menu
if "%aop%"=="4" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Storage-Advanced\Optimize_Pagefile_Configuration.ps1" & goto :advanced_menu
if "%aop%"=="5" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Power\Disable_USB_Selective_Suspend.ps1" & goto :advanced_menu
if "%aop%"=="6" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Sync\Uninstall_OneDrive.ps1" & goto :advanced_menu
if "%aop%"=="7" goto :start
goto :advanced_menu

:critical_lab
cls
echo ======================================================================
echo         [TIER 3] CRITICAL / EXPERIMENTAL HEAVY TESTER LAB
echo ======================================================================
echo  [!] WARNING: The tools below perform aggressive deep modifications.
echo      They are intended for benchmarkers, testers, and isolated VMs.
echo      DO NOT run these on daily production systems unless intentional!
echo ======================================================================
echo.
echo  *1.- Extreme Debloat (Aggressive Appx & Capabilities Purge)
echo  *2.- Deep Component Store Cleanup (DISM ResetBase - Irreversible)
echo  *3.- Toggle Windows Automatic Updates (Policy Mode)
echo  *4.- Aggressive Services Optimization
echo  *5.- Go Back
echo.
set /p cop=Option [1-5]: 
if "%cop%"=="1" goto :run_extreme_debloat
if "%cop%"=="2" goto :run_deep_cleanup
if "%cop%"=="3" goto :toggle_update
if "%cop%"=="4" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Recursos\Services\Optimize Services.ps1" & goto :critical_lab
if "%cop%"=="5" goto :start
goto :critical_lab

:run_extreme_debloat
cls
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0System\Extreme_Debloat.ps1"
echo.
echo Press any key to return...
pause >nul
goto :critical_lab

:run_deep_cleanup
cls
call "%~dp0Storage-Aggressive\Deep Component Cleanup (Aggressive).bat"
echo.
echo Press any key to return...
pause >nul
goto :critical_lab

:toggle_update
cls
echo Windows Update Control:
echo  *1.- Disable Automatic Updates (Policy)
echo  *2.- Enable Automatic Updates
echo  *3.- Go Back
set /p uop=Option [1-3]: 
if "%uop%"=="1" call "%~dp0Updates\Disable Windows Update.bat" & goto :critical_lab
if "%uop%"=="2" call "%~dp0Updates\Enable Windows Update.bat" & goto :critical_lab
goto :critical_lab

:cleaner
cls
echo ======================================================================
echo                         Safe PC Storage Cleaner
echo ======================================================================
call "%~dp0Storage\Safe Temporary Cleanup.bat"
echo.
echo Press any key to return...
pause >nul
goto :start

:restorepoint
cls
echo ======================================================================
echo                       Create Restore Point
echo ======================================================================
echo Creating Windows System Restore Checkpoint...
powershell.exe -NoProfile -Command "Enable-ComputerRestore -Drive $env:SystemDrive; Checkpoint-Computer -Description 'WinAurex Checkpoint' -RestorePointType 'MODIFY_SETTINGS'" 2>nul
echo [+] Restore checkpoint requested.
timeout /t 3 >nul
goto :start

:gui_dashboard
cls
echo Launching WinAurex GUI Dashboard...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Launch_Dashboard.ps1"
goto :start

:modulartweaks
cls
echo ======================================================================
echo                         Modular Tweak Browser
echo ======================================================================
echo  *1.- Performance & Gaming (Boot, Gaming, GPU, Power)
echo  *2.- Privacy & Security (Diagnostics, Privacy, Security, Sync)
echo  *3.- UI & Explorer (Appearance, Explorer, Visual, Shell)
echo  *4.- Storage & Maintenance (Storage, Storage-Advanced)
echo  *5.- Go Back
echo ======================================================================
set /p mtwk=Option: 
if "%mtwk%"=="1" set "CATS=Boot Gaming GPU Power" & goto :modulartweaks_list
if "%mtwk%"=="2" set "CATS=Diagnostics Privacy Security Sync" & goto :modulartweaks_list
if "%mtwk%"=="3" set "CATS=Appearance Explorer Visual Shell" & goto :modulartweaks_list
if "%mtwk%"=="4" set "CATS=Storage Storage-Advanced" & goto :modulartweaks_list
if "%mtwk%"=="5" goto :start
goto :modulartweaks

:modulartweaks_list
cls
echo ======================================================================
echo               Available Modular Tweaks in Selected Categories
echo ======================================================================
setlocal enabledelayedexpansion
set "idx=1"
for %%C in (%CATS%) do (
    if exist "%~dp0%%C" (
        for %%F in ("%~dp0%%C\*.ps1" "%~dp0%%C\*.reg" "%~dp0%%C\*.bat") do (
            echo  *!idx!.- [%%C] %%~nxF
            set "file!idx!=%%F"
            set /a idx+=1
        )
    )
)
echo  *!idx!.- Go Back
echo.
set /p sel=Select tweak number to execute: 
if "!sel!"=="" endlocal & goto :modulartweaks
if "!sel!"=="!idx!" endlocal & goto :modulartweaks

set "chosen=!file%sel%!"
if defined chosen (
    echo.
    echo Executing: !chosen!
    if "!chosen:~-4!"==".ps1" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!chosen!"
    if "!chosen:~-4!"==".reg" regedit.exe /s "!chosen!" & echo Registry applied.
    if "!chosen:~-4!"==".bat" call "!chosen!"
    echo.
    pause
)
endlocal
goto :modulartweaks
