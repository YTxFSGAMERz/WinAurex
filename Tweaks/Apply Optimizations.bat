@echo off
title PC Optimizer Farhan
setlocal enabledelayedexpansion

:: BatchGotAdmin
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
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
echo.
echo --------------------------------------------------
echo                   Optimizer
echo --------------------------------------------------
echo.

:: Options to select
echo *1.- Apply Recommended Optimizations
echo *2.- System Optimizations
echo *3.- Create Restore Point (Recommended)
echo *4.- Delete temporary files
echo *5.- Disable Windows Defender
echo *6.- Disable Windows Update
echo *7.- About the Optimizer
echo.

:: Options (Automated)
echo.
echo =======================================================
echo    APPLYING ALL RECOMMENDED OPTIMIZATIONS AUTOMATICALLY
echo =======================================================
echo.
timeout /t 3 /nobreak
goto :recommended

:recommended
cls

echo.
echo === Reducing svchost processes ===
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize"') do set MEM=%%i
set /a RAM=%MEM% + 1024000
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%RAM%" /f

echo.
echo === Disabling Wifi Sense ===
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi" /v AllowWiFiHotSpotReporting /t REG_DWORD /d 0 /f
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi" /v AllowAutoConnectToWiFiSenseHotspots /t REG_DWORD /d 0 /f

echo.
echo === Disabling Windows Update Tasks ===
schtasks /Change /TN "\Microsoft\Windows\InstallService\*" /Disable
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\*" /Disable
schtasks /Change /TN "\Microsoft\Windows\UpdateAssistant\*" /Disable
schtasks /Change /TN "\Microsoft\Windows\WaaSMedic\*" /Disable
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\*" /Disable
schtasks /Change /TN "\Microsoft\WindowsUpdate\*" /Disable

echo.
echo === Optimizing Visual Section ===
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 200 /f
reg add "HKCU\Control Panel\Desktop" /v MinAnimate /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v KeyboardDelay /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ListviewShadow /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v TaskbarAnimations /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v VisualFXSetting /t REG_DWORD /d 3 /f
reg add "HKCU\Control Panel\Desktop" /v EnableAeroPeek /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f

echo.
echo === Disabling Teredo ===
netsh interface teredo set state disabled

echo.
echo === Disabling Telemetry Tasks ===
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClient" /Disable
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\MareBackup" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\PcaPatchDbTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Maps\MapsUpdateTask" /Disable

echo.
echo === Disabling Telemetry Registry ===
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f

echo.
echo === Applying Registry Tweaks ===
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d 10000 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "MaxCmds" /t REG_DWORD /d 100 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "MaxThreads" /t REG_DWORD /d 100 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "MaxCollectionCount" /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f
reg add "HKLM\SYSTEM\ControlSet001\Services\Ndu" /v Start /t REG_DWORD /d 2 /f
reg add "HKCU\Control Panel\Mouse" /v MouseHoverTime /t REG_SZ /d "400" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v IRPStackSize /t REG_DWORD /d 30 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAMeetNow /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v ScoobeSystemSettingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f

