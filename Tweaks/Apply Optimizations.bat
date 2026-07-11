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
echo *8.- Explore Modular Tweaks
echo.

:: Options
set /p op=Option: 
if "%op%"=="" goto :start
if "%op%"=="1" goto :recommended
if "%op%"=="2" goto :optitweakspc
if "%op%"=="3" goto :restorepoint
if "%op%"=="4" goto :temp
if "%op%"=="5" goto :defender
if "%op%"=="6" goto :update
if "%op%"=="7" goto :about
if "%op%"=="8" goto :modulartweaks
if "%op%"=="" goto :Start

:recommended
cls

echo.
echo === Reducing svchost processes ===
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize"') do set MEM=%%i
set /a RAM=%MEM% + 1024000
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%RAM%" /f 2>nul

echo.
echo === Disabling Wifi Sense ===
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi" /v AllowWiFiHotSpotReporting /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi" /v AllowAutoConnectToWiFiSenseHotspots /t REG_DWORD /d 0 /f 2>nul

echo.
echo === Disabling Windows Update Tasks ===
schtasks /Change /TN "\Microsoft\Windows\InstallService\*" /Disable 2>nul
schtasks /Change /TN "\Microsoft\Windows\UpdateOrchestrator\*" /Disable 2>nul
schtasks /Change /TN "\Microsoft\Windows\UpdateAssistant\*" /Disable 2>nul
schtasks /Change /TN "\Microsoft\Windows\WaaSMedic\*" /Disable 2>nul
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\*" /Disable 2>nul
schtasks /Change /TN "\Microsoft\WindowsUpdate\*" /Disable 2>nul

echo.
echo === Optimizing Visual Section ===
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 200 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v MinAnimate /t REG_SZ /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v KeyboardDelay /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v ListviewShadow /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v TaskbarAnimations /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v VisualFXSetting /t REG_DWORD /d 3 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v EnableAeroPeek /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_DWORD /d 1 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_DWORD /d 1 /f 2>nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f 2>nul

echo.
echo === Disabling Teredo ===
netsh interface teredo set state disabled

echo.
echo === Disabling Telemetry Tasks ===
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClient" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Application Experience\MareBackup" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Application Experience\PcaPatchDbTask" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Maps\MapsUpdateTask" /Disable 2>nul

echo.
echo === Disabling Telemetry Registry ===
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f 2>nul
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f 2>nul

echo.
echo === Applying Registry Tweaks ===
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d 0 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d 10000 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "MaxCmds" /t REG_DWORD /d 100 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "MaxThreads" /t REG_DWORD /d 100 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "MaxCollectionCount" /t REG_DWORD /d 32 /f 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\Ndu" /v Start /t REG_DWORD /d 2 /f 2>nul
reg add "HKCU\Control Panel\Mouse" /v MouseHoverTime /t REG_SZ /d "400" /f 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v IRPStackSize /t REG_DWORD /d 30 /f 2>nul
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAMeetNow /t REG_DWORD /d 1 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v ScoobeSystemSettingEnabled /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f 2>nul

