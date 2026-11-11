import json
import os

DATASET = [
    # =========================================================================
    # 1. TELEMETRY, DIAGNOSTICS & TRACE SERVICES (TIER 1 - SAFE)
    # =========================================================================
    {"name": "DiagTrack", "type": "service", "desc": "Connected User Experiences and Telemetry", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "dmwappushservice", "type": "service", "desc": "WAP Push Message Routing Service for enterprise and device telemetry", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "diagnosticshub.standardcollector.service", "type": "service", "desc": "Microsoft Diagnostics Hub Standard Collector ETW tracing", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "WerSvc", "type": "service", "desc": "Windows Error Reporting Service automated crash dump upload", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "wercplsupport", "type": "service", "desc": "Problem Reports and Solutions Control Panel Support", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "PcaSvc", "type": "service", "desc": "Program Compatibility Assistant monitoring and shim injection", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "WdiServiceHost", "type": "service", "desc": "Diagnostic Service Host", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "WdiSystemHost", "type": "service", "desc": "Diagnostic System Host", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "DPS", "type": "service", "desc": "Diagnostic Policy Service problem detection", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "diagsvc", "type": "service", "desc": "Diagnostic Execution Service", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "autotimesvc", "type": "service", "desc": "Cellular Time Synchronization Service", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 2, "is_safe": True},
    {"name": "InventorySvc", "type": "service", "desc": "System inventory and telemetry scanner", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "cloudidsvc", "type": "service", "desc": "Microsoft Cloud Identity and telemetry service", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},
    {"name": "CompatTelRunner.exe", "type": "process", "desc": "Microsoft Compatibility Telemetry Runner background scanner", "vendor": "Microsoft", "category": "Telemetry_Tracking", "risk_tier": 1, "is_safe": True},

    # =========================================================================
    # 2. CONSUMER, KIOSK & LEGACY SERVICES (TIER 1 & 2 - SAFE / RECOMMENDED)
    # =========================================================================
    {"name": "RetailDemo", "type": "service", "desc": "Retail Demo Service for store display PCs", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "MapsBroker", "type": "service", "desc": "Downloaded Maps Manager offline map sync", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "lfsvc", "type": "service", "desc": "Geolocation Service location tracking", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Fax", "type": "service", "desc": "Legacy Fax Service dial-up fax transmission", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "RemoteRegistry", "type": "service", "desc": "Remote Registry network modification service", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "RemoteAccess", "type": "service", "desc": "Routing and Remote Access legacy NAT server", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "SharedAccess", "type": "service", "desc": "Internet Connection Sharing (ICS)", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "PhoneSvc", "type": "service", "desc": "Phone Service telephony integration", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "SmsRouter", "type": "service", "desc": "Microsoft Windows SMS Router cellular routing", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "SEMgrSvc", "type": "service", "desc": "Payments and NFC/SE Manager", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "WalletService", "type": "service", "desc": "Microsoft Pay and Wallet background host", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "PushToInstall", "type": "service", "desc": "Windows PushToInstall Service for remote app pushes", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "wisvc", "type": "service", "desc": "Windows Insider Service preview build validator", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "WpcMonSvc", "type": "service", "desc": "Parental Controls activity logger and blocker", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AJRouter", "type": "service", "desc": "AllJoyn Router Service IoT routing", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "WMPNetworkSvc", "type": "service", "desc": "Windows Media Player Network Sharing UPnP DLNA", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "PeerDistSvc", "type": "service", "desc": "BranchCache enterprise local intranet cache", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "CscService", "type": "service", "desc": "Offline Files network caching client", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "RpcLocator", "type": "service", "desc": "Remote Procedure Call (RPC) Locator legacy database", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "TrkWks", "type": "service", "desc": "Distributed Link Tracking Client NTFS network link tracker", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "shpamsvc", "type": "service", "desc": "Shared PC Account Manager kiosk account cleaner", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "UevAgentService", "type": "service", "desc": "User Experience Virtualization Service roaming profile manager", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AppVClient", "type": "service", "desc": "Microsoft App-V Client virtualization engine", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "SessionEnv", "type": "service", "desc": "Remote Desktop Configuration", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "TermService", "type": "service", "desc": "Remote Desktop Services daemon", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "UmRdpService", "type": "service", "desc": "User Profile Service for Remote Desktop", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "SensorDataService", "type": "service", "desc": "Sensor Data Service accelerometer orientation", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "SensrSvc", "type": "service", "desc": "Sensor Monitoring Service ambient light auto-rotation", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "SensorService", "type": "service", "desc": "Unified Windows Sensor broker", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "TabletInputService", "type": "service", "desc": "Touch Keyboard and Handwriting Panel", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "WFDSConSvc", "type": "service", "desc": "Wi-Fi Direct Services Connection Manager Miracast", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "WwanSvc", "type": "service", "desc": "WWAN AutoConfig cellular SIM broadband manager", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DusmSvc", "type": "service", "desc": "Data Usage Monitoring Service cellular bandwidth meter", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "icssvc", "type": "service", "desc": "Windows Mobile Hotspot Service", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "XblAuthManager", "type": "service", "desc": "Xbox Live Auth Manager gamertag authentication", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "XblGameSave", "type": "service", "desc": "Xbox Live Game Save Service cloud sync", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "XboxNetApiSvc", "type": "service", "desc": "Xbox Live Networking Service Teredo multiplayer tunnel", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "XboxGipSvc", "type": "service", "desc": "Xbox Accessory Management Service wireless controller firmware", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "DoSvc", "type": "service", "desc": "Delivery Optimization P2P upload and bandwidth seeder", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},

    # Per-User Synchronization Daemons
    {"name": "CDPUserSvc", "type": "service", "desc": "Connected Devices Platform User Service cross-device sync", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "OneSyncSvc", "type": "service", "desc": "Sync Host contacts and calendar background synchronizer", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "UserDataSvc", "type": "service", "desc": "User Data Access Service storage synchronization", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "UnistoreSvc", "type": "service", "desc": "User Data Storage Service email contact store", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "PimIndexMaintenanceSvc", "type": "service", "desc": "Contact Data Indexing Service", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "MessagingService", "type": "service", "desc": "Messaging Service SMS and text synchronization", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "WpnUserService", "type": "service", "desc": "Windows Push Notifications User Service background push host", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DevicePickerUserSvc", "type": "service", "desc": "Device Picker User Service Miracast casting", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DevicesFlowUserSvc", "type": "service", "desc": "Devices Flow User Service hardware accessory wizard", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "CloudBackupRestoreSvc", "type": "service", "desc": "Cloud Backup and Restore User Service OneDrive syncing", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},

    # =========================================================================
    # 3. OEM BLOATWARE SERVICES (TIER 1 - SAFE TO PURGE)
    # =========================================================================
    # Dell
    {"name": "DellClientManagementService", "type": "service", "desc": "Dell hardware telemetry and remote inventory agent", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DellDataVault", "type": "service", "desc": "Dell Data Vault continuous hardware health telemetry logger", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DellDataVaultCollector", "type": "service", "desc": "Dell Data Vault crash and diagnostic dump aggregator", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DellDataVaultProcessor", "type": "service", "desc": "Dell Data Vault sensor and metrics processor", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DellHardwareSupport", "type": "service", "desc": "Dell SupportAssist hardware background scanner", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DellSupportAssistAgent", "type": "service", "desc": "Dell SupportAssist automated diagnostics and updater agent", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DellUpdate", "type": "service", "desc": "Dell Update Service periodic background poller", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DDVDataCollector", "type": "service", "desc": "Dell Data Vault Data Collector background logger", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Dell TechHub", "type": "service", "desc": "Dell TechHub diagnostics and telemetry background server", "vendor": "Dell", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # HP
    {"name": "HPAppHelperCap", "type": "service", "desc": "HP App Helper HSA Service companion app bridge", "vendor": "HP", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "HPCommRecovery", "type": "service", "desc": "HP Network HSA Service telemetry monitor", "vendor": "HP", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "HPDiagsCap", "type": "service", "desc": "HP Diagnostics HSA Service automated hardware testing", "vendor": "HP", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "HPSysInfoCap", "type": "service", "desc": "HP System Info HSA Service identifier collector", "vendor": "HP", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "HPTouchpointAnalyticsService", "type": "service", "desc": "HP Touchpoint Analytics Client daily metrics telemetry", "vendor": "HP", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "CaslData", "type": "service", "desc": "HP CASL Framework Service legacy companion software", "vendor": "HP", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # Lenovo
    {"name": "LenovoVantageService", "type": "service", "desc": "Lenovo Vantage Service background telemetry and updates", "vendor": "Lenovo", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "ImControllerService", "type": "service", "desc": "Lenovo System Interface Foundation Service background daemon", "vendor": "Lenovo", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "LenovoTransition", "type": "service", "desc": "Lenovo Transition screen auto-rotate detector", "vendor": "Lenovo", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "LenovoBrowserGuard", "type": "service", "desc": "Lenovo Browser Guard search protection add-on", "vendor": "Lenovo", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "LenovoHotkeys", "type": "service", "desc": "Lenovo Hotkeys OSD overlay monitor", "vendor": "Lenovo", "category": "OEM_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "LenovoSystemUpdateFoundations", "type": "service", "desc": "Lenovo System Update background poller", "vendor": "Lenovo", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # ASUS
    {"name": "ArmouryCrateControlInterface", "type": "service", "desc": "ASUS Armoury Crate RGB hardware and fan daemon", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "ArmouryCrateService", "type": "service", "desc": "ASUS Armoury Crate User Session Helper telemetry", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AsusAppService", "type": "service", "desc": "ASUS App Service communication layer for MyASUS", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AsusLinkNear", "type": "service", "desc": "ASUS Link Near proximity Wi-Fi and Bluetooth scanner", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AsusLinkRemote", "type": "service", "desc": "ASUS Link Remote mobile pairing connection client", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "ASUSOptimization", "type": "service", "desc": "ASUS Optimization Service power fan profile switcher", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "ASUSSoftwareManager", "type": "service", "desc": "ASUS Software Manager promotional updater", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "ASUSSystemAnalysis", "type": "service", "desc": "ASUS System Analysis hardware diagnostic telemetry", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "ASUSSystemDiagnosis", "type": "service", "desc": "ASUS System Diagnosis detailed crash log collector", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "LightingService", "type": "service", "desc": "Aura Lighting Service Asus RGB controller driver", "vendor": "ASUS", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # Razer
    {"name": "Razer Synapse Service", "type": "service", "desc": "Razer Synapse peripheral configuration and telemetry", "vendor": "Razer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Razer Central Service", "type": "service", "desc": "Razer Central Service promotional launcher and telemetry", "vendor": "Razer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Razer Game Manager", "type": "service", "desc": "Razer Game Manager background process game scanner", "vendor": "Razer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Razer Chroma Stream Server", "type": "service", "desc": "Razer Chroma Stream Server lighting broadcaster", "vendor": "Razer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Razer Update Service", "type": "service", "desc": "Razer Update Service background updater", "vendor": "Razer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # Acer
    {"name": "AcerCareCenterService", "type": "service", "desc": "Acer Care Center automated hardware diagnostics and updater", "vendor": "Acer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AcerConfigurationService", "type": "service", "desc": "Acer Configuration Service background settings synchronizer", "vendor": "Acer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AcerQuickAccessConsole", "type": "service", "desc": "Acer Quick Access Service hotkey overlay daemon", "vendor": "Acer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AcerLightingService", "type": "service", "desc": "Acer Predator RGB lighting controller", "vendor": "Acer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AcerSysHardwareService", "type": "service", "desc": "Acer System Hardware monitor telemetry agent", "vendor": "Acer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "AcerHardwareService", "type": "service", "desc": "Acer Hardware Service diagnostic broker", "vendor": "Acer", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # Intel
    {"name": "ESRV_SVC_WILLAMETTE", "type": "service", "desc": "Intel(R) SUR System Usage Report hardware telemetry", "vendor": "Intel", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "USER_ESRV_SVC_WILLAMETTE", "type": "service", "desc": "Intel(R) SUR User Session telemetry collector agent", "vendor": "Intel", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "IntelAudioService", "type": "service", "desc": "Intel Audio Service audio telemetry and smart sound assistant", "vendor": "Intel", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "LMS", "type": "service", "desc": "Intel(R) Management and Security Application Local Management Service", "vendor": "Intel", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Intel(R) Capability Licensing Service TCP IP Interface", "type": "service", "desc": "Intel capability licensing background listener", "vendor": "Intel", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Intel(R) Content Protection HECI Service", "type": "service", "desc": "Intel content protection DRM background daemon", "vendor": "Intel", "category": "OEM_Bloatware", "risk_tier": 1, "is_safe": True},

    # =========================================================================
    # 4. THIRD-PARTY AUTO-UPDATERS (TIER 1 - SAFE TO DISABLE)
    # =========================================================================
    {"name": "AdobeARMservice", "type": "service", "desc": "Adobe Acrobat Update Service", "vendor": "Adobe", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "AdobeUpdateService", "type": "service", "desc": "Adobe Creative Cloud background updater", "vendor": "Adobe", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "AGSService", "type": "service", "desc": "Adobe Genuine Software Integrity Service telemetry", "vendor": "Adobe", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "gupdate", "type": "service", "desc": "Google Update Service (gupdate)", "vendor": "Google", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "gupdatem", "type": "service", "desc": "Google Update Service (gupdatem)", "vendor": "Google", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "GoogleUpdaterService", "type": "service", "desc": "Google Chrome modern background updater", "vendor": "Google", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "GoogleUpdaterInternalService", "type": "service", "desc": "Google Chrome internal maintenance updater", "vendor": "Google", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "edgeupdate", "type": "service", "desc": "Microsoft Edge Update Service (edgeupdate)", "vendor": "Microsoft", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "edgeupdatem", "type": "service", "desc": "Microsoft Edge Update Service (edgeupdatem)", "vendor": "Microsoft", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "MozillaMaintenance", "type": "service", "desc": "Mozilla Maintenance Service Firefox background updater", "vendor": "Mozilla", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "OperaCrashReporter", "type": "service", "desc": "Opera Browser crash dump reporting agent", "vendor": "Opera", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},
    {"name": "CCleanerUpdate", "type": "service", "desc": "CCleaner Emergency Update telemetry agent", "vendor": "Piriform", "category": "ThirdParty_Updater", "risk_tier": 1, "is_safe": True},

    # =========================================================================
    # 5. SPONSORED & BLOATWARE UWP / APPX PACKAGES (TIER 1 - SAFE TO REMOVE)
    # =========================================================================
    {"name": "TikTok", "type": "appx", "desc": "TikTok sponsored social media video app", "vendor": "Bytedance", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Facebook", "type": "appx", "desc": "Facebook sponsored social app", "vendor": "Meta", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Instagram", "type": "appx", "desc": "Instagram sponsored social media app", "vendor": "Meta", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "WhatsApp", "type": "appx", "desc": "WhatsApp Desktop preinstalled client", "vendor": "Meta", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "SpotifyAB.SpotifyMusic", "type": "appx", "desc": "Spotify Music streaming client preload", "vendor": "Spotify", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "DisneyMagicKingdoms", "type": "appx", "desc": "Disney Magic Kingdoms sponsored game", "vendor": "Gameloft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Disney.37853FC22B2CE", "type": "appx", "desc": "Disney+ streaming media preload", "vendor": "Disney", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "King.com.CandyCrushSaga", "type": "appx", "desc": "Candy Crush Saga sponsored game", "vendor": "King", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "King.com.CandyCrushSodaSaga", "type": "appx", "desc": "Candy Crush Soda Saga sponsored game", "vendor": "King", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "King.com.CandyCrushFriends", "type": "appx", "desc": "Candy Crush Friends sponsored game", "vendor": "King", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Amazon.AmazonVideo", "type": "appx", "desc": "Amazon Prime Video streaming app", "vendor": "Amazon", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Amazon.AmazonPrime", "type": "appx", "desc": "Amazon Prime delivery shopping preload", "vendor": "Amazon", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Clipchamp.Clipchamp", "type": "appx", "desc": "Clipchamp freemium video editor preload", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Fitbit.FitbitCoach", "type": "appx", "desc": "Fitbit Coach fitness sponsored app", "vendor": "Fitbit", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "LinkedIn", "type": "appx", "desc": "LinkedIn social network preload", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Netflix", "type": "appx", "desc": "Netflix streaming client preload", "vendor": "Netflix", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "HiddenCityMysteryofShadows", "type": "appx", "desc": "Hidden City sponsored game", "vendor": "G5", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "MarchofEmpires", "type": "appx", "desc": "March of Empires sponsored game", "vendor": "Gameloft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "RoyalRevolt", "type": "appx", "desc": "Royal Revolt sponsored strategy game", "vendor": "Flaregames", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},

    # Microsoft Non-Essential UWP Bloat
    {"name": "Microsoft.BingWeather", "type": "appx", "desc": "Bing Weather consumer forecast app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.BingNews", "type": "appx", "desc": "Bing News consumer MSN news feed", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.BingFinance", "type": "appx", "desc": "Bing Finance MSN stock market tracker", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.BingSports", "type": "appx", "desc": "Bing Sports consumer sports tracker", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.MicrosoftSolitaireCollection", "type": "appx", "desc": "Solitaire card game collection with in-app advertising", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.GetHelp", "type": "appx", "desc": "Get Help interactive assistant support app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.Getstarted", "type": "appx", "desc": "Tips and Getting Started promotional app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.MicrosoftOfficeHub", "type": "appx", "desc": "Office 365 promotional hub", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.People", "type": "appx", "desc": "People contact synchronizer app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.Todos", "type": "appx", "desc": "Microsoft To-Do task manager preload", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.WindowsFeedbackHub", "type": "appx", "desc": "Feedback Hub telemetry reporting tool", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.WindowsMaps", "type": "appx", "desc": "Windows Maps offline maps client", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.YourPhone", "type": "appx", "desc": "Phone Link phone synchronization app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Microsoft.ZuneMusic", "type": "appx", "desc": "Groove Music media player preload", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.ZuneVideo", "type": "appx", "desc": "Films and TV video player preload", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.SkypeApp", "type": "appx", "desc": "Skype modern communications client", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.MixedReality.Portal", "type": "appx", "desc": "Windows Mixed Reality portal", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.549981C3F5F10", "type": "appx", "desc": "Cortana voice assistant app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft.WindowsCommunicationsApps", "type": "appx", "desc": "Legacy Windows Mail and Calendar apps", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Microsoft.PowerAutomateDesktop", "type": "appx", "desc": "Power Automate workflow engine preload", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Microsoft.MicrosoftStickyNotes", "type": "appx", "desc": "Sticky Notes companion app", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Microsoft.XboxGamingOverlay", "type": "appx", "desc": "Xbox Game Bar heavy overlay injector", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},
    {"name": "Microsoft.XboxApp", "type": "appx", "desc": "Xbox Console Companion", "vendor": "Microsoft", "category": "Consumer_Bloatware", "risk_tier": 2, "is_safe": True},

    # =========================================================================
    # 6. HIGH-FREQUENCY TELEMETRY SCHEDULED TASKS (TIER 1 - SAFE TO DISABLE)
    # =========================================================================
    {"name": "Microsoft Compatibility Appraiser", "type": "task", "desc": "Application Experience daily full-disk telemetry compatibility scanner", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "ProgramDataUpdater", "type": "task", "desc": "Application Experience crash history and telemetry updater", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "StartupAppTask", "type": "task", "desc": "Application Experience startup impact profiler", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "PcaPatchDbTask", "type": "task", "desc": "Application Experience compatibility shim database updater", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "Consolidator", "type": "task", "desc": "Customer Experience Improvement Program metrics consolidator and packager", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "UsbCeip", "type": "task", "desc": "Customer Experience Improvement Program USB telemetry collector", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "KernelCeipTask", "type": "task", "desc": "Customer Experience Improvement Program kernel halt event collector", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft-Windows-DiskDiagnosticDataCollector", "type": "task", "desc": "Disk diagnostic telemetry collector S.M.A.R.T. health uploader", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "Microsoft-Windows-DiskDiagnosticResolver", "type": "task", "desc": "Disk diagnostic resolver error prompter", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "QueueReporting", "type": "task", "desc": "Windows Error Reporting queue upload flushing agent", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "DmClient", "type": "task", "desc": "Feedback and diagnostic survey client uploader", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "DmClientOnScenarioDownload", "type": "task", "desc": "Feedback scenario download telemetry trigger", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "Autochk Proxy", "type": "task", "desc": "Autochk disk corruption report proxy uploader", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "WinSAT", "type": "task", "desc": "Windows System Assessment benchmark execution task", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "AnalyzeSystem", "type": "task", "desc": "Power efficiency diagnostic trace collector", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "MapsUpdateTask", "type": "task", "desc": "Offline maps periodic poller", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "MapsToastTask", "type": "task", "desc": "Offline maps toast notification manager", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 1, "is_safe": True},
    {"name": "ScheduledDefrag", "type": "task", "desc": "Automatic background drive defragmentation and trimming", "vendor": "Microsoft", "category": "High_Overhead_Task", "risk_tier": 2, "is_safe": True},

    # =========================================================================
    # 7. CORE OS ESSENTIAL & SYSTEM SHIELD (TIER 0 - STRICTLY PROTECTED WHITELIST)
    # =========================================================================
    {"name": "Appinfo", "type": "service", "desc": "Application Information Service for UAC Administrative Elevation", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "RpcSs", "type": "service", "desc": "Remote Procedure Call (RPC) Core Kernel Message Engine", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "RpcEptMapper", "type": "service", "desc": "RPC Endpoint Mapper IPC Broker", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "DcomLaunch", "type": "service", "desc": "DCOM Server Process Launcher Core Object Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "StateRepository", "type": "service", "desc": "State Repository Service AppX manifest and database manager", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "ClipSVC", "type": "service", "desc": "Client License Service (ClipSVC) Microsoft Store digital licenses", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "wuauserv", "type": "service", "desc": "Windows Update Service operating system security patcher", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "TrustedInstaller", "type": "service", "desc": "Windows Modules Installer Component-Based Servicing CBS", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "UsoSvc", "type": "service", "desc": "Update Session Orchestrator update workflow manager", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "WaaSMedicSvc", "type": "service", "desc": "Windows Update Medic Service self-healing repair engine", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "InstallService", "type": "service", "desc": "Microsoft Store Install Service UWP application installer", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "AppXSvc", "type": "service", "desc": "AppX Deployment Service UWP manifest deployer", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "AppReadiness", "type": "service", "desc": "App Readiness Service user login setup broker", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Audiosrv", "type": "service", "desc": "Windows Audio Service audio playback and mixing engine", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "AudioEndpointBuilder", "type": "service", "desc": "Windows Audio Endpoint Builder sound device enumerator", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "CryptSvc", "type": "service", "desc": "Cryptographic Services driver signature and catalog validator", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Dhcp", "type": "service", "desc": "DHCP Client local network IP address lease manager", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Dnscache", "type": "service", "desc": "DNS Client Cache domain name resolution broker", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "WlanSvc", "type": "service", "desc": "WLAN AutoConfig Wi-Fi radio and authentication engine", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "LanmanWorkstation", "type": "service", "desc": "Workstation network client SMB share connector", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "netprofm", "type": "service", "desc": "Network List Service network connection status provider", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "NlaSvc", "type": "service", "desc": "Network Location Awareness network state reporter", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "nsi", "type": "service", "desc": "Network Store Interface Service kernel network notification", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "PlugPlay", "type": "service", "desc": "Plug and Play hardware device detection bus", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Power", "type": "service", "desc": "Power Service ACPI power plan and sleep state coordinator", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "ProfSvc", "type": "service", "desc": "User Profile Service Windows desktop account login broker", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "SamSs", "type": "service", "desc": "Security Accounts Manager local user credential database", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "LsaIso", "type": "service", "desc": "Credential Guard LSA Isolated Process authentication host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "KeyIso", "type": "service", "desc": "CNG Key Isolation TPM and BitLocker cryptography host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "VaultSvc", "type": "service", "desc": "Credential Manager saved Windows credentials host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "mpssvc", "type": "service", "desc": "Windows Defender Firewall network security and UWP sandbox bridge", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "BFE", "type": "service", "desc": "Base Filtering Engine firewall and packet filter manager", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "BDESVC", "type": "service", "desc": "BitLocker Drive Encryption Service storage encryption host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "FontCache", "type": "service", "desc": "Windows Font Cache Service font glyph rendering accelerator", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "FontCache3.0.0.0", "type": "service", "desc": "Windows Presentation Foundation WPF Font Cache Service", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "EventLog", "type": "service", "desc": "Windows Event Log system auditing provider", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Schedule", "type": "service", "desc": "Task Scheduler engine automated maintenance host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "UserManager", "type": "service", "desc": "User Manager multi-user shell broker", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Themes", "type": "service", "desc": "Themes visual styles manager", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Winmgmt", "type": "service", "desc": "Windows Management Instrumentation WMI system query host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},

    # Hardware Drivers (NVIDIA, AMD, Intel Core, VMware)
    {"name": "nvsvc", "type": "service", "desc": "NVIDIA Display Driver Service GPU hardware management", "vendor": "NVIDIA", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "NVDisplay.Container.exe", "type": "process", "desc": "NVIDIA Driver Container Service", "vendor": "NVIDIA", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "amdfendrs", "type": "service", "desc": "AMD Crash Defender Driver Service GPU hardware safety", "vendor": "AMD", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "AMD External Events Utility", "type": "service", "desc": "AMD Catalyst Hardware Event Driver Service", "vendor": "AMD", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "AmdPpkgSvc", "type": "service", "desc": "AMD Provisioning Package Core Driver Service", "vendor": "AMD", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "amdpmfservice", "type": "service", "desc": "AMD Platform Management Framework Service", "vendor": "AMD", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "vmtoolsd", "type": "service", "desc": "VMware Tools Core Daemon virtualization driver", "vendor": "VMware", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},

    # Core Kernel & System Processes
    {"name": "System", "type": "process", "desc": "NT Kernel and System Process", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "System Idle Process", "type": "process", "desc": "CPU Idle Process", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Registry", "type": "process", "desc": "Kernel Registry Architecture Hive", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "smss.exe", "type": "process", "desc": "Session Manager Subsystem", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "csrss.exe", "type": "process", "desc": "Client Server Runtime Subsystem", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "wininit.exe", "type": "process", "desc": "Windows Initialization Process", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "services.exe", "type": "process", "desc": "Services and Controller App", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "lsass.exe", "type": "process", "desc": "Local Security Authority Process", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "winlogon.exe", "type": "process", "desc": "Windows Logon Application", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "dwm.exe", "type": "process", "desc": "Desktop Window Manager Compositor", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "explorer.exe", "type": "process", "desc": "Windows Explorer Shell GUI", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "fontdrvhost.exe", "type": "process", "desc": "Usermode Font Driver Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "sihost.exe", "type": "process", "desc": "Shell Infrastructure Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "ctfmon.exe", "type": "process", "desc": "CTF Loader and Input Architecture", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "conhost.exe", "type": "process", "desc": "Console Window Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "svchost.exe", "type": "process", "desc": "Host Process for Windows Services", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "MemCompression", "type": "process", "desc": "Windows Memory Compression Engine", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "taskhostw.exe", "type": "process", "desc": "Host Process for Windows Tasks", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "RuntimeBroker.exe", "type": "process", "desc": "Runtime Broker UWP Permission Manager", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "ApplicationFrameHost.exe", "type": "process", "desc": "Application Frame Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "StartMenuExperienceHost.exe", "type": "process", "desc": "Start Menu Experience Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "ShellExperienceHost.exe", "type": "process", "desc": "Windows Shell Experience Host", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "SearchHost.exe", "type": "process", "desc": "Windows Search Host Indexer Client", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Taskmgr.exe", "type": "process", "desc": "Windows Task Manager Diagnostic Tool", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "powershell.exe", "type": "process", "desc": "Windows PowerShell Engine", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "cmd.exe", "type": "process", "desc": "Windows Command Processor", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "WmiPrvSE.exe", "type": "process", "desc": "WMI Provider Host Core Service", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},

    # Core System UWP AppX Whitelist
    {"name": "Microsoft.WindowsStore", "type": "appx", "desc": "Microsoft Store App Platform", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.DesktopAppInstaller", "type": "appx", "desc": "Windows Package Manager winget MSIX installer", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.StorePurchaseApp", "type": "appx", "desc": "Store In-App Purchase API Provider", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.WindowsTerminal", "type": "appx", "desc": "Windows Terminal Modern Console", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.WindowsCalculator", "type": "appx", "desc": "Windows Calculator Core Utility", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.WindowsNotepad", "type": "appx", "desc": "Windows Notepad Text Editor", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.ScreenSketch", "type": "appx", "desc": "Snipping Tool Screen Capture Utility", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.Paint", "type": "appx", "desc": "Paint Graphic Editor", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.UI.Xaml.2.8", "type": "appx", "desc": "Modern UI Visual Runtime Library", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.VCLibs.140.00", "type": "appx", "desc": "Visual C++ Runtime Binaries for Modern Apps", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.NET.Native.Framework.2.2", "type": "appx", "desc": ".NET Native Runtime Framework", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False},
    {"name": "Microsoft.AccountsControl", "type": "appx", "desc": "Account Authentication Modal Broker", "vendor": "Microsoft", "category": "Core_OS_Essential", "risk_tier": 0, "is_safe": False}
]

def generate_dataset():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(os.path.dirname(out_dir), "data")
    os.makedirs(data_dir, exist_ok=True)
    out_file = os.path.join(data_dir, "training_dataset.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(DATASET, f, indent=2)
    print(f"Generated {len(DATASET)} training samples in {out_file}")

if __name__ == "__main__":
    generate_dataset()