echo.
echo === Setting services to manual ===
sc config "AJRouter" start= demand
sc config "ALG" start= demand
sc config "AppIDSvc" start= demand
sc config "AppMgmt" start= demand
sc config "AppReadiness" start= demand
sc config "AppXSvc" start= demand
sc config "Appinfo" start= demand
sc config "AssignedAccessManagerSvc" start= demand
sc config "AxInstSV" start= demand
sc config "BDESVC" start= demand
sc config "BTAGService" start= demand
sc config "BcastDVRUserService_*" start= demand
sc config "BluetoothUserService_*" start= demand
sc config "Browser" start= demand
sc config "CaptureService_*" start= demand
sc config "CertPropSvc" start= demand
sc config "ClipSVC" start= demand
sc config "ConsentUxUserSvc_*" start= demand
sc config "CredentialEnrollmentManagerUserSvc_*" start= demand
sc config "CscService" start= demand
sc config "DcpSvc" start= demand
sc config "DevQueryBroker" start= demand
sc config "DeviceAssociationBrokerSvc_*" start= demand
sc config "DeviceAssociationService" start= demand
sc config "DeviceInstall" start= demand
sc config "DevicePickerUserSvc_*" start= demand
sc config "DevicesFlowUserSvc_*" start= demand
sc config "DisplayEnhancementService" start= demand
sc config "DmEnrollmentSvc" start= demand
sc config "DsSvc" start= demand
sc config "DsmSvc" start= demand
sc config "EFS" start= demand
sc config "EapHost" start= demand
sc config "EntAppSvc" start= demand
sc config "FDResPub" start= demand
sc config "Fax" start= demand
sc config "FrameServer" start= demand
sc config "FrameServerMonitor" start= demand
sc config "GraphicsPerfSvc" start= demand
sc config "HomeGroupListener" start= demand
sc config "HomeGroupProvider" start= demand
sc config "HvHost" start= demand
sc config "IEEtwCollectorService" start= demand
sc config "IKEEXT" start= demand
sc config "InstallService" start= demand
sc config "InventorySvc" start= demand
sc config "IpxlatCfgSvc" start= demand
sc config "KtmRm" start= demand
sc config "LicenseManager" start= demand
sc config "LxpSvc" start= demand
sc config "MSDTC" start= demand
sc config "MSiSCSI" start= demand
sc config "McpManagementService" start= demand
sc config "MessagingService_*" start= demand
sc config "MicrosoftEdgeElevationService" start= demand
sc config "MixedRealityOpenXRSvc" start= demand
sc config "NPSMSvc_*" start= demand
sc config "NaturalAuthentication" start= demand
sc config "NcaSvc" start= demand
sc config "NcbService" start= demand
sc config "NcdAutoSetup" start= demand
sc config "NetSetupSvc" start= demand
sc config "Netman" start= demand
sc config "NgcCtnrSvc" start= demand
sc config "NgcSvc" start= demand
sc config "NlaSvc" start= demand
sc config "P9RdrService_*" start= demand
sc config "PNRPAutoReg" start= demand
sc config "PNRPsvc" start= demand
sc config "PeerDistSvc" start= demand
sc config "PenService_*" start= demand
sc config "PerfHost" start= demand
sc config "PhoneSvc" start= demand
sc config "PimIndexMaintenanceSvc_*" start= demand
sc config "PlugPlay" start= demand
sc config "PolicyAgent" start= demand
sc config "PrintNotify" start= demand
sc config "PrintWorkflowUserSvc_*" start= demand
sc config "PushToInstall" start= demand
sc config "QWAVE" start= demand
sc config "RasAuto" start= demand
sc config "RasMan" start= demand
sc config "RetailDemo" start= demand
sc config "RmSvc" start= demand
sc config "RpcLocator" start= demand
sc config "SCPolicySvc" start= demand
sc config "SCardSvr" start= demand
sc config "SDRSVC" start= demand
sc config "SEMgrSvc" start= demand
sc config "SNMPTRAP" start= demand
sc config "SNMPTrap" start= demand
sc config "SSDPSRV" start= demand
sc config "ScDeviceEnum" start= demand
sc config "SecurityHealthService" start= demand
sc config "Sense" start= demand
sc config "SensorDataService" start= demand
sc config "SensorService" start= demand
sc config "SensrSvc" start= demand
sc config "SessionEnv" start= demand
sc config "SharedAccess" start= demand
sc config "SharedRealitySvc" start= demand
sc config "SmsRouter" start= demand
sc config "SstpSvc" start= demand
sc config "StiSvc" start= demand
sc config "TabletInputService" start= demand
sc config "TapiSrv" start= demand
sc config "TieringEngineService" start= demand
sc config "TimeBroker" start= demand
sc config "TimeBrokerSvc" start= demand
sc config "TokenBroker" start= demand
sc config "TroubleshootingSvc" start= demand
sc config "TrustedInstaller" start= demand
sc config "UI0Detect" start= demand
sc config "UdkUserSvc_*" start= demand
sc config "UmRdpService" start= demand
sc config "UnistoreSvc_*" start= demand
sc config "UserDataSvc_*" start= demand
sc config "VSS" start= demand
sc config "VacSvc" start= demand
sc config "W32Time" start= demand
sc config "WEPHOSTSVC" start= demand
sc config "WFDSConMgrSvc" start= demand
sc config "WMPNetworkSvc" start= demand
sc config "WManSvc" start= demand
sc config "WPDBusEnum" start= demand
sc config "WSService" start= demand
sc config "WaaSMedicSvc" start= demand
sc config "WalletService" start= demand
sc config "WarpJITSvc" start= demand
sc config "WbioSrvc" start= demand
sc config "WcsPlugInService" start= demand
sc config "WdNisSvc" start= demand
sc config "WdiServiceHost" start= demand
sc config "WdiSystemHost" start= demand
sc config "WebClient" start= demand
sc config "Wecsvc" start= demand
sc config "WerSvc" start= demand
sc config "WiaRpc" start= demand
sc config "WinHttpAutoProxySvc" start= demand
sc config "WinRM" start= demand
sc config "WpcMonSvc" start= demand
sc config "XblAuthManager" start= demand
sc config "XblGameSave" start= demand
sc config "XboxGipSvc" start= demand
sc config "XboxNetApiSvc" start= demand
sc config "autotimesvc" start= demand
sc config "bthserv" start= demand
sc config "camsvc" start= demand
sc config "cloudidsvc" start= demand
sc config "dcsvc" start= demand
sc config "defragsvc" start= demand
sc config "diagnosticshub.standardcollector.service" start= demand
sc config "diagsvc" start= demand
sc config "dmwappushservice" start= demand
sc config "dot3svc" start= demand
sc config "edgeupdate" start= demand
sc config "edgeupdatem" start= demand
sc config "embeddedmode" start= demand
sc config "fdPHost" start= demand
sc config "fhsvc" start= demand
sc config "hidserv" start= demand
sc config "icssvc" start= demand
sc config "lfsvc" start= demand
sc config "lltdsvc" start= demand
sc config "lmhosts" start= demand
sc config "msiserver" start= demand
sc config "netprofm" start= demand
sc config "p2pimsvc" start= demand
sc config "p2psvc" start= demand
sc config "perceptionsimulation" start= demand
sc config "pla" start= demand
sc config "seclogon" start= demand
sc config "smphost" start= demand
sc config "spectrum" start= demand
sc config "svsvc" start= demand
sc config "swprv" start= demand
sc config "upnphost" start= demand
sc config "vds" start= demand
sc config "vmicguestinterface" start= demand
sc config "vmicheartbeat" start= demand
sc config "vmickvpexchange" start= demand
sc config "vmicrdv" start= demand
sc config "vmicshutdown" start= demand
sc config "vmictimesync" start= demand
sc config "vmicvmsession" start= demand
sc config "vmicvss" start= demand
sc config "vmvss" start= demand
sc config "wbengine" start= demand
sc config "wcncsvc" start= demand
sc config "webthreatdefsvc" start= demand
sc config "wercplsupport" start= demand
sc config "wisvc" start= demand
sc config "wlidsvc" start= demand
sc config "wlpasvc" start= demand
sc config "wmiApSrv" start= demand
sc config "workfolderssvc" start= demand
sc config "wuauserv" start= demand
sc config "wudfsvc" start= demand