echo.
echo === Setting services to manual ===
sc config "AJRouter" start= demand 2>nul
sc config "ALG" start= demand 2>nul
sc config "AppIDSvc" start= demand 2>nul
sc config "AppMgmt" start= demand 2>nul
sc config "AppReadiness" start= demand 2>nul
sc config "AppXSvc" start= demand 2>nul
sc config "Appinfo" start= demand 2>nul
sc config "AssignedAccessManagerSvc" start= demand 2>nul
sc config "AxInstSV" start= demand 2>nul
sc config "BDESVC" start= demand 2>nul
sc config "BTAGService" start= demand 2>nul
sc config "BcastDVRUserService_*" start= demand 2>nul
sc config "BluetoothUserService_*" start= demand 2>nul
sc config "Browser" start= demand 2>nul
sc config "CaptureService_*" start= demand 2>nul
sc config "CertPropSvc" start= demand 2>nul
sc config "ClipSVC" start= demand 2>nul
sc config "ConsentUxUserSvc_*" start= demand 2>nul
sc config "CredentialEnrollmentManagerUserSvc_*" start= demand 2>nul
sc config "CscService" start= demand 2>nul
sc config "DcpSvc" start= demand 2>nul
sc config "DevQueryBroker" start= demand 2>nul
sc config "DeviceAssociationBrokerSvc_*" start= demand 2>nul
sc config "DeviceAssociationService" start= demand 2>nul
sc config "DeviceInstall" start= demand 2>nul
sc config "DevicePickerUserSvc_*" start= demand 2>nul
sc config "DevicesFlowUserSvc_*" start= demand 2>nul
sc config "DisplayEnhancementService" start= demand 2>nul
sc config "DmEnrollmentSvc" start= demand 2>nul
sc config "DsSvc" start= demand 2>nul
sc config "DsmSvc" start= demand 2>nul
sc config "EFS" start= demand 2>nul
sc config "EapHost" start= demand 2>nul
sc config "EntAppSvc" start= demand 2>nul
sc config "FDResPub" start= demand 2>nul
sc config "Fax" start= demand 2>nul
sc config "FrameServer" start= demand 2>nul
sc config "FrameServerMonitor" start= demand 2>nul
sc config "GraphicsPerfSvc" start= demand 2>nul
sc config "HomeGroupListener" start= demand 2>nul
sc config "HomeGroupProvider" start= demand 2>nul
sc config "HvHost" start= demand 2>nul
sc config "IEEtwCollectorService" start= demand 2>nul
sc config "IKEEXT" start= demand 2>nul
sc config "InstallService" start= demand 2>nul
sc config "InventorySvc" start= demand 2>nul
sc config "IpxlatCfgSvc" start= demand 2>nul
sc config "KtmRm" start= demand 2>nul
sc config "LicenseManager" start= demand 2>nul
sc config "LxpSvc" start= demand 2>nul
sc config "MSDTC" start= demand 2>nul
sc config "MSiSCSI" start= demand 2>nul
sc config "McpManagementService" start= demand 2>nul
sc config "MessagingService_*" start= demand 2>nul
sc config "MicrosoftEdgeElevationService" start= demand 2>nul
sc config "MixedRealityOpenXRSvc" start= demand 2>nul
sc config "NPSMSvc_*" start= demand 2>nul
sc config "NaturalAuthentication" start= demand 2>nul
sc config "NcaSvc" start= demand 2>nul
sc config "NcbService" start= demand 2>nul
sc config "NcdAutoSetup" start= demand 2>nul
sc config "NetSetupSvc" start= demand 2>nul
sc config "Netman" start= demand 2>nul
sc config "NgcCtnrSvc" start= demand 2>nul
sc config "NgcSvc" start= demand 2>nul
sc config "NlaSvc" start= demand 2>nul
sc config "P9RdrService_*" start= demand 2>nul
sc config "PNRPAutoReg" start= demand 2>nul
sc config "PNRPsvc" start= demand 2>nul
sc config "PeerDistSvc" start= demand 2>nul
sc config "PenService_*" start= demand 2>nul
sc config "PerfHost" start= demand 2>nul
sc config "PhoneSvc" start= demand 2>nul
sc config "PimIndexMaintenanceSvc_*" start= demand 2>nul
sc config "PlugPlay" start= demand 2>nul
sc config "PolicyAgent" start= demand 2>nul
sc config "PrintNotify" start= demand 2>nul
sc config "PrintWorkflowUserSvc_*" start= demand 2>nul
sc config "PushToInstall" start= demand 2>nul
sc config "QWAVE" start= demand 2>nul
sc config "RasAuto" start= demand 2>nul
sc config "RasMan" start= demand 2>nul
sc config "RetailDemo" start= demand 2>nul
sc config "RmSvc" start= demand 2>nul
sc config "RpcLocator" start= demand 2>nul
sc config "SCPolicySvc" start= demand 2>nul
sc config "SCardSvr" start= demand 2>nul
sc config "SDRSVC" start= demand 2>nul
sc config "SEMgrSvc" start= demand 2>nul
sc config "SNMPTRAP" start= demand 2>nul
sc config "SNMPTrap" start= demand 2>nul
sc config "SSDPSRV" start= demand 2>nul
sc config "ScDeviceEnum" start= demand 2>nul
sc config "SecurityHealthService" start= demand 2>nul
sc config "Sense" start= demand 2>nul
sc config "SensorDataService" start= demand 2>nul
sc config "SensorService" start= demand 2>nul
sc config "SensrSvc" start= demand 2>nul
sc config "SessionEnv" start= demand 2>nul
sc config "SharedAccess" start= demand 2>nul
sc config "SharedRealitySvc" start= demand 2>nul
sc config "SmsRouter" start= demand 2>nul
sc config "SstpSvc" start= demand 2>nul
sc config "StiSvc" start= demand 2>nul
sc config "TabletInputService" start= demand 2>nul
sc config "TapiSrv" start= demand 2>nul
sc config "TieringEngineService" start= demand 2>nul
sc config "TimeBroker" start= demand 2>nul
sc config "TimeBrokerSvc" start= demand 2>nul
sc config "TokenBroker" start= demand 2>nul
sc config "TroubleshootingSvc" start= demand 2>nul
sc config "TrustedInstaller" start= demand 2>nul
sc config "UI0Detect" start= demand 2>nul
sc config "UdkUserSvc_*" start= demand 2>nul
sc config "UmRdpService" start= demand 2>nul
sc config "UnistoreSvc_*" start= demand 2>nul
sc config "UserDataSvc_*" start= demand 2>nul
sc config "VSS" start= demand 2>nul
sc config "VacSvc" start= demand 2>nul
sc config "W32Time" start= demand 2>nul
sc config "WEPHOSTSVC" start= demand 2>nul
sc config "WFDSConMgrSvc" start= demand 2>nul
sc config "WMPNetworkSvc" start= demand 2>nul
sc config "WManSvc" start= demand 2>nul
sc config "WPDBusEnum" start= demand 2>nul
sc config "WSService" start= demand 2>nul
sc config "WaaSMedicSvc" start= demand 2>nul
sc config "WalletService" start= demand 2>nul
sc config "WarpJITSvc" start= demand 2>nul
sc config "WbioSrvc" start= demand 2>nul
sc config "WcsPlugInService" start= demand 2>nul
sc config "WdNisSvc" start= demand 2>nul
sc config "WdiServiceHost" start= demand 2>nul
sc config "WdiSystemHost" start= demand 2>nul
sc config "WebClient" start= demand 2>nul
sc config "Wecsvc" start= demand 2>nul
sc config "WerSvc" start= demand 2>nul
sc config "WiaRpc" start= demand 2>nul
sc config "WinHttpAutoProxySvc" start= demand 2>nul
sc config "WinRM" start= demand 2>nul
sc config "WpcMonSvc" start= demand 2>nul
sc config "XblAuthManager" start= demand 2>nul
sc config "XblGameSave" start= demand 2>nul
sc config "XboxGipSvc" start= demand 2>nul
sc config "XboxNetApiSvc" start= demand 2>nul
sc config "autotimesvc" start= demand 2>nul
sc config "bthserv" start= demand 2>nul
sc config "camsvc" start= demand 2>nul
sc config "cloudidsvc" start= demand 2>nul
sc config "dcsvc" start= demand 2>nul
sc config "defragsvc" start= demand 2>nul
sc config "diagnosticshub.standardcollector.service" start= demand 2>nul
sc config "diagsvc" start= demand 2>nul
sc config "dmwappushservice" start= demand 2>nul
sc config "dot3svc" start= demand 2>nul
sc config "edgeupdate" start= demand 2>nul
sc config "edgeupdatem" start= demand 2>nul
sc config "embeddedmode" start= demand 2>nul
sc config "fdPHost" start= demand 2>nul
sc config "fhsvc" start= demand 2>nul
sc config "hidserv" start= demand 2>nul
sc config "icssvc" start= demand 2>nul
sc config "lfsvc" start= demand 2>nul
sc config "lltdsvc" start= demand 2>nul
sc config "lmhosts" start= demand 2>nul
sc config "msiserver" start= demand 2>nul
sc config "netprofm" start= demand 2>nul
sc config "p2pimsvc" start= demand 2>nul
sc config "p2psvc" start= demand 2>nul
sc config "perceptionsimulation" start= demand 2>nul
sc config "pla" start= demand 2>nul
sc config "seclogon" start= demand 2>nul
sc config "smphost" start= demand 2>nul
sc config "spectrum" start= demand 2>nul
sc config "svsvc" start= demand 2>nul
sc config "swprv" start= demand 2>nul
sc config "upnphost" start= demand 2>nul
sc config "vds" start= demand 2>nul
sc config "vmicguestinterface" start= demand 2>nul
sc config "vmicheartbeat" start= demand 2>nul
sc config "vmickvpexchange" start= demand 2>nul
sc config "vmicrdv" start= demand 2>nul
sc config "vmicshutdown" start= demand 2>nul
sc config "vmictimesync" start= demand 2>nul
sc config "vmicvmsession" start= demand 2>nul
sc config "vmicvss" start= demand 2>nul
sc config "vmvss" start= demand 2>nul
sc config "wbengine" start= demand 2>nul
sc config "wcncsvc" start= demand 2>nul
sc config "webthreatdefsvc" start= demand 2>nul
sc config "wercplsupport" start= demand 2>nul
sc config "wisvc" start= demand 2>nul
sc config "wlidsvc" start= demand 2>nul
sc config "wlpasvc" start= demand 2>nul
sc config "wmiApSrv" start= demand 2>nul
sc config "workfolderssvc" start= demand 2>nul
sc config "wuauserv" start= demand 2>nul
sc config "wudfsvc" start= demand 2>nul

