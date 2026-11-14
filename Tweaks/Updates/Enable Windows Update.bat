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

:: 1. Restore any legacy renamed services if present from older scripts
for %%i in (WaaSMedicSvc, wuaueng, usosvc) do (
    if exist "%SystemRoot%\System32\%%i_BAK.dll" (
        takeown /f "%SystemRoot%\System32\%%i_BAK.dll" >nul 2>&1
        icacls "%SystemRoot%\System32\%%i_BAK.dll" /grant *S-1-1-0:F >nul 2>&1
        rename "%SystemRoot%\System32\%%i_BAK.dll" %%i.dll >nul 2>&1
        icacls "%SystemRoot%\System32\%%i.dll" /setowner "NT SERVICE\TrustedInstaller" >nul 2>&1
        icacls "%SystemRoot%\System32\%%i.dll" /remove *S-1-1-0 >nul 2>&1
    )
)

:: 2. Re-register and restore UsoSvc (Update Orchestrator Service) if missing or stripped
sc query UsoSvc >nul 2>&1
if '%errorlevel%' NEQ '0' (
    sc create UsoSvc binPath= "%SystemRoot%\system32\svchost.exe -k netsvcs -p" type= share start= auto depend= rpcss >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v DisplayName /t REG_SZ /d "@%%systemroot%%\system32\usosvc.dll,-101" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Description /t REG_SZ /d "@%%systemroot%%\system32\usosvc.dll,-102" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v ImagePath /t REG_EXPAND_SZ /d "%%SystemRoot%%\system32\svchost.exe -k netsvcs -p" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v ObjectName /t REG_SZ /d "LocalSystem" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v ErrorControl /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Type /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v DependOnService /t REG_MULTI_SZ /d "rpcss" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v ServiceSidType /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc\Parameters" /v ServiceDll /t REG_EXPAND_SZ /d "%%SystemRoot%%\system32\usosvc.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc\Parameters" /v ServiceDllUnloadOnStop /t REG_DWORD /d 1 /f >nul 2>&1

:: 3. Re-register and restore WaaSMedicSvc (Windows Update Medic Service) if missing
sc query WaaSMedicSvc >nul 2>&1
if '%errorlevel%' NEQ '0' (
    sc create WaaSMedicSvc binPath= "%SystemRoot%\system32\svchost.exe -k wusvcs -p" type= share start= demand depend= rpcss >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v DisplayName /t REG_SZ /d "Windows Update Medic Service" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Description /t REG_SZ /d "Enables remediation and protection of Windows Update components." /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v ImagePath /t REG_EXPAND_SZ /d "%%SystemRoot%%\system32\svchost.exe -k wusvcs -p" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v ObjectName /t REG_SZ /d "LocalSystem" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v ErrorControl /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Type /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v DependOnService /t REG_MULTI_SZ /d "rpcss" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v ServiceSidType /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc\Parameters" /v ServiceDll /t REG_EXPAND_SZ /d "%%SystemRoot%%\system32\WaaSMedicSvc.dll" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc\Parameters" /v ServiceDllUnloadOnStop /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost" /v wusvcs /t REG_MULTI_SZ /d "WaaSMedicSvc" /f >nul 2>&1

:: 4. Remove disabling policies & WSUS localhost redirection
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "WUServer" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "WUStatusServer" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "UpdateServiceUrlAlternate" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "DisableOnline" /f >nul 2>&1

:: 5. Restore Settings Page Visibility (Unhide Windows Update in modern Settings app)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; if (Test-Path $path) { $val = (Get-ItemProperty -Path $path -Name 'SettingsPageVisibility' -ErrorAction SilentlyContinue).SettingsPageVisibility; if ($val) { $newVal = ($val -replace ';?windowsupdate', '' -replace 'windowsupdate;?', '').Trim(';'); if ($newVal -eq 'hide:' -or [string]::IsNullOrWhiteSpace($newVal) -or $newVal -eq 'hide') { Remove-ItemProperty -Path $path -Name 'SettingsPageVisibility' -ErrorAction SilentlyContinue } else { Set-ItemProperty -Path $path -Name 'SettingsPageVisibility' -Value $newVal -Force } } }" >nul 2>&1

:: 6. Enable and Start Services
sc config wuauserv start= auto >nul 2>&1
sc config UsoSvc start= auto >nul 2>&1
sc config WaaSMedicSvc start= demand >nul 2>&1
sc config BITS start= delayed-auto >nul 2>&1
sc config dosvc start= delayed-auto >nul 2>&1

net start BITS >nul 2>&1
net start wuauserv >nul 2>&1
net start UsoSvc >nul 2>&1

:: 7. Re-enable scheduled tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\ScanForUpdates" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Report policies" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\PerformRemediation" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /enable >nul 2>&1

echo.
echo [SUCCESS] Windows Update services, policies, and scheduled tasks re-enabled.
exit /b 0