echo.
echo === Disabling Services ===
sc config "diagnosticshub.standardcollector.service" start= disabled
sc config "DiagTrack" start= disabled
sc config "DPS" start= disabled
sc config "FontCache" start= disabled
sc config "FontCache3.0.0.0" start= disabled
sc config "SystemUsageReportSvc_QUEENCREEK" start= disabled
sc config "GpuEnergyDrv" start= disabled
sc config "ShellHWDetection" start= disabled
sc config "SgrmAgent" start= disabled
sc config "SgrmBroker" start= disabled
sc config "uhssvc" start= disabled
sc config "TrkWks" start= disabled
sc config "WdiServiceHost" start= disabled
sc config "WdiSystemHost" start= disabled
sc config "WSearch" start= disabled
sc config "diagsvc" start= disabled

echo === Clearing DNS cache ===
echo.
ipconfig /flushdns >nul 2>&1

echo.
echo === Applying Repository Master Recommended Profile ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Applying Workstation Master Profile (Recommended)...'; echo 'y' | & '%~dp0Profiles\Apply_Workstation_Master_Profile.ps1'"

timeout /t 3 /nobreak
goto :done

:temp
echo.
echo Deleting Temporary Files...
del /S /F /Q "%temp%"
del /S /F /Q "%WINDIR%\Temp\*.*"
del /S /F /Q "%WINDIR%\Prefetch\*.*" 
echo.
goto :done