echo.
echo === Disabling Services ===
sc config "diagnosticshub.standardcollector.service" start= disabled 2>nul
sc config "DiagTrack" start= disabled 2>nul
sc config "DPS" start= disabled 2>nul
sc config "FontCache" start= disabled 2>nul
sc config "FontCache3.0.0.0" start= disabled 2>nul
sc config "SystemUsageReportSvc_QUEENCREEK" start= disabled 2>nul
sc config "GpuEnergyDrv" start= disabled 2>nul
sc config "ShellHWDetection" start= disabled 2>nul
sc config "SgrmAgent" start= disabled 2>nul
sc config "SgrmBroker" start= disabled 2>nul
sc config "uhssvc" start= disabled 2>nul
sc config "TrkWks" start= disabled 2>nul
sc config "WdiServiceHost" start= disabled 2>nul
sc config "WdiSystemHost" start= disabled 2>nul
sc config "WSearch" start= disabled 2>nul
sc config "diagsvc" start= disabled 2>nul

echo === Clearing DNS cache ===
echo.
ipconfig /flushdns 2>nul

echo.
echo === Select a Master Profile to Apply ===
echo *1.- Apply Workstation Master Profile (Recommended for Productivity)
echo *2.- Apply Gaming Master Profile
echo *3.- Apply Privacy Master Profile
echo *4.- Skip Profile Application
echo.
set /p profop=Option: 
if "%profop%"=="1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Applying Workstation Master Profile...'; & '%~dp0Profiles\Apply_Workstation_Master_Profile.ps1' -Force"
) else if "%profop%"=="2" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Applying Gaming Master Profile...'; & '%~dp0Profiles\Apply_Gaming_Master_Profile.ps1' -Force"
) else if "%profop%"=="3" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Applying Privacy Master Profile...'; & '%~dp0Profiles\Apply_Privacy_Master_Profile.ps1' -Force"
)

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
echo *3.- Delete Windows Defender (Irreversible)
echo *4.- Go Back.
echo.

