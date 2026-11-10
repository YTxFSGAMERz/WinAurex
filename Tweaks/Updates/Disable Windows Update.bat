@echo off
setlocal enabledelayedexpansion

:: BatchGotAdmin
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

echo ======================================================================
echo              Disabling Windows Automatic Updates (Policy Method)
echo ======================================================================
echo Disabling automatic downloads and updates via Group Policy...
echo System binaries will NOT be modified or renamed.

:: Configure Group Policies to disable automatic updating
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1

:: Pause update orchestrator and medic tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\ScanForUpdates" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Report policies" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\PerformRemediation" /disable >nul 2>&1

:: Set services to manual demand
net stop wuauserv >nul 2>&1
sc config wuauserv start= demand >nul 2>&1
net stop WaaSMedicSvc >nul 2>&1
sc config WaaSMedicSvc start= demand >nul 2>&1

echo.
echo [SUCCESS] Windows Automatic Updates disabled via policy.
echo Windows will notify before downloading, preventing unexpected reboots.
timeout /t 3 /nobreak >nul
exit /b