:restorepoint
cls

echo.
echo Creating restore point...
"powershell.exe" Enable-ComputerRestore -Drive "%SystemDrive%"
"powershell.exe" -Command "Checkpoint-Computer -Description 'Optimizer Script'"
goto :start

:defender
cls

echo --------------------------------------------------
echo                   Optimizer
echo --------------------------------------------------
echo.

:: Options to select
echo *1.- Disable Defender
echo *2.- Enable Defender
echo *3.- Go Back.
echo.

:: Code to go to menu with Options
set /p oput=Option: 
if "%oput%"=="1" goto :DF
if "%oput%"=="2" goto :DE
if "%oput%"=="3" goto :Start
if "%oput%"=="" goto :Start



:DF
cls
echo.
echo --------------------------------------------------
echo        Disabling Windows Defender
echo --------------------------------------------------
echo.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Sense" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wscsvc" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotification" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d 1 /f
timeout /t 3 /nobreak
goto :Start



:DE
cls
echo.
echo --------------------------------------------------
echo            Enabling Windows Defender.
echo --------------------------------------------------
echo.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend" /v "Start" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v "Start" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Sense" /v "Start" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wscsvc" /v "Start" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotification" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d 0 /f
timeout /t 3 /nobreak
goto :start

:optitweakspc
cls

echo --------------------------------------------------
echo                   Optimizer
echo --------------------------------------------------
echo.

:: Options to select
echo *1.- Set services to Manual
echo *2.- Disable Fullscreen Optimizations
echo *3.- Disable Telemetry
echo *4.- Disable unnecessary services
echo *5.- Disable background apps
echo *6.- Reduce Windows quality
echo *7.- High priority for Games
echo *8.- Reduce svchost processes
echo *9.- Disable GameDVR
echo *10.- Go Back
echo.

:: Options
set /p optwkpc=Option: 
if "%optwkpc%"=="" goto :start
if "%optwkpc%"=="1" goto :servicemanual
if "%optwkpc%"=="2" goto :disablefullscreenoptimizations
if "%optwkpc%"=="3" goto :disabletelemetry
if "%optwkpc%"=="4" goto :disableservices
if "%optwkpc%"=="5" goto :disablebackgroundapps
if "%optwkpc%"=="6" goto :reducewindows
if "%optwkpc%"=="7" goto :highprioritygame
if "%optwkpc%"=="8" goto :svchostprocess
if "%optwkpc%"=="9" goto :disablegamedvr
if "%optwkpc%"=="10" goto :start
if "%optwkpc%"=="" goto :Start

:servicemanual
cls