:: Code to go to menu with Options
set /p oput=Option: 
if "%oput%"=="1" goto :DF
if "%oput%"=="2" goto :DE
if "%oput%"=="3" goto :DELDEF
if "%oput%"=="4" goto :Start
if "%oput%"=="" goto :Start



:DF
cls
echo.
echo --------------------------------------------------
echo        Disabling Windows Defender
echo --------------------------------------------------
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "ServiceStartStates" /t REG_DWORD /d 1 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d 0 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUA" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontReportInfectionInformation" /t REG_DWORD /d 1 /f 2>nul

reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControlEnabled" /t REG_DWORD /d 0 /f 2>nul

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotification" /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d 1 /f 2>nul

sc config WinDefend start= disabled 2>nul
sc config SecurityHealthService start= disabled 2>nul
sc config Sense start= disabled 2>nul
sc config WdNisDrv start= disabled 2>nul
sc config WdNisSvc start= disabled 2>nul

timeout /t 3 /nobreak
goto :Start



:DE
cls
echo.
echo --------------------------------------------------
echo            Enabling Windows Defender.
echo --------------------------------------------------
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "ServiceStartStates" /t REG_DWORD /d 0 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 0 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d 2 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUA" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontReportInfectionInformation" /t REG_DWORD /d 0 /f 2>nul

reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 1 /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControlEnabled" /f 2>nul

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d 0 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d 0 /f 2>nul
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotification" /t REG_DWORD /d 0 /f 2>nul
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d 0 /f 2>nul

sc config WinDefend start= auto 2>nul
sc config SecurityHealthService start= auto 2>nul
sc config Sense start= auto 2>nul
sc config WdNisDrv start= auto 2>nul
sc config WdNisSvc start= auto 2>nul

timeout /t 3 /nobreak
goto :start



:DELDEF
cls
echo.
echo --------------------------------------------------
echo      DELETING Windows Defender (Irreversible)
echo --------------------------------------------------
echo.
echo WARNING: This action is irreversible. Windows Defender will be completely removed.
echo Press CTRL+C to cancel, or press any key to continue...
pause >nul
echo.

:: Registry Tweaks (Disabling all features just in case)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "ServiceStartStates" /t REG_DWORD /d 1 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d 0 /f 2>nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUA" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontReportInfectionInformation" /t REG_DWORD /d 1 /f 2>nul

reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControlEnabled" /t REG_DWORD /d 0 /f 2>nul

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotification" /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d 1 /f 2>nul

:: Stop and Delete Services
sc stop WinDefend 2>nul
sc delete WinDefend 2>nul
sc stop SecurityHealthService 2>nul
sc delete SecurityHealthService 2>nul
sc stop Sense 2>nul
sc delete Sense 2>nul
sc stop WdNisDrv 2>nul
sc delete WdNisDrv 2>nul
sc stop WdNisSvc 2>nul
sc delete WdNisSvc 2>nul
sc stop wscsvc 2>nul
sc delete wscsvc 2>nul

:: Take Ownership and Delete Directories
takeown /f "%ProgramFiles%\Windows Defender" /r /d y 2>nul
icacls "%ProgramFiles%\Windows Defender" /grant administrators:F /t 2>nul
rd /s /q "%ProgramFiles%\Windows Defender" 2>nul

takeown /f "%ProgramFiles(x86)%\Windows Defender" /r /d y 2>nul
icacls "%ProgramFiles(x86)%\Windows Defender" /grant administrators:F /t 2>nul
rd /s /q "%ProgramFiles(x86)%\Windows Defender" 2>nul

