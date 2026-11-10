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
echo                     Enabling Windows Update
echo ======================================================================

:: Restore any legacy renamed services if present from older scripts
for %%i in (WaaSMedicSvc, wuaueng) do (
    if exist "C:\Windows\System32\%%i_BAK.dll" (
        takeown /f C:\Windows\System32\%%i_BAK.dll >nul 2>&1
        icacls C:\Windows\System32\%%i_BAK.dll /grant *S-1-1-0:F >nul 2>&1
        rename C:\Windows\System32\%%i_BAK.dll %%i.dll >nul 2>&1
        icacls C:\Windows\System32\%%i.dll /setowner "NT SERVICE\TrustedInstaller" >nul 2>&1
        icacls C:\Windows\System32\%%i.dll /remove *S-1-1-0 >nul 2>&1
    )
)

:: Remove disabling policies
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f >nul 2>&1

:: Enable services
sc config wuauserv start= auto >nul 2>&1
sc config UsoSvc start= auto >nul 2>&1
sc config WaaSMedicSvc start= demand >nul 2>&1
net start wuauserv >nul 2>&1

:: Re-enable scheduled tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\ScanForUpdates" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Report policies" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\PerformRemediation" /enable >nul 2>&1

echo.
echo [SUCCESS] Windows Update services and scheduled tasks re-enabled.
timeout /t 3 /nobreak >nul
exit /b