echo.
echo Setting services to manual...
sc config "AJRouter" start= demand
sc config "ALG" start= demand
sc config "AppIDSvc" start= demand
sc config "AppMgmt" start= demand
sc config "AppReadiness" start= demand
sc config "AppXSvc" start= demand
sc config "Appinfo" start= demand
sc config "AssignedAccessManagerSvc" start= demand
sc config "AxInstSV" start= demand
sc config "BDESVC" start= demand
sc config "BTAGService" start= demand
sc config "BcastDVRUserService_*" start= demand
sc config "BluetoothUserService_*" start= demand
sc config "Browser" start= demand
sc config "CaptureService_*" start= demand
sc config "CertPropSvc" start= demand
sc config "ClipSVC" start= demand
sc config "ConsentUxUserSvc_*" start= demand
sc config "CredentialEnrollmentManagerUserSvc_*" start= demand
sc config "CscService" start= demand
sc config "DcpSvc" start= demand
sc config "DevQueryBroker" start= demand
sc config "DeviceAssociationBrokerSvc_*" start= demand
sc config "DeviceAssociationService" start= demand
sc config "DeviceInstall" start= demand
sc config "DevicePickerUserSvc_*" start= demand
sc config "DevicesFlowUserSvc_*" start= demand
sc config "DisplayEnhancementService" start= demand
sc config "DmEnrollmentSvc" start= demand
sc config "DsSvc" start= demand
sc config "DsmSvc" start= demand
sc config "EFS" start= demand
sc config "EapHost" start= demand
sc config "EntAppSvc" start= demand
sc config "FDResPub" start= demand
sc config "Fax" start= demand
sc config "FrameServer" start= demand
sc config "FrameServerMonitor" start= demand
sc config "GraphicsPerfSvc" start= demand
sc config "HomeGroupListener" start= demand
sc config "HomeGroupProvider" start= demand
sc config "HvHost" start= demand
sc config "IEEtwCollectorService" start= demand
sc config "IKEEXT" start= demand
sc config "InstallService" start= demand
sc config "InventorySvc" start= demand
sc config "IpxlatCfgSvc" start= demand
sc config "KtmRm" start= demand
sc config "LicenseManager" start= demand
sc config "LxpSvc" start= demand
sc config "MSDTC" start= demand
sc config "MSiSCSI" start= demand
sc config "McpManagementService" start= demand
sc config "MessagingService_*" start= demand
sc config "MicrosoftEdgeElevationService" start= demand
sc config "MixedRealityOpenXRSvc" start= demand
sc config "NPSMSvc_*" start= demand
sc config "NaturalAuthentication" start= demand
sc config "NcaSvc" start= demand
sc config "NcbService" start= demand
sc config "NcdAutoSetup" start= demand
sc config "NetSetupSvc" start= demand
sc config "Netman" start= demand
sc config "NgcCtnrSvc" start= demand
sc config "NgcSvc" start= demand
sc config "NlaSvc" start= demand
sc config "P9RdrService_*" start= demand
sc config "PNRPAutoReg" start= demand
sc config "PNRPsvc" start= demand
sc config "PeerDistSvc" start= demand
sc config "PenService_*" start= demand
sc config "PerfHost" start= demand
sc config "PhoneSvc" start= demand
sc config "PimIndexMaintenanceSvc_*" start= demand
sc config "PlugPlay" start= demand
sc config "PolicyAgent" start= demand
sc config "PrintNotify" start= demand
sc config "PrintWorkflowUserSvc_*" start= demand
sc config "PushToInstall" start= demand
sc config "QWAVE" start= demand
sc config "RasAuto" start= demand
sc config "RasMan" start= demand
sc config "RetailDemo" start= demand
sc config "RmSvc" start= demand
sc config "RpcLocator" start= demand
sc config "SCPolicySvc" start= demand
sc config "SCardSvr" start= demand
sc config "SDRSVC" start= demand
sc config "SEMgrSvc" start= demand
sc config "SNMPTRAP" start= demand
sc config "SNMPTrap" start= demand
sc config "SSDPSRV" start= demand
sc config "ScDeviceEnum" start= demand
sc config "SecurityHealthService" start= demand
sc config "Sense" start= demand
sc config "SensorDataService" start= demand
sc config "SensorService" start= demand
sc config "SensrSvc" start= demand
sc config "SessionEnv" start= demand
sc config "SharedAccess" start= demand
sc config "SharedRealitySvc" start= demand
sc config "SmsRouter" start= demand
sc config "SstpSvc" start= demand
sc config "StiSvc" start= demand
sc config "TabletInputService" start= demand
sc config "TapiSrv" start= demand
sc config "TieringEngineService" start= demand
sc config "TimeBroker" start= demand
sc config "TimeBrokerSvc" start= demand
sc config "TokenBroker" start= demand
sc config "TroubleshootingSvc" start= demand
sc config "TrustedInstaller" start= demand
sc config "UI0Detect" start= demand
sc config "UdkUserSvc_*" start= demand
sc config "UmRdpService" start= demand
sc config "UnistoreSvc_*" start= demand
sc config "UserDataSvc_*" start= demand
sc config "VSS" start= demand
sc config "VacSvc" start= demand
sc config "W32Time" start= demand
sc config "WEPHOSTSVC" start= demand
sc config "WFDSConMgrSvc" start= demand
sc config "WMPNetworkSvc" start= demand
sc config "WManSvc" start= demand
sc config "WPDBusEnum" start= demand
sc config "WSService" start= demand
sc config "WaaSMedicSvc" start= demand
sc config "WalletService" start= demand
sc config "WarpJITSvc" start= demand
sc config "WbioSrvc" start= demand
sc config "WcsPlugInService" start= demand
sc config "WdNisSvc" start= demand
sc config "WdiServiceHost" start= demand
sc config "WdiSystemHost" start= demand
sc config "WebClient" start= demand
sc config "Wecsvc" start= demand
sc config "WerSvc" start= demand
sc config "WiaRpc" start= demand
sc config "WinHttpAutoProxySvc" start= demand
sc config "WinRM" start= demand
sc config "WpcMonSvc" start= demand
sc config "XblAuthManager" start= demand
sc config "XblGameSave" start= demand
sc config "XboxGipSvc" start= demand
sc config "XboxNetApiSvc" start= demand
sc config "autotimesvc" start= demand
sc config "bthserv" start= demand
sc config "camsvc" start= demand
sc config "cloudidsvc" start= demand
sc config "dcsvc" start= demand
sc config "defragsvc" start= demand
sc config "diagnosticshub.standardcollector.service" start= demand
sc config "diagsvc" start= demand
sc config "dmwappushservice" start= demand
sc config "dot3svc" start= demand
sc config "edgeupdate" start= demand
sc config "edgeupdatem" start= demand
sc config "embeddedmode" start= demand
sc config "fdPHost" start= demand
sc config "fhsvc" start= demand
sc config "hidserv" start= demand
sc config "icssvc" start= demand
sc config "lfsvc" start= demand
sc config "lltdsvc" start= demand
sc config "lmhosts" start= demand
sc config "msiserver" start= demand
sc config "netprofm" start= demand
sc config "p2pimsvc" start= demand
sc config "p2psvc" start= demand
sc config "perceptionsimulation" start= demand
sc config "pla" start= demand
sc config "seclogon" start= demand
sc config "smphost" start= demand
sc config "spectrum" start= demand
sc config "svsvc" start= demand
sc config "swprv" start= demand
sc config "upnphost" start= demand
sc config "vds" start= demand
sc config "vmicguestinterface" start= demand
sc config "vmicheartbeat" start= demand
sc config "vmickvpexchange" start= demand
sc config "vmicrdv" start= demand
sc config "vmicshutdown" start= demand
sc config "vmictimesync" start= demand
sc config "vmicvmsession" start= demand
sc config "vmicvss" start= demand
sc config "vmvss" start= demand
sc config "wbengine" start= demand
sc config "wcncsvc" start= demand
sc config "webthreatdefsvc" start= demand
sc config "wercplsupport" start= demand
sc config "wisvc" start= demand
sc config "wlidsvc" start= demand
sc config "wlpasvc" start= demand
sc config "wmiApSrv" start= demand
sc config "workfolderssvc" start= demand
sc config "wuauserv" start= demand
sc config "wudfsvc" start= demand