takeown /f "%ProgramData%\Microsoft\Windows Defender" /r /d y 2>nul
icacls "%ProgramData%\Microsoft\Windows Defender" /grant administrators:F /t 2>nul
rd /s /q "%ProgramData%\Microsoft\Windows Defender" 2>nul

echo Windows Defender has been completely removed.
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
sc config "AJRouter" start= demand 2>nul
sc config "ALG" start= demand 2>nul
sc config "AppIDSvc" start= demand 2>nul
sc config "AppMgmt" start= demand 2>nul
sc config "AppReadiness" start= demand 2>nul
sc config "AppXSvc" start= demand 2>nul
sc config "Appinfo" start= demand 2>nul
sc config "AssignedAccessManagerSvc" start= demand 2>nul
sc config "AxInstSV" start= demand 2>nul
sc config "BDESVC" start= demand 2>nul
sc config "BTAGService" start= demand 2>nul
sc config "BcastDVRUserService_*" start= demand 2>nul
sc config "BluetoothUserService_*" start= demand 2>nul
sc config "Browser" start= demand 2>nul
sc config "CaptureService_*" start= demand 2>nul
sc config "CertPropSvc" start= demand 2>nul
sc config "ClipSVC" start= demand 2>nul
sc config "ConsentUxUserSvc_*" start= demand 2>nul
sc config "CredentialEnrollmentManagerUserSvc_*" start= demand 2>nul
sc config "CscService" start= demand 2>nul
sc config "DcpSvc" start= demand 2>nul
sc config "DevQueryBroker" start= demand 2>nul
sc config "DeviceAssociationBrokerSvc_*" start= demand 2>nul
sc config "DeviceAssociationService" start= demand 2>nul
sc config "DeviceInstall" start= demand 2>nul
sc config "DevicePickerUserSvc_*" start= demand 2>nul
sc config "DevicesFlowUserSvc_*" start= demand 2>nul
sc config "DisplayEnhancementService" start= demand 2>nul
sc config "DmEnrollmentSvc" start= demand 2>nul
sc config "DsSvc" start= demand 2>nul
sc config "DsmSvc" start= demand 2>nul
sc config "EFS" start= demand 2>nul
sc config "EapHost" start= demand 2>nul
sc config "EntAppSvc" start= demand 2>nul
sc config "FDResPub" start= demand 2>nul
sc config "Fax" start= demand 2>nul
sc config "FrameServer" start= demand 2>nul
sc config "FrameServerMonitor" start= demand 2>nul
sc config "GraphicsPerfSvc" start= demand 2>nul
sc config "HomeGroupListener" start= demand 2>nul
sc config "HomeGroupProvider" start= demand 2>nul
sc config "HvHost" start= demand 2>nul
sc config "IEEtwCollectorService" start= demand 2>nul
sc config "IKEEXT" start= demand 2>nul
sc config "InstallService" start= demand 2>nul
sc config "InventorySvc" start= demand 2>nul
sc config "IpxlatCfgSvc" start= demand 2>nul
sc config "KtmRm" start= demand 2>nul
sc config "LicenseManager" start= demand 2>nul
sc config "LxpSvc" start= demand 2>nul
sc config "MSDTC" start= demand 2>nul
sc config "MSiSCSI" start= demand 2>nul
sc config "McpManagementService" start= demand 2>nul
sc config "MessagingService_*" start= demand 2>nul
sc config "MicrosoftEdgeElevationService" start= demand 2>nul
sc config "MixedRealityOpenXRSvc" start= demand 2>nul
sc config "NPSMSvc_*" start= demand 2>nul
sc config "NaturalAuthentication" start= demand 2>nul
sc config "NcaSvc" start= demand 2>nul
sc config "NcbService" start= demand 2>nul
sc config "NcdAutoSetup" start= demand 2>nul
sc config "NetSetupSvc" start= demand 2>nul
sc config "Netman" start= demand 2>nul
sc config "NgcCtnrSvc" start= demand 2>nul
sc config "NgcSvc" start= demand 2>nul
sc config "NlaSvc" start= demand 2>nul
sc config "P9RdrService_*" start= demand 2>nul
sc config "PNRPAutoReg" start= demand 2>nul
sc config "PNRPsvc" start= demand 2>nul
sc config "PeerDistSvc" start= demand 2>nul
sc config "PenService_*" start= demand 2>nul
sc config "PerfHost" start= demand 2>nul
sc config "PhoneSvc" start= demand 2>nul
sc config "PimIndexMaintenanceSvc_*" start= demand 2>nul
sc config "PlugPlay" start= demand 2>nul
sc config "PolicyAgent" start= demand 2>nul
sc config "PrintNotify" start= demand 2>nul
sc config "PrintWorkflowUserSvc_*" start= demand 2>nul
sc config "PushToInstall" start= demand 2>nul
sc config "QWAVE" start= demand 2>nul
sc config "RasAuto" start= demand 2>nul
sc config "RasMan" start= demand 2>nul
sc config "RetailDemo" start= demand 2>nul
sc config "RmSvc" start= demand 2>nul
sc config "RpcLocator" start= demand 2>nul
sc config "SCPolicySvc" start= demand 2>nul
sc config "SCardSvr" start= demand 2>nul
sc config "SDRSVC" start= demand 2>nul
sc config "SEMgrSvc" start= demand 2>nul
sc config "SNMPTRAP" start= demand 2>nul
sc config "SNMPTrap" start= demand 2>nul
sc config "SSDPSRV" start= demand 2>nul
sc config "ScDeviceEnum" start= demand 2>nul
sc config "SecurityHealthService" start= demand 2>nul
sc config "Sense" start= demand 2>nul
sc config "SensorDataService" start= demand 2>nul
sc config "SensorService" start= demand 2>nul
sc config "SensrSvc" start= demand 2>nul
sc config "SessionEnv" start= demand 2>nul
sc config "SharedAccess" start= demand 2>nul
sc config "SharedRealitySvc" start= demand 2>nul
sc config "SmsRouter" start= demand 2>nul
sc config "SstpSvc" start= demand 2>nul
sc config "StiSvc" start= demand 2>nul
sc config "TabletInputService" start= demand 2>nul
sc config "TapiSrv" start= demand 2>nul
sc config "TieringEngineService" start= demand 2>nul
sc config "TimeBroker" start= demand 2>nul
sc config "TimeBrokerSvc" start= demand 2>nul
sc config "TokenBroker" start= demand 2>nul
sc config "TroubleshootingSvc" start= demand 2>nul
sc config "TrustedInstaller" start= demand 2>nul
sc config "UI0Detect" start= demand 2>nul
sc config "UdkUserSvc_*" start= demand 2>nul
sc config "UmRdpService" start= demand 2>nul
sc config "UnistoreSvc_*" start= demand 2>nul
sc config "UserDataSvc_*" start= demand 2>nul
sc config "VSS" start= demand 2>nul
sc config "VacSvc" start= demand 2>nul
sc config "W32Time" start= demand 2>nul
sc config "WEPHOSTSVC" start= demand 2>nul
sc config "WFDSConMgrSvc" start= demand 2>nul
sc config "WMPNetworkSvc" start= demand 2>nul
sc config "WManSvc" start= demand 2>nul
sc config "WPDBusEnum" start= demand 2>nul
sc config "WSService" start= demand 2>nul
sc config "WaaSMedicSvc" start= demand 2>nul
sc config "WalletService" start= demand 2>nul
sc config "WarpJITSvc" start= demand 2>nul
sc config "WbioSrvc" start= demand 2>nul
sc config "WcsPlugInService" start= demand 2>nul
sc config "WdNisSvc" start= demand 2>nul
sc config "WdiServiceHost" start= demand 2>nul
sc config "WdiSystemHost" start= demand 2>nul
sc config "WebClient" start= demand 2>nul
sc config "Wecsvc" start= demand 2>nul
sc config "WerSvc" start= demand 2>nul
sc config "WiaRpc" start= demand 2>nul
sc config "WinHttpAutoProxySvc" start= demand 2>nul
sc config "WinRM" start= demand 2>nul
sc config "WpcMonSvc" start= demand 2>nul
sc config "XblAuthManager" start= demand 2>nul
sc config "XblGameSave" start= demand 2>nul
sc config "XboxGipSvc" start= demand 2>nul
sc config "XboxNetApiSvc" start= demand 2>nul
sc config "autotimesvc" start= demand 2>nul
sc config "bthserv" start= demand 2>nul
sc config "camsvc" start= demand 2>nul
sc config "cloudidsvc" start= demand 2>nul
sc config "dcsvc" start= demand 2>nul
sc config "defragsvc" start= demand 2>nul
sc config "diagnosticshub.standardcollector.service" start= demand 2>nul
sc config "diagsvc" start= demand 2>nul
sc config "dmwappushservice" start= demand 2>nul
sc config "dot3svc" start= demand 2>nul
sc config "edgeupdate" start= demand 2>nul
sc config "edgeupdatem" start= demand 2>nul
sc config "embeddedmode" start= demand 2>nul
sc config "fdPHost" start= demand 2>nul
sc config "fhsvc" start= demand 2>nul
sc config "hidserv" start= demand 2>nul
sc config "icssvc" start= demand 2>nul
sc config "lfsvc" start= demand 2>nul
sc config "lltdsvc" start= demand 2>nul
sc config "lmhosts" start= demand 2>nul
sc config "msiserver" start= demand 2>nul
sc config "netprofm" start= demand 2>nul
sc config "p2pimsvc" start= demand 2>nul
sc config "p2psvc" start= demand 2>nul
sc config "perceptionsimulation" start= demand 2>nul
sc config "pla" start= demand 2>nul
sc config "seclogon" start= demand 2>nul
sc config "smphost" start= demand 2>nul
sc config "spectrum" start= demand 2>nul
sc config "svsvc" start= demand 2>nul
sc config "swprv" start= demand 2>nul
sc config "upnphost" start= demand 2>nul
sc config "vds" start= demand 2>nul
sc config "vmicguestinterface" start= demand 2>nul
sc config "vmicheartbeat" start= demand 2>nul
sc config "vmickvpexchange" start= demand 2>nul
sc config "vmicrdv" start= demand 2>nul
sc config "vmicshutdown" start= demand 2>nul
sc config "vmictimesync" start= demand 2>nul
sc config "vmicvmsession" start= demand 2>nul
sc config "vmicvss" start= demand 2>nul
sc config "vmvss" start= demand 2>nul
sc config "wbengine" start= demand 2>nul
sc config "wcncsvc" start= demand 2>nul
sc config "webthreatdefsvc" start= demand 2>nul
sc config "wercplsupport" start= demand 2>nul
sc config "wisvc" start= demand 2>nul
sc config "wlidsvc" start= demand 2>nul
sc config "wlpasvc" start= demand 2>nul
sc config "wmiApSrv" start= demand 2>nul
sc config "workfolderssvc" start= demand 2>nul
sc config "wuauserv" start= demand 2>nul
sc config "wudfsvc" start= demand 2>nul

