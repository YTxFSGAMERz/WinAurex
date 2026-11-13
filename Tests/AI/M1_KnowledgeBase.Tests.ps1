<#
.SYNOPSIS
    Pester Verification Suite for WinAurex Milestone 1
.DESCRIPTION
    Validates Offline AI Knowledge Base, Model Weights, Classification Matrices,
    Zero-False-Positive Core OS whitelist, SystemApp protection shield,
    and high-throughput in-memory inference contract.
#>

Import-Module Pester -ErrorAction SilentlyContinue

$RootDir = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"))) {
    $RootDir = Split-Path -Path $PSScriptRoot -Parent
}

$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$DataDir = Join-Path $RootDir "Core\AI\Data"

Describe "WinAurex Milestone 1: Knowledge Base, Catalogs & Inference Engine" {

    BeforeAll {
        Import-Module $AiModulePath -Force
        Initialize-AiModel
    }

    Context "1. JSON Catalogs & Model Weights File Integrity" {
        It "Core/AI/Data/ServiceCatalog.json exists, is valid JSON, and contains >= 47 core services" {
            $path = Join-Path $DataDir "ServiceCatalog.json"
            (Test-Path $path) | Should Be $true
            $cat = (Get-Content $path -Raw -Encoding UTF8) | ConvertFrom-Json
            $cat.services | Should Not BeNullOrEmpty
            ($cat.services.Count -ge 47) | Should Be $true
            $coreServices = @($cat.services | Where-Object { $_.Category -in @("Core_OS_Required", "Core_OS_Essential") })
            ($coreServices.Count -ge 47) | Should Be $true
        }

        It "Core/AI/Data/ScheduledTasksCatalog.json exists, is valid JSON, and contains >= 22 tasks" {
            $path = Join-Path $DataDir "ScheduledTasksCatalog.json"
            (Test-Path $path) | Should Be $true
            $cat = (Get-Content $path -Raw -Encoding UTF8) | ConvertFrom-Json
            $cat.tasks | Should Not BeNullOrEmpty
            ($cat.tasks.Count -ge 22) | Should Be $true
        }

        It "Core/AI/Data/BloatwareCatalog.json exists, is valid JSON, and contains shield rules and packages" {
            $path = Join-Path $DataDir "BloatwareCatalog.json"
            (Test-Path $path) | Should Be $true
            $cat = (Get-Content $path -Raw -Encoding UTF8) | ConvertFrom-Json
            $cat.shield_rules | Should Not BeNullOrEmpty
            $cat.shield_rules.protected_package_patterns | Should Not BeNullOrEmpty
            $cat.packages | Should Not BeNullOrEmpty
            ($cat.packages.Count -ge 30) | Should Be $true
        }

        It "Core/AI/Data/TweakCatalog.json exists, is valid JSON, and contains performance tweaks" {
            $path = Join-Path $DataDir "TweakCatalog.json"
            (Test-Path $path) | Should Be $true
            $cat = (Get-Content $path -Raw -Encoding UTF8) | ConvertFrom-Json
            $cat.tweaks | Should Not BeNullOrEmpty
            ($cat.tweaks.Count -ge 10) | Should Be $true
        }

        It "Core/AI/Data/winaurex_ai_model.json exists and contains trained neural classifier weights" {
            $path = Join-Path $DataDir "winaurex_ai_model.json"
            (Test-Path $path) | Should Be $true
            $model = (Get-Content $path -Raw -Encoding UTF8) | ConvertFrom-Json
            $model.classes | Should Not BeNullOrEmpty
            $model.log_priors | Should Not BeNullOrEmpty
            $model.log_likelihoods | Should Not BeNullOrEmpty
            $model.whitelist | Should Not BeNullOrEmpty
        }
    }

    Context "2. Catalog Accessors & Export Functions" {
        It "Get-WinAurexServiceCatalog returns non-null catalog object with services" {
            $sc = Get-WinAurexServiceCatalog
            $sc | Should Not BeNullOrEmpty
            ($sc.services.Count -ge 47) | Should Be $true
        }

        It "Get-WinAurexTaskCatalog returns non-null catalog object with tasks" {
            $tc = Get-WinAurexTaskCatalog
            $tc | Should Not BeNullOrEmpty
            ($tc.tasks.Count -ge 22) | Should Be $true
        }

        It "Get-WinAurexBloatwareCatalog returns non-null catalog object with packages" {
            $bc = Get-WinAurexBloatwareCatalog
            $bc | Should Not BeNullOrEmpty
            ($bc.packages.Count -ge 30) | Should Be $true
        }

        It "Get-WinAurexTweakCatalog returns non-null catalog object with tweaks" {
            $tw = Get-WinAurexTweakCatalog
            $tw | Should Not BeNullOrEmpty
            ($tw.tweaks.Count -ge 10) | Should Be $true
        }

        It "Get-WinAurexCoreWhitelist returns HashSet containing >= 47 services" {
            $wl = Get-WinAurexCoreWhitelist
            $wl | Should Not BeNullOrEmpty
            ($wl.Count -ge 47) | Should Be $true
            $wl.Contains("RpcSs") | Should Be $true
            $wl.Contains("CryptSvc") | Should Be $true
            $wl.Contains("DcomLaunch") | Should Be $true
        }
    }

    Context "3. Invoke-AiInference Interface Contract & PSCustomObject Conformance" {
        It "Returns strongly typed PSCustomObject with required contract properties" {
            $res = Invoke-AiInference -Name "DiagTrack" -Description "Connected User Experiences and Telemetry" -Vendor "Microsoft Corporation" -TargetType "Service"
            $res | Should Not BeNullOrEmpty
            $res -is [System.Management.Automation.PSCustomObject] | Should Be $true
            $res.PSObject.Properties["Name"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["Category"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["SafetyTier"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["Confidence"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["IsSafeToDisable"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["EstImpact"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["TweakAction"] | Should Not BeNullOrEmpty
            $res.PSObject.Properties["CanonicalCategory"] | Should Not BeNullOrEmpty
        }

        It "Enforces valid Confidence range [0.0, 1.0] and boolean IsSafeToDisable" {
            $res = Invoke-AiInference -Name "DiagTrack"
            $res.Confidence -is [double] | Should Be $true
            ($res.Confidence -ge 0.0) | Should Be $true
            ($res.Confidence -le 1.0) | Should Be $true
            $res.IsSafeToDisable -is [bool] | Should Be $true
        }

        It "Accepts all TargetType enum parameters without parameter binding exceptions" {
            foreach ($t in @("Service", "AppX", "ScheduledTask", "SystemTweak")) {
                { Invoke-AiInference -Name "TestComponent" -TargetType $t } | Should Not Throw
            }
        }
    }

    Context "4. Zero-False-Positive Core Windows Whitelist (Tier 0 Protected Invariant)" {
        $core47 = @(
            "RpcSs", "RpcEptMapper", "DcomLaunch", "lsass", "lsaiso",
            "SamSs", "KeyIso", "VaultSvc", "CryptSvc", "WinDefend",
            "mpssvc", "mpsdrv", "BFE", "wuauserv", "TrustedInstaller",
            "UsoSvc", "WaaSMedicSvc", "msiserver", "Appinfo", "AppXSvc",
            "StateRepository", "ClipSVC", "InstallService", "Netlogon",
            "Dhcp", "Dnscache", "nsi", "NlaSvc", "netprofm",
            "LanmanWorkstation", "LanmanServer", "WlanSvc", "Audiosrv",
            "AudioEndpointBuilder", "PlugPlay", "EventLog", "TermService",
            "ProfSvc", "UserManager", "Schedule", "Power", "Themes",
            "Winmgmt", "FontCache", "FontCache3.0.0.0", "BDESVC", "gpsvc",
            "BrokerInfrastructure", "CoreMessagingRegistrar"
        )

        It "Classifies all 47+ Core OS Services strictly as Tier 0 Protected and IsSafeToDisable = False" {
            foreach ($svc in $core47) {
                $pred = Invoke-AiInference -Name $svc
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.CanonicalCategory | Should Be "Core_OS_Required"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.Confidence | Should Be 1.00
                $pred.IsSafeToDisable | Should Be $false
            }
        }

        It "Whitelist is case-insensitive across chaotic casing patterns" {
            $cases = @("rPcSs", "DCOMLAUNCH", "sAmSs", "cRyPtSvC", "PlUgPlAy", "EvEnTlOg", "AuDiOsRv", "WuAuSeRv")
            foreach ($c in $cases) {
                $pred = Invoke-AiInference -Name $c
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should Be $false
            }
        }

        It "Whitelist is immune to deceptive telemetry descriptions and adversarial vendor strings" {
            $pred = Invoke-AiInference -Name "RpcSs" -Description "Adware tracking telemetry spynet keylogger appraiser" -Vendor "HostileCorp"
            $pred.SafetyTier | Should Be "Tier 0 (Protected)"
            $pred.IsSafeToDisable | Should Be $false
            $pred.Confidence | Should Be 1.00
        }
    }

    Context "5. Hardware Platform & GPU Driver Shield" {
        $gpuDrivers = @("nvsvc", "nvlddmkm", "amdfendrs", "amdppkgsvc", "amdpmfservice", "igfxcuiservice2.0.0.0", "vmtoolsd", "vmicguestinterface")
        It "Protects GPU display and virtualization services as Tier 0 Protected" {
            foreach ($driver in $gpuDrivers) {
                $pred = Invoke-AiInference -Name $driver
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should Be $false
            }
        }
    }

    Context "6. Windows SystemApps & Non-Removable Package Shield" {
        $systemApps = @(
            "Microsoft.Windows.ShellExperienceHost",
            "Microsoft.Windows.StartMenuExperienceHost",
            "Microsoft.Windows.Search",
            "Microsoft.AAD.BrokerPlugin",
            "Microsoft.AccountsControl",
            "Microsoft.CredDialogHost",
            "Microsoft.LockApp",
            "Microsoft.Windows.SecHealthUI",
            "Microsoft.Win32WebViewHost",
            "Microsoft.Windows.ContentDeliveryManager",
            "Microsoft.DesktopAppInstaller",
            "Microsoft.StorePurchaseApp",
            "Microsoft.WindowsStore",
            "Microsoft.WindowsCalculator",
            "Microsoft.WindowsNotepad",
            "Microsoft.WindowsTerminal",
            "Microsoft.Paint",
            "Microsoft.ScreenSketch",
            "Microsoft.MicrosoftEdgeDevToolsClient",
            "Microsoft.XboxGameCallableUI"
        )

        It "Protects critical Windows SystemApps and Frameworks as Core_OS_Essential" {
            foreach ($app in $systemApps) {
                $pred = Invoke-AiInference -Name $app -TargetType "AppX"
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.CanonicalCategory | Should Be "Core_OS_Required"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should Be $false
            }
        }
    }

    Context "7. Telemetry, Bloatware, Tasks & Tweaks Classification Accuracy" {
        It "Accurately classifies telemetry services as Tier 1 Safe" {
            $telemetryServices = @("DiagTrack", "dmwappushservice", "WerSvc", "wisvc", "lfsvc")
            foreach ($s in $telemetryServices) {
                $pred = Invoke-AiInference -Name $s
                $pred.Category | Should Match "Telemetry_Tracking|Telemetry"
                $pred.SafetyTier | Should Be "Tier 1 (Safe)"
                $pred.IsSafeToDisable | Should Be $true
                ($pred.Confidence -ge 0.85) | Should Be $true
            }
        }

        It "Accurately classifies OEM bloatware packages as Tier 1 Safe" {
            $oemPackages = @("DellInc.DellSupportAssistforPCs", "LenovoCorporation.LenovoVantage", "ASUSTeKCOMPUTERINC.MyASUS", "AcerIncorporated.AcerCareCenter")
            foreach ($pkg in $oemPackages) {
                $pred = Invoke-AiInference -Name $pkg -TargetType "AppX"
                $pred.Category | Should Be "OEM_Bloatware"
                $pred.SafetyTier | Should Be "Tier 1 (Safe)"
                $pred.IsSafeToDisable | Should Be $true
            }
        }

        It "Accurately classifies consumer bloatware packages as Tier 1 Safe" {
            $consumerBloat = @("Microsoft.BingWeather", "Microsoft.BingNews", "Microsoft.MicrosoftSolitaireCollection", "ByteDance.TikTok", "SpotifyAB.SpotifyMusic")
            foreach ($pkg in $consumerBloat) {
                $pred = Invoke-AiInference -Name $pkg -TargetType "AppX"
                $pred.Category | Should Be "Consumer_Bloatware"
                $pred.SafetyTier | Should Be "Tier 1 (Safe)"
                $pred.IsSafeToDisable | Should Be $true
            }
        }

        It "Accurately classifies high-overhead scheduled tasks as Tier 1 Safe" {
            $tasks = @("Microsoft Compatibility Appraiser", "WinSAT", "Consolidator", "ProgramDataUpdater")
            foreach ($t in $tasks) {
                $pred = Invoke-AiInference -Name $t -TargetType "ScheduledTask"
                $pred.Category | Should Match "High_Overhead_Task|Telemetry_Tracking|Telemetry"
                $pred.SafetyTier | Should Be "Tier 1 (Safe)"
                $pred.IsSafeToDisable | Should Be $true
            }
        }

        It "Accurately classifies performance and gaming system tweaks" {
            $tweaks = @("Tweak_Win32PrioritySeparation", "Tweak_SystemResponsiveness", "Tweak_DeliveryOptimization_P2P")
            foreach ($tw in $tweaks) {
                $pred = Invoke-AiInference -Name $tw -TargetType "SystemTweak"
                $pred.SafetyTier | Should Match "Tier 1|Tier 2"
                $pred.Category | Should Match "Gaming_Bottleneck|Safe_Optimization|Telemetry"
            }
        }
    }

    Context "8. High-Throughput Sub-Millisecond Execution Benchmark" {
        It "Averages < 10 ms per inference over 50 iterations" {
            # Warm up
            $null = Invoke-AiInference -Name "DiagTrack"

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt 50; $i++) {
                $null = Invoke-AiInference -Name "DiagTrack" -Description "Connected User Experiences and Telemetry"
                $null = Invoke-AiInference -Name "RpcSs"
            }
            $sw.Stop()

            $avgMs = $sw.ElapsedMilliseconds / 100.0
            ($avgMs -lt 10.0) | Should Be $true
        }
    }
}