timeout /t 3 /nobreak
goto :done

:disablefullscreenoptimizations
cls

echo.
echo Disabling Fullscreen Optimizations...

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 1 /f

timeout /t 3 /nobreak
goto :done

:disabletelemetry
cls

echo.
echo Disabling Telemetry Registry...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f

timeout /t 3 /nobreak
goto :done

:disableservices
cls

echo.
echo === Disabling Services ===
sc config "DiagTrack" start= disabled
sc config "DPS" start= disabled
sc config "FontCache" start= disabled
sc config "FontCache3.0.0.0" start= disabled
sc config "SystemUsageReportSvc_QUEENCREEK" start= disabled
sc config "GpuEnergyDrv" start= disabled
sc config "ShellHWDetection" start= disabled
sc config "SgrmAgent" start= disabled
sc config "SgrmBroker" start= disabled
sc config "uhssvc" start= disabled
sc config "WdiServiceHost" start= disabled
sc config "WdiSystemHost" start= disabled
sc config "WSearch" start= disabled
sc config "diagsvc" start= disabled

timeout /t 3 /nobreak
goto :done

:disablebackgroundapps
cls

echo Disabling background applications
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v GlobalUserDisabled /t REG_DWORD /d 1 /f

timeout /t 3 /nobreak
goto :done

:reducewindows
cls