timeout /t 3 /nobreak
goto :done

:disablefullscreenoptimizations
cls

echo.
echo Disabling Fullscreen Optimizations...

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 1 /f 2>nul

timeout /t 3 /nobreak
goto :done

:disabletelemetry
cls

echo.
echo Disabling Telemetry Registry...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f 2>nul
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f 2>nul

timeout /t 3 /nobreak
goto :done

:disableservices
cls

echo.
echo === Disabling Services ===
sc config "DiagTrack" start= disabled 2>nul
sc config "DPS" start= disabled 2>nul
sc config "FontCache" start= disabled 2>nul
sc config "FontCache3.0.0.0" start= disabled 2>nul
sc config "SystemUsageReportSvc_QUEENCREEK" start= disabled 2>nul
sc config "GpuEnergyDrv" start= disabled 2>nul
sc config "ShellHWDetection" start= disabled 2>nul
sc config "SgrmAgent" start= disabled 2>nul
sc config "SgrmBroker" start= disabled 2>nul
sc config "uhssvc" start= disabled 2>nul
sc config "WdiServiceHost" start= disabled 2>nul
sc config "WdiSystemHost" start= disabled 2>nul
sc config "WSearch" start= disabled 2>nul
sc config "diagsvc" start= disabled 2>nul

timeout /t 3 /nobreak
goto :done

:disablebackgroundapps
cls

echo Disabling background applications
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v GlobalUserDisabled /t REG_DWORD /d 1 /f 2>nul

timeout /t 3 /nobreak
goto :done

:reducewindows
cls

echo.
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 200 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v KeyboardDelay /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v ListviewShadow /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v TaskbarAnimations /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v VisualFXSetting /t REG_DWORD /d 3 /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v EnableAeroPeek /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /v TaskbarMn /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /v TaskbarDa /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f 2>nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f 2>nul

timeout /t 3 /nobreak
goto :done


:highprioritygame
cls

echo.
echo Setting high priority for games...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csgo.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\cs2.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FortniteClient-Win64-Shipping.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\gta_3.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\gta_vc.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\gta_sa.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GTAIV.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GTA5.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\java.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\javaw.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\minecraft.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Minecraft.Windows.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\obs32.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\obs64.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\PPSSPP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ShellExperienceHost.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 5 /f 2>nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\svchost.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 5 /f 2>nul
goto :done

:svchostprocess
cls

echo Reducing svchost processes...
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set MEM=%%i
set /a RAM=%MEM% + 1024000
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%RAM%" /f 2>nul

timeout /t 3 /nobreak
goto :done

:disablegamedvr
cls

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 1 /f 2>nul

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
sc config %%i start= disabled 2>nul
	sc failure %%i reset= 0 actions= ""
)

:: Brute force rename services
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i.dll && icacls C:\Windows\System32\%%i.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i.dll %%i_BAK.dll
	icacls C:\Windows\System32\%%i_BAK.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i_BAK.dll /remove *S-1-1-0
)

:: Update registry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 000000000000000000000000030000001400000000000000c0d4010000000000e09304000000000000000000 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f 2>nul

:: Delete downloaded update files
erase /f /s /q c:\windows\softwaredistribution\*.* && rmdir /s /q c:\windows\softwaredistribution

:: Disable all update related scheduled tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\*" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\*" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\UpdateAssistant\*" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\*" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\*" /disable 2>nul
schtasks /change /tn "\Microsoft\WindowsUpdate\*" /disable 2>nul

:: Go Back
timeout /t 3 /nobreak
goto :update  