echo.
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 200 /f
reg add "HKCU\Control Panel\Desktop" /v KeyboardDelay /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ListviewShadow /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v TaskbarAnimations /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v VisualFXSetting /t REG_DWORD /d 3 /f
reg add "HKCU\Control Panel\Desktop" /v EnableAeroPeek /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /v TaskbarMn /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /v TaskbarDa /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f

timeout /t 3 /nobreak
goto :done


:highprioritygame
cls

echo.
echo Setting high priority for games...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csgo.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\cs2.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FortniteClient-Win64-Shipping.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\gta_3.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\gta_vc.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\gta_sa.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GTAIV.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GTA5.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\java.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\javaw.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\minecraft.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Minecraft.Windows.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\obs32.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\obs64.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\PPSSPP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ShellExperienceHost.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 5 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\svchost.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 5 /f
goto :done

:svchostprocess
cls

echo Reducing svchost processes...
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set MEM=%%i
set /a RAM=%MEM% + 1024000
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%RAM%" /f

timeout /t 3 /nobreak
goto :done

:disablegamedvr
cls

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 1 /f

timeout /t 3 /nobreak
goto :done

:update
cls

echo --------------------------------------------------
echo                   Optimizer
echo --------------------------------------------------
echo.

:: Options to select
echo *1.- Disable Windows Update
echo *2.- Enable Windows Update
echo *3.- Go Back.
echo.

:: Code to go to menu with Options
set /p oput=Option: 
if "%oput%"=="1" goto :WA
if "%oput%"=="2" goto :WD
if "%oput%"=="3" goto :Start
if "%oput%"=="" goto :Start


:WA
cls

:: Disable update related services
for %%i in (wuauserv, UsoSvc, uhssvc, WaaSMedicSvc) do (
	net stop %%i
	sc config %%i start= disabled
	sc failure %%i reset= 0 actions= ""
)

:: Brute force rename services
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i.dll && icacls C:\Windows\System32\%%i.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i.dll %%i_BAK.dll
	icacls C:\Windows\System32\%%i_BAK.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i_BAK.dll /remove *S-1-1-0
)

:: Update registry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 000000000000000000000000030000001400000000000000c0d4010000000000e09304000000000000000000 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

:: Delete downloaded update files
erase /f /s /q c:\windows\softwaredistribution\*.* && rmdir /s /q c:\windows\softwaredistribution

:: Disable all update related scheduled tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\*" /disable
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\*" /disable
schtasks /change /tn "\Microsoft\Windows\UpdateAssistant\*" /disable
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\*" /disable
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\*" /disable
schtasks /change /tn "\Microsoft\WindowsUpdate\*" /disable

:: Go Back
timeout /t 3 /nobreak
goto :update  

:WD
cls
:: Enable update related services
sc config wuauserv start= auto
sc config UsoSvc start= auto
sc config uhssvc start= delayed-auto

:: Restore renamed services
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i_BAK.dll && icacls C:\Windows\System32\%%i_BAK.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i_BAK.dll %%i.dll
	icacls C:\Windows\System32\%%i.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i.dll /remove *S-1-1-0
)

:: Update registry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 840300000000000000000000030000001400000001000000c0d4010001000000e09304000000000000000000 /f
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f

:: Enable all update related scheduled tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\*" /enable
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\*" /enable
schtasks /change /tn "\Microsoft\Windows\UpdateAssistant\*" /enable
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\*" /enable
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\*" /enable
schtasks /change /tn "\Microsoft\WindowsUpdate\*" /enable

:: Go Back
timeout /t 3 /nobreak
goto :update

:about
cls

echo ---------------------------------------------------------------------------------
echo                                 Optimizer
echo ---------------------------------------------------------------------------------
echo.
echo A simple and efficient PC optimizer to increase performance on low-end systems.
echo Special credits to Farhan for the optimizations.
echo.
echo ---------------------------------------------------------------------------------
echo.

:: Code to go to menu with Options
pause
goto :start

:done
cls
echo --------------------------------------------------
echo            Optimization completed!
echo --------------------------------------------------
echo.
echo Your operating system was optimized correctly!	  
echo Please restart your PC to notice the change.
echo.
echo --------------------------------------------------
timeout /t 3 /nobreak
goto :start