:WD
cls
:: Enable update related services
sc config wuauserv start= auto 2>nul
sc config UsoSvc start= auto 2>nul
sc config uhssvc start= delayed-auto 2>nul

:: Restore renamed services
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i_BAK.dll && icacls C:\Windows\System32\%%i_BAK.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i_BAK.dll %%i.dll
	icacls C:\Windows\System32\%%i.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i.dll /remove *S-1-1-0
)

:: Update registry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 840300000000000000000000030000001400000001000000c0d4010001000000e09304000000000000000000 /f 2>nul
reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f

:: Enable all update related scheduled tasks
schtasks /change /tn "\Microsoft\Windows\InstallService\*" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\*" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\UpdateAssistant\*" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\WaaSMedic\*" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\*" /enable 2>nul
schtasks /change /tn "\Microsoft\WindowsUpdate\*" /enable 2>nul

:: Go Back
timeout /t 3 /nobreak
goto :update

:modulartweaks
cls
echo --------------------------------------------------
echo             Explore Modular Tweaks
echo --------------------------------------------------
echo.
echo *1.- Performance ^& Gaming (Boot, Gaming, GPU, Power)
echo *2.- Privacy ^& Security (Privacy, Security)
echo *3.- System ^& Services (Services, System, Tasks, Troubleshooting, Apps)
echo *4.- Network ^& Internet (Network, Network-Diagnostics, Browser)
echo *5.- UI ^& Explorer (Appearance, Explorer, Visual)
echo *6.- Storage ^& Cleanup (Storage, Storage-Advanced, Storage-Aggressive)
echo *7.- Go Back
echo.
set /p mtwk=Option: 
if "%mtwk%"=="1" set "CATS=Boot Gaming GPU Power" & goto :modulartweaks_action
if "%mtwk%"=="2" set "CATS=Privacy Security" & goto :modulartweaks_action
if "%mtwk%"=="3" set "CATS=Services System Tasks Troubleshooting Apps" & goto :modulartweaks_action
if "%mtwk%"=="4" set "CATS=Network Network-Diagnostics Browser" & goto :modulartweaks_action
if "%mtwk%"=="5" set "CATS=Appearance Explorer Visual" & goto :modulartweaks_action
if "%mtwk%"=="6" set "CATS=Storage Storage-Advanced Storage-Aggressive" & goto :modulartweaks_action
if "%mtwk%"=="7" goto :start
goto :modulartweaks

:modulartweaks_action
cls
echo --------------------------------------------------
echo             Select Action
echo --------------------------------------------------
echo.
echo *1.- Apply Tweaks (Disable / Optimize)
echo *2.- Restore Tweaks (Enable / Revert)
echo *3.- Go Back
echo.
set /p mact=Option: 
if "%mact%"=="1" set "ACTION=Apply" & goto :modulartweaks_list
if "%mact%"=="2" set "ACTION=Restore" & goto :modulartweaks_list
if "%mact%"=="3" goto :modulartweaks
goto :modulartweaks_action

:modulartweaks_list
cls
echo --------------------------------------------------
echo             Available Tweaks (%ACTION%)
echo --------------------------------------------------
echo.

setlocal enabledelayedexpansion
set "idx=1"
set "file!idx!=Go Back"
echo *!idx!.- Go Back
set /a idx+=1

for %%C in (%CATS%) do (
    if exist "%~dp0%%C" (
        for %%F in ("%~dp0%%C\*.*") do (
            set "skip=0"
            set "filename=%%~nxF"
            
            if "%ACTION%"=="Apply" (
                echo !filename! ^| findstr /i /c:"Restore" /c:"Enable" >nul
                if not errorlevel 1 set "skip=1"
            ) else (
                echo !filename! ^| findstr /i /c:"Restore" /c:"Enable" >nul
                if errorlevel 1 set "skip=1"
            )
            
            if "!skip!"=="0" (
                echo *!idx!.- [%%C] !filename!
                set "file!idx!=%%F"
                set /a idx+=1
            )
        )
    )
)
echo.
set /p sel=Select tweak to run (1-!idx!): 

if "!sel!"=="" endlocal & goto :modulartweaks_list
if "!sel!"=="1" endlocal & goto :modulartweaks_action

set "chosen=!file%sel%!"
if "!chosen!"=="" (
    echo Invalid selection.
    timeout /t 2 /nobreak
    endlocal
    goto :modulartweaks_list
)

echo.
echo Executing: "!chosen!"
set "ext=!chosen:~-4!"
if /i "!ext!"==".reg" (
    reg import "!chosen!"
) else if /i "!ext!"==".ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!chosen!"
) else if /i "!ext!"==".bat" (
    call "!chosen!"
) else if /i "!ext!"==".cmd" (
    call "!chosen!"
) else (
    echo Unsupported file type.
)
echo.
echo Done.
endlocal
goto :modulartweaks_action

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

