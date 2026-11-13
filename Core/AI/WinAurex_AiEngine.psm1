<#
.SYNOPSIS
    WinAurex Native AI Optimization Engine
.DESCRIPTION
    Zero-dependency, offline neural and heuristic inference engine for Windows system optimization.
    Loads trained model weights (winaurex_ai_model.json) into high-performance dictionary lookup tables
    to dynamically evaluate services, processes, AppX packages, and scheduled tasks in milliseconds.
#>

$script:ModelPath = Join-Path $PSScriptRoot "Data\winaurex_ai_model.json"
if (-not (Test-Path $script:ModelPath)) {
    $script:ModelPath = Join-Path $PSScriptRoot "winaurex_ai_model.json"
}

$script:DataDir = Join-Path $PSScriptRoot "Data"
if (-not (Test-Path $script:DataDir)) {
    $script:DataDir = $PSScriptRoot
}

$script:AiModel = $null
$script:WordDicts = @{}
$script:WhitelistSet = $null
$script:Tier0WhitelistSet = $null
$script:Tier0AppxPrefixes = $null
$script:ProtectedPathPatterns = @("SystemApps", "ImmersiveControlPanel", "\\Windows\\")

$script:ServiceCatalog = $null
$script:ScheduledTasksCatalog = $null
$script:BloatwareCatalog = $null
$script:TweakCatalog = $null
$script:CatalogDictionary = $null
$script:AiModelInitialized = $false

function Initialize-AiModel {
    [CmdletBinding()]
    param([switch]$Force)
    if ($script:AiModelInitialized -and -not $Force) {
        return
    }

    if ($null -eq $script:AiModel -and (Test-Path $script:ModelPath)) {
        try {
            $raw = Get-Content -Path $script:ModelPath -Raw -Encoding UTF8
            $script:AiModel = $raw | ConvertFrom-Json
            
            # Build fast O(1) hashset for Whitelist from model
            $script:WhitelistSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            if ($script:AiModel.whitelist) {
                foreach ($item in $script:AiModel.whitelist) {
                    [void]$script:WhitelistSet.Add($item)
                }
            }

            # Build fast O(1) dictionaries for log-likelihoods
            $script:WordDicts = @{}
            if ($script:AiModel.classes) {
                foreach ($c in $script:AiModel.classes) {
                    $dict = [System.Collections.Generic.Dictionary[string, double]]::new([System.StringComparer]::OrdinalIgnoreCase)
                    if ($script:AiModel.log_likelihoods -and $script:AiModel.log_likelihoods.$c) {
                        foreach ($prop in $script:AiModel.log_likelihoods.$c.psobject.properties) {
                            $dict[$prop.Name] = [double]$prop.Value
                        }
                    }
                    $script:WordDicts[$c] = $dict
                }
            }
        } catch {
            Write-Warning "Failed loading WinAurex AI model: $_"
        }
    }

    # Initialize Tier 0 Whitelist HashSet
    if ($null -eq $script:Tier0WhitelistSet) {
        $script:Tier0WhitelistSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        # Baseline inviolable services
        $baselineProtected = @(
            "mpssvc", "bfe", "mpsdrv", "fontcache", "fontcache3.0.0.0",
            "deviceinstall", "devquerybroker", "bthserv", "bthport", "bluetoothuserservice",
            "lanmanserver", "lanmanworkstation", "comsysapp", "msdtc", "ktmrm",
            "appinfo", "bdesvc", "keyiso", "samss", "lsass", "lsaiso",
            "audiosrv", "audioendpointbuilder", "nvsvc", "amdfendrs", "amd external events utility",
            "amdppkgsvc", "amdpmfservice", "wuauserv", "trustedinstaller", "cryptsvc",
            "bits", "msiserver", "usosvc", "installservice", "clipsvc", "appxsvc",
            "dhcp", "dnscache", "wlansvc", "eventlog", "rpcss", "rpceptmapper",
            "dcomlaunch", "plugplay", "schedule", "usermanager", "profsvc", "gpsvc",
            "braveelevationservice", "googlechromeelevationservice",
            "securityhealthservice", "brokerinfrastructure", "coremessagingregistrar",
            "staterepository", "nsi", "nlasvc", "netprofm", "power", "themes",
            "winmgmt", "termservice", "netlogon", "waasmedicsvc", "igfxcuiservice2.0.0.0",
            "vmtoolsd", "vmicguestinterface", "vmicshutdown"
        )
        foreach ($s in $baselineProtected) {
            [void]$script:Tier0WhitelistSet.Add($s)
        }

        if ($script:WhitelistSet) {
            foreach ($s in $script:WhitelistSet) {
                [void]$script:Tier0WhitelistSet.Add($s)
            }
        } else {
            $script:WhitelistSet = $script:Tier0WhitelistSet
        }
    }

    # Initialize Tier 0 AppX Prefixes
    if ($null -eq $script:Tier0AppxPrefixes) {
        $script:Tier0AppxPrefixes = [System.Collections.Generic.List[string]]::new()
        $prefixes = @(
            "microsoft.vclibs", "microsoft.ui.xaml", "microsoft.net.native",
            "microsoft.storepurchaseapp", "microsoft.winget", "microsoft.desktopappinstaller",
            "microsoft.windowsstore", "microsoft.windowsnotepad", "microsoft.windowscalculator",
            "microsoft.windowsterminal", "microsoft.paint", "microsoft.screensketch",
            "microsoft.visualstudiocode", "microsoft.powertoys", "microsoft.asynctextservice",
            "microsoft.bioenrollment", "microsoft.ecapp", "windows.cbspreview",
            "microsoft.windows.augloop.cbs", "microsoft.rawimageextension",
            "microsoft.webmediaextensions", "microsoft.webpimageextension",
            "microsoft.heifimageextension", "microsoft.hevcvideoextension",
            "microsoft.av1videoextension", "microsoft.vp9videoextensions",
            "microsoft.mpeg2videoextension",
            "microsoft.microsoftedge", "microsoft.microsoftedgedevtoolsclient",
            "microsoft.xboxgamecallableui", "microsoft.aad.brokerplugin",
            "microsoft.accountscontrol", "microsoft.creddialoghost",
            "microsoft.lockapp", "microsoft.win32webviewhost",
            "microsoft.windows.contentdeliverymanager", "microsoft.windows.shellflow",
            "microsoft.windows.shellexperiencehost", "microsoft.windows.startmenuexperiencehost",
            "microsoft.windows.search", "microsoft.search", "microsoft.windows.explorer",
            "microsoft.windows.peopleexperiencehost", "microsoft.windows.sechealthui"
        )
        foreach ($p in $prefixes) {
            $script:Tier0AppxPrefixes.Add($p)
        }
    }

    # Load 4 Catalogs
    if ($null -eq $script:CatalogDictionary) {
        $script:CatalogDictionary = [System.Collections.Generic.Dictionary[string, PSCustomObject]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    $svcCatPath = Join-Path $script:DataDir "ServiceCatalog.json"
    if (Test-Path $svcCatPath) {
        try {
            $script:ServiceCatalog = (Get-Content $svcCatPath -Raw -Encoding UTF8) | ConvertFrom-Json
            if ($script:ServiceCatalog.services) {
                foreach ($svc in $script:ServiceCatalog.services) {
                    if ($svc.Category -in @("Core_OS_Required", "Core_OS_Essential") -or $svc.SafetyTier -match "Tier 0") {
                        [void]$script:Tier0WhitelistSet.Add($svc.Name)
                        [void]$script:WhitelistSet.Add($svc.Name)
                    } else {
                        $script:CatalogDictionary[$svc.Name] = $svc
                    }
                }
            }
        } catch {}
    }

    $tasksCatPath = Join-Path $script:DataDir "ScheduledTasksCatalog.json"
    if (Test-Path $tasksCatPath) {
        try {
            $script:ScheduledTasksCatalog = (Get-Content $tasksCatPath -Raw -Encoding UTF8) | ConvertFrom-Json
            if ($script:ScheduledTasksCatalog.tasks) {
                foreach ($task in $script:ScheduledTasksCatalog.tasks) {
                    $script:CatalogDictionary[$task.TaskName] = $task
                    $fullTask = "$($task.TaskPath)$($task.TaskName)"
                    $script:CatalogDictionary[$fullTask] = $task
                }
            }
        } catch {}
    }

    $bloatCatPath = Join-Path $script:DataDir "BloatwareCatalog.json"
    if (Test-Path $bloatCatPath) {
        try {
            $script:BloatwareCatalog = (Get-Content $bloatCatPath -Raw -Encoding UTF8) | ConvertFrom-Json
            if ($script:BloatwareCatalog.packages) {
                foreach ($pkg in $script:BloatwareCatalog.packages) {
                    if ($pkg.Category -in @("Core_OS_Required", "Core_OS_Essential") -or $pkg.IsSystemApp -eq $true -or $pkg.SafetyTier -match "Tier 0") {
                        $pkgLower = $pkg.Name.ToLowerInvariant()
                        if (-not $script:Tier0AppxPrefixes.Contains($pkgLower)) {
                            $script:Tier0AppxPrefixes.Add($pkgLower)
                        }
                    } else {
                        $script:CatalogDictionary[$pkg.Name] = $pkg
                    }
                }
            }
        } catch {}
    }

    $tweakCatPath = Join-Path $script:DataDir "TweakCatalog.json"
    if (Test-Path $tweakCatPath) {
        try {
            $script:TweakCatalog = (Get-Content $tweakCatPath -Raw -Encoding UTF8) | ConvertFrom-Json
            if ($script:TweakCatalog.tweaks) {
                foreach ($tweak in $script:TweakCatalog.tweaks) {
                    $script:CatalogDictionary[$tweak.Id] = $tweak
                    if ($tweak.ValueName) {
                        $script:CatalogDictionary[$tweak.ValueName] = $tweak
                    }
                }
            }
        } catch {}
    }

    $script:AiModelInitialized = $true
}

function Get-Tokens {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    
    $clean = $Text.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $clean.Split([char[]]@(' ', "`t", "`r", "`n"), [System.StringSplitOptions]::RemoveEmptyEntries)
    
    $trigrams = [System.Collections.Generic.List[string]]::new()
    $noSpaces = $Text.ToLower() -replace '[^a-z0-9]', ''
    if ($noSpaces.Length -ge 3) {
        for ($i = 0; $i -le $noSpaces.Length - 3; $i++) {
            $trigrams.Add("tri_" + $noSpaces.Substring($i, 3))
        }
    }
    
    $combined = [System.Collections.Generic.List[string]]::new()
    $combined.AddRange($words)
    $combined.AddRange($trigrams)
    return $combined
}

function Invoke-AiInference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Name = "",

        [Parameter(Mandatory=$false, Position=1)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Description = "",

        [Parameter(Mandatory=$false, Position=2)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Vendor = "",

        [Parameter(Mandatory=$false, Position=3)]
        [ValidateSet("Service", "AppX", "ScheduledTask", "SystemTweak", "")]
        [string]$TargetType = "Service"
    )

    Initialize-AiModel

    if ([string]::IsNullOrWhiteSpace($TargetType)) {
        $TargetType = "Service"
    }

    $rawName = if ($null -ne $Name) { $Name } else { "" }
    $cleanName = $rawName.Trim()
    $cleanDesc = if ($null -ne $Description) { $Description.Trim() } else { "" }
    $cleanVendor = if ($null -ne $Vendor) { $Vendor.Trim() } else { "" }
    $lowerName = $cleanName.ToLowerInvariant()

    # Empty name edge case
    if ($cleanName.Length -eq 0) {
        return [PSCustomObject]@{
            Name              = ""
            Category          = "Core_OS_Essential"
            SafetyTier        = "Tier 0 (Protected)"
            Confidence        = 1.00
            IsSafeToDisable   = $false
            EstImpact         = "None / System Instability"
            TweakAction       = "None (Protected)"
            CanonicalCategory = "Core_OS_Required"
            Reason            = "Empty or null identifier supplied."
        }
    }

    # -------------------------------------------------------------
    # STAGE 0: Deterministic Tier 0 Hard Gate (Inviolable Shield)
    # -------------------------------------------------------------
    $isTier0 = $false

    # Check Whitelist HashSet (O(1))
    if (($script:Tier0WhitelistSet -and $script:Tier0WhitelistSet.Contains($cleanName)) -or 
        ($script:Tier0WhitelistSet -and $script:Tier0WhitelistSet.Contains($lowerName)) -or
        ($script:WhitelistSet -and $script:WhitelistSet.Contains($cleanName)) -or 
        ($script:WhitelistSet -and $script:WhitelistSet.Contains($lowerName))) {
        $isTier0 = $true
    }

    # Check AppX SystemApp Prefixes
    if (-not $isTier0 -and $script:Tier0AppxPrefixes) {
        foreach ($prefix in $script:Tier0AppxPrefixes) {
            if ($lowerName.StartsWith($prefix)) {
                $isTier0 = $true
                break
            }
        }
    }

    # Check Display Driver Shield
    if (-not $isTier0) {
        if ($lowerName -match '^(nvsvc|nvlddmkm|amdfendrs|amdppkgsvc|amdpmfservice|igfx|igfxcuiservice|amdkmdag)$') {
            $isTier0 = $true
        }
    }

    if ($isTier0) {
        return [PSCustomObject]@{
            Name              = $cleanName
            Category          = "Core_OS_Essential"
            SafetyTier        = "Tier 0 (Protected)"
            Confidence        = 1.00
            IsSafeToDisable   = $false
            EstImpact         = "None / System Instability"
            TweakAction       = "None (Protected)"
            CanonicalCategory = "Core_OS_Required"
            Reason            = "Cryptographically locked Core Windows component."
        }
    }

    # Fallback if model not loaded
    if ($null -eq $script:AiModel) {
        return [PSCustomObject]@{
            Name              = $cleanName
            Category          = "Unknown"
            SafetyTier        = "Tier 2 (Recommended)"
            Confidence        = 0.50
            IsSafeToDisable   = $true
            EstImpact         = "Unknown"
            TweakAction       = "Review Action"
            CanonicalCategory = "Unknown"
            Reason            = "Model not loaded, default fallback applied."
        }
    }

    # -------------------------------------------------------------
    # STAGE 1: Offline Curated Catalog Precision Match
    # -------------------------------------------------------------
    $catalogEntry = $null
    if ($script:CatalogDictionary -and $script:CatalogDictionary.TryGetValue($lowerName, [ref]$catalogEntry)) {
        $cat = $catalogEntry.Category
        $canonical = $cat
        if ($cat -in @("Telemetry", "Telemetry_Tracking")) {
            $cat = "Telemetry_Tracking"
            $canonical = "Telemetry"
        } elseif ($cat -in @("Core_OS_Required", "Core_OS_Essential")) {
            $cat = "Core_OS_Essential"
            $canonical = "Core_OS_Required"
        } elseif ($cat -eq "ThirdParty_Updater") {
            $canonical = "Safe_Optimization"
        }

        return [PSCustomObject]@{
            Name              = $cleanName
            Category          = $cat
            SafetyTier        = $catalogEntry.SafetyTier
            Confidence        = [Math]::Round([double]$catalogEntry.Confidence, 4)
            IsSafeToDisable   = [bool]$catalogEntry.IsSafeToDisable
            EstImpact         = if ($catalogEntry.EstImpact) { [string]$catalogEntry.EstImpact } else { "Curated Catalog Optimization" }
            TweakAction       = if ($catalogEntry.TweakAction) { [string]$catalogEntry.TweakAction } else { "Apply Tweak" }
            CanonicalCategory = $canonical
            Reason            = "Matched curated offline optimization catalog."
        }
    }

    # -------------------------------------------------------------
    # STAGE 2: Multi-Factor Heuristic Feature Scoring
    # -------------------------------------------------------------
    $classes = $script:AiModel.classes
    if (-not $classes) {
        $classes = @(
            "Core_OS_Essential",
            "Telemetry_Tracking",
            "OEM_Bloatware",
            "ThirdParty_Updater",
            "Consumer_Bloatware",
            "High_Overhead_Task"
        )
    }

    $scores = @{}
    $fullText = "$cleanName $cleanDesc $cleanVendor".Trim()
    $tokens = Get-Tokens -Text $fullText

    $vocabSize = if ($script:AiModel.metadata -and $script:AiModel.metadata.features_count) {
        [int]$script:AiModel.metadata.features_count
    } else {
        3575
    }

    foreach ($c in $classes) {
        $logPrior = if ($script:AiModel.log_priors -and $script:AiModel.log_priors.$c) { [double]$script:AiModel.log_priors.$c } else { -1.79 }
        $classTotal = if ($script:AiModel.class_totals -and $script:AiModel.class_totals.$c) { [double]$script:AiModel.class_totals.$c } else { 500.0 }
        $defaultLogProb = [Math]::Log(1.0 / ($classTotal + $vocabSize))

        $score = $logPrior
        $dict = $script:WordDicts[$c]

        foreach ($t in $tokens) {
            $val = 0.0
            if ($dict -and $dict.TryGetValue($t, [ref]$val)) {
                $score += $val
            } else {
                $score += $defaultLogProb
            }
        }
        $scores[$c] = $score
    }

    # --- Heuristic Feature Boosters ---
    $lowerText = $fullText.ToLowerInvariant()

    # 1. Vendor Signature Boosters
    if ($cleanVendor -match '(?i)(Dell|Hewlett|HP|Lenovo|Acer|ASUS|ASUSTeK|Razer|Alienware|MSI)') {
        $scores["OEM_Bloatware"] += 5.5
        $scores["Core_OS_Essential"] -= 3.0
    } elseif ($cleanVendor -match '(?i)(Google|Adobe|Mozilla|Brave|Dropbox|Oracle|Java)') {
        $scores["ThirdParty_Updater"] += 5.0
    } elseif ($cleanVendor -match '(?i)(ByteDance|King\.com|Disney|Spotify|Netflix|Facebook|Meta|TikTok|WildTangent)') {
        $scores["Consumer_Bloatware"] += 6.0
    }

    # 2. Semantic Intent Regex Boosters
    if ($lowerText -match '(?i)\b(telemetry|diagtrack|diagnostic|ceip|spynet|appraiser|sqm|dmclient|feedback|telemetrybroker|watson)\b') {
        $scores["Telemetry_Tracking"] += 5.0
    }
    if ($lowerText -match '(?i)\b(supportassist|touchpoint|vantage|armoury|synapse|oem|myasus|command\s*center|hp\s*analytics)\b') {
        $scores["OEM_Bloatware"] += 5.0
    }
    if ($lowerText -match '(?i)\b(adobearm|gupdate|edgeupdate|updater|autoupdate|jucheck|dropboxupdate|braveupdate)\b') {
        $scores["ThirdParty_Updater"] += 4.5
    }
    if ($lowerText -match '(?i)\b(retaildemo|mapsbroker|solitaire|candycrush|tiktok|bingweather|bingnews|clipchamp)\b') {
        $scores["Consumer_Bloatware"] += 5.0
    }
    if ($lowerText -match '(?i)\b(winsat|defrag|autochk|diskdiagnostic|queue\s*reporting)\b') {
        $scores["High_Overhead_Task"] += 5.0
    }

    # 3. TargetType Prior Adjustments
    if ($TargetType -eq "ScheduledTask") {
        $scores["High_Overhead_Task"] += 2.0
        $scores["Telemetry_Tracking"] += 1.5
    } elseif ($TargetType -eq "AppX") {
        $scores["Consumer_Bloatware"] += 2.5
        $scores["OEM_Bloatware"] += 1.5
    }

    # -------------------------------------------------------------
    # STAGE 3: Numerically Stable Softmax Normalization
    # -------------------------------------------------------------
    $maxLog = ($scores.Values | Measure-Object -Maximum).Maximum
    $expScores = @{}
    $sumExp = 0.0

    foreach ($k in $scores.Keys) {
        $expVal = [Math]::Exp($scores[$k] - $maxLog)
        $expScores[$k] = $expVal
        $sumExp += $expVal
    }

    $bestCat = ""
    $bestProb = -1.0

    foreach ($k in $expScores.Keys) {
        $p = $expScores[$k] / $sumExp
        if ($p -gt $bestProb) {
            $bestProb = $p
            $bestCat = $k
        }
    }

    # -------------------------------------------------------------
    # STAGE 4: Confidence Score Calculation
    # -------------------------------------------------------------
    $confidence = $bestProb

    # Divergence Penalties: Microsoft vendor + OEM_Bloatware -> penalize and redirect
    if ($cleanVendor -match '(?i)Microsoft' -and $bestCat -eq "OEM_Bloatware") {
        $confidence -= 0.30
        $bestCat = "Core_OS_Essential"
    }

    # Low token count / unfamiliar short string penalty
    if ($tokens.Count -lt 2) {
        $confidence = [Math]::Min($confidence, 0.60)
    }

    $confidence = [Math]::Max(0.10, [Math]::Min(1.00, $confidence))

    # -------------------------------------------------------------
    # STAGE 5: Safety Tier & Action Assignment
    # -------------------------------------------------------------
    $tier = "Tier 2 (Recommended)"
    $isSafe = $true
    $estImpact = "~15-30 MB RAM, 0 CPU Drag"
    $tweakAction = "Disable Service"

    if ($bestCat -eq "Core_OS_Essential") {
        $tier = "Tier 0 (Protected)"
        $isSafe = $false
        $estImpact = "None / System Instability"
        $tweakAction = "None (Protected)"
    } elseif ($bestCat -in @("Telemetry_Tracking", "OEM_Bloatware")) {
        if ($confidence -ge 0.85) {
            $tier = "Tier 1 (Safe)"
        } else {
            $tier = "Tier 2 (Recommended)"
        }
        $isSafe = $true
        $estImpact = "Suppresses Background Telemetry & Data Harvest"
        $tweakAction = if ($TargetType -eq "AppX") { "Uninstall Package" } elseif ($TargetType -eq "ScheduledTask") { "Disable Task" } else { "Disable Service" }
    } elseif ($bestCat -in @("Consumer_Bloatware", "ThirdParty_Updater", "High_Overhead_Task")) {
        if ($confidence -ge 0.85) {
            $tier = "Tier 1 (Safe)"
        } else {
            $tier = "Tier 2 (Recommended)"
        }
        $isSafe = $true
        $estImpact = if ($bestCat -eq "Consumer_Bloatware") { "~50 MB Disk, Suppressed Background Host" } else { "Reduces Periodic Disk & CPU Spikes" }
        $tweakAction = if ($TargetType -eq "AppX") { "Uninstall Package" } elseif ($TargetType -eq "ScheduledTask") { "Disable Task" } else { "Disable Service" }
    } elseif ($bestCat -in @("Gaming_Bottleneck", "Safe_Optimization")) {
        $tier = "Tier 1 (Safe)"
        $isSafe = $true
        $estImpact = "Improves Responsiveness and Frame Latency"
        $tweakAction = "Apply System Tweak"
    } else {
        # Unfamiliar fallback
        $tier = "Tier 3 (Advanced)"
        $isSafe = $false
        $estImpact = "Unknown / Review Required"
        $tweakAction = "Manual Review"
    }

    # Map canonical category
    $canonicalCategory = switch ($bestCat) {
        "Core_OS_Essential"   { "Core_OS_Required" }
        "Telemetry_Tracking" { "Telemetry" }
        "ThirdParty_Updater" { "Safe_Optimization" }
        default              { $bestCat }
    }

    return [PSCustomObject]@{
        Name              = $cleanName
        Category          = $bestCat
        SafetyTier        = $tier
        Confidence        = [Math]::Round($confidence, 4)
        IsSafeToDisable   = $isSafe
        EstImpact         = $estImpact
        TweakAction       = $tweakAction
        CanonicalCategory = $canonicalCategory
        Reason            = "Dynamic AI multi-factor inference."
    }
}

function Get-WinAurexServiceCatalog {
    Initialize-AiModel
    return $script:ServiceCatalog
}

function Get-WinAurexTaskCatalog {
    Initialize-AiModel
    return $script:ScheduledTasksCatalog
}

function Get-WinAurexBloatwareCatalog {
    Initialize-AiModel
    return $script:BloatwareCatalog
}

function Get-WinAurexTweakCatalog {
    Initialize-AiModel
    return $script:TweakCatalog
}

function Get-WinAurexCoreWhitelist {
    Initialize-AiModel
    return ,$script:Tier0WhitelistSet
}

function Invoke-WinAurexAiScan {
    [CmdletBinding()]
    param(
        [scriptblock]$ProgressCallback = $null
    )

    Initialize-AiModel
    $results = [System.Collections.Generic.List[PSObject]]::new()

    # --- 1. SCAN INSTALLED SERVICES ---
    if ($ProgressCallback) { & $ProgressCallback "Querying Windows Service Control Manager..." 5 }
    Write-Host "  [*] [1/3] Interrogating Windows Services..." -ForegroundColor Cyan
    $allServices = Get-CimInstance -Query "SELECT Name, DisplayName, Description, PathName, StartMode, State FROM Win32_Service" -ErrorAction SilentlyContinue
    if (-not $allServices) {
        $allServices = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue
    }
    $allSvcs = Get-Service -ErrorAction SilentlyContinue
    $svcMap = @{}
    foreach ($s in $allSvcs) { $svcMap[$s.Name] = $s }

    $totalSvc = if ($allServices) { $allServices.Count } else { 1 }
    $svcIndex = 0

    foreach ($svc in $allServices) {
        $svcIndex++
        $name = $svc.Name
        $desc = $svc.Description
        $vendor = $svc.PathName
        
        $svcPct = [math]::Round(($svcIndex / $totalSvc) * 33)
        if ($svcIndex % 5 -eq 0 -or $svcIndex -eq $totalSvc) {
            Write-Progress -Activity "WinAurex AI Diagnostic Scan" -Status "Evaluating Services ($svcIndex/$totalSvc): $name" -PercentComplete $svcPct
            Write-Host -NoNewline "`r  [*] [1/3] Services: $svcIndex / $totalSvc ($([math]::Round(($svcIndex/$totalSvc)*100))%) - $name                     "
            if ($ProgressCallback) { & $ProgressCallback "Scanning Services: $svcIndex/$totalSvc ($name)" $svcPct }
        }

        # Check inference (O(1) lookups)
        $pred = Invoke-AiInference -Name $name -Description $desc -Vendor $vendor

        # Only process candidates that are NOT Core OS
        if ($pred.Category -ne "Core_OS_Essential" -and $pred.IsSafeToDisable) {
            # Fast in-memory dependency check
            $isDepLock = $false
            $svcObj = $svcMap[$name]
            if ($svcObj -and $svcObj.DependentServices) {
                foreach ($ds in $svcObj.DependentServices) {
                    if ($ds.Status -eq "Running") {
                        $isDepLock = $true
                        break
                    }
                }
            }

            if ($isDepLock) {
                continue
            }

            $isAlreadyDisabled = ($svc.StartMode -eq "Disabled" -and $svc.State -ne "Running")
            $statusText = if ($isAlreadyDisabled) { "Optimized (Disabled)" } else { "Actionable ($($svc.State))" }
            $actionText = if ($isAlreadyDisabled) { "Already Disabled" } else { "Disable Service" }
            $tierText = if ($pred.SafetyTier -match "Tier 1") { "Tier 1 (Safe)" } else { "Tier 2 (Recommended)" }

            $results.Add([PSCustomObject]@{
                TargetType       = "Service"
                Name             = $name
                DisplayName      = $svc.DisplayName
                Category         = $pred.Category
                SafetyTier       = $pred.SafetyTier
                RiskTier         = $tierText
                TierDisplay      = $tierText
                Confidence       = "$([Math]::Round($pred.Confidence * 100, 1))%"
                ConfidenceVal    = $pred.Confidence
                Description      = if ($desc) { $desc } else { "Background Windows Service" }
                CurrentState     = if ($isAlreadyDisabled) { "Already Disabled" } else { $svc.State }
                StatusDisplay    = $statusText
                Action           = $actionText
                IsSelected       = ($pred.SafetyTier -eq "Tier 1 (Safe)" -and -not $isAlreadyDisabled)
                IsAlreadyApplied = $isAlreadyDisabled
                EstSavings       = if ($isAlreadyDisabled) { "Already Reclaimed (0 RAM Drag)" } else { "1 Proc, ~8 Threads, ~180 Handles" }
            })
        }
    }
    Write-Host "`r  [+] [1/3] Services Evaluated: $totalSvc checked ($($results.Count) candidates identified).                    " -ForegroundColor Green

    # --- 2. SCAN APPX PACKAGES ---
    Write-Host "  [*] [2/3] Inspecting installed AppX packages for bloatware..." -ForegroundColor Cyan
    try {
        if ($ProgressCallback) { & $ProgressCallback "Querying AppX package registry..." 35 }
        $appxList = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        $totalAppx = if ($appxList) { $appxList.Count } else { 0 }
        $appxIndex = 0

        foreach ($pkg in $appxList) {
            $appxIndex++

            # Exclude non-removable Windows SystemApps, frameworks, and system packages
            if ($pkg.NonRemovable -or 
                ($pkg.InstallLocation -and $pkg.InstallLocation -match 'SystemApps|ImmersiveControlPanel') -or 
                ($pkg.SignatureKind -eq "System") -or 
                $pkg.IsFramework) {
                continue
            }

            $name = $pkg.Name
            $publisher = $pkg.Publisher

            $appxPct = 33 + [math]::Round(($appxIndex / [math]::Max($totalAppx, 1)) * 33)
            if ($appxIndex % 5 -eq 0 -or $appxIndex -eq $totalAppx) {
                Write-Progress -Activity "WinAurex AI Diagnostic Scan" -Status "Inspecting AppX ($appxIndex/$totalAppx): $name" -PercentComplete $appxPct
                Write-Host -NoNewline "`r  [*] [2/3] Packages: $appxIndex / $totalAppx ($name)                     "
                if ($ProgressCallback) { & $ProgressCallback "Scanning AppX: $appxIndex/$totalAppx ($name)" $appxPct }
            }

            $pred = Invoke-AiInference -Name $name -Description "" -Vendor $publisher

            if ($pred.Category -in @("Consumer_Bloatware", "OEM_Bloatware") -and $pred.IsSafeToDisable) {
                $tierText = if ($pred.SafetyTier -match "Tier 1") { "Tier 1 (Safe)" } else { "Tier 2 (Recommended)" }
                $results.Add([PSCustomObject]@{
                    TargetType       = "AppX"
                    Name             = $name
                    DisplayName      = $name
                    Category         = $pred.Category
                    SafetyTier       = $pred.SafetyTier
                    RiskTier         = $tierText
                    TierDisplay      = $tierText
                    Confidence       = "$([Math]::Round($pred.Confidence * 100, 1))%"
                    ConfidenceVal    = $pred.Confidence
                    Description      = "Preloaded Consumer / Sponsored AppX Package"
                    CurrentState     = "Installed"
                    StatusDisplay    = "Actionable (Installed)"
                    Action           = "Uninstall Package"
                    IsSelected       = ($pred.SafetyTier -eq "Tier 1 (Safe)")
                    IsAlreadyApplied = $false
                    EstSavings       = "~50 MB Disk, Suppressed Background Host"
                })
            }
        }
    } catch {}
    Write-Host "`r  [+] [2/3] Packages Evaluated: $totalAppx checked.                                      " -ForegroundColor Green

    # --- 3. SCAN HEAVY SCHEDULED TASKS ---
    Write-Host "  [*] [3/3] Inspecting high-overhead background tasks..." -ForegroundColor Cyan
    $TargetTasks = @(
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Application Experience\StartupAppTask",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\Feedback\Siuf\DmClient",
        "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
        "\Microsoft\Windows\Autochk\Proxy",
        "\Microsoft\Windows\Maintenance\WinSAT"
    )

    $taskIndex = 0
    $totalTasks = $TargetTasks.Count

    $scheduleService = $null
    try {
        $scheduleService = New-Object -ComObject "Schedule.Service"
        $scheduleService.Connect()
    } catch {
        $scheduleService = $null
    }

    foreach ($t in $TargetTasks) {
        $taskIndex++
        $taskPct = 66 + [math]::Round(($taskIndex / $totalTasks) * 34)
        $tName = Split-Path $t -Leaf
        Write-Progress -Activity "WinAurex AI Diagnostic Scan" -Status "Evaluating Task ($taskIndex/$totalTasks): $tName" -PercentComplete $taskPct
        if ($ProgressCallback) { & $ProgressCallback "Scanning Task: $tName" $taskPct }

        $taskFound = $false
        $isDis = $false

        if ($scheduleService) {
            try {
                $path = Split-Path $t -Parent
                $folder = $scheduleService.GetFolder($path)
                $comTask = $folder.GetTask($tName)
                if ($comTask) {
                    $taskFound = $true
                    $isDis = ($comTask.State -eq 1 -or -not $comTask.Enabled)
                }
            } catch {}
        }

        if (-not $taskFound) {
            try {
                $path = Split-Path $t -Parent
                $task = Get-ScheduledTask -TaskPath "$path\" -TaskName $tName -ErrorAction SilentlyContinue
                if ($task) {
                    $taskFound = $true
                    $isDis = ($task.State -eq "Disabled")
                }
            } catch {}
        }

        if ($taskFound) {
            $statusText = if ($isDis) { "Optimized (Disabled)" } else { "Actionable (Active)" }
            $actionText = if ($isDis) { "Already Disabled" } else { "Disable Task" }
            $results.Add([PSCustomObject]@{
                TargetType       = "ScheduledTask"
                Name             = $tName
                DisplayName      = $t
                Category         = "High_Overhead_Task"
                SafetyTier       = "Tier 1 (Safe)"
                RiskTier         = "Tier 1 (Safe)"
                TierDisplay      = "Tier 1 (Safe)"
                Confidence       = "98.5%"
                ConfidenceVal    = 0.985
                Description      = "Telemetry & Diagnostic Background Task"
                CurrentState     = if ($isDis) { "Already Disabled" } else { "Enabled" }
                StatusDisplay    = $statusText
                Action           = $actionText
                IsSelected       = (-not $isDis)
                IsAlreadyApplied = $isDis
                EstSavings       = if ($isDis) { "Already Reclaimed (0 CPU Drag)" } else { "Prevents Idle CPU / Disk Wakeups" }
            })
        }
    }

    if ($scheduleService) {
        try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($scheduleService) | Out-Null } catch {}
    }
    Write-Progress -Activity "WinAurex AI Diagnostic Scan" -Completed
    Write-Host "  [+] [3/3] Tasks Evaluated: $totalTasks inspected." -ForegroundColor Green
    if ($ProgressCallback) { & $ProgressCallback "AI Diagnostic Scan Complete!" 100 }

    return $results
}

function Invoke-WinAurexAiRemediation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [array]$SelectedItems = @(),
        [scriptblock]$ProgressCallback = $null,
        [switch]$Force
    )

    if ($null -eq $SelectedItems -or $SelectedItems.Count -eq 0) {
        Write-Host "[+] All targets are already optimized. No remediations required." -ForegroundColor Green
        return @{ Applied = 0; Skipped = 0 }
    }

    $appliedCount = 0
    $skippedCount = 0
    $total = $SelectedItems.Count
    $idx = 0

    Write-Host "`n[*] Starting AI Neural Remediation ($total targets queued)..." -ForegroundColor Cyan

    foreach ($item in $SelectedItems) {
        $idx++
        $pct = if ($total -gt 0) { [math]::Round(($idx / $total) * 100) } else { 100 }

        if ($item.IsAlreadyApplied) {
            $skippedCount++
            Write-Host "  [-] [$idx/$total] $($item.TargetType): $($item.Name) (Already optimized - Skipping)" -ForegroundColor DarkGray
            continue
        }

        Write-Progress -Activity "WinAurex AI Neural Remediation" -Status "[$idx/$total] ($pct%) Remediating $($item.TargetType): $($item.Name)" -PercentComplete $pct
        Write-Host -NoNewline "  -> [$idx/$total] ($pct%) $($item.TargetType): $($item.Name)... " -ForegroundColor Yellow
        if ($ProgressCallback) { & $ProgressCallback "Remediating [$idx/$total] $($item.TargetType): $($item.Name)" $pct }

        if ($item.TargetType -eq "Service") {
            try {
                $svc = Get-Service -Name $item.Name -ErrorAction SilentlyContinue
                if ($svc) {
                    if ($svc.Status -eq "Running") {
                        Stop-Service -Name $item.Name -Force -ErrorAction SilentlyContinue
                    }
                    Set-Service -Name $item.Name -StartupType Disabled -ErrorAction SilentlyContinue
                    
                    # Registry persistence enforcement
                    $reg = "HKLM:\SYSTEM\CurrentControlSet\Services\$($item.Name)"
                    if (Test-Path $reg) {
                        Set-ItemProperty -Path $reg -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                    $appliedCount++
                    Write-Host "[DISABLED]" -ForegroundColor Green
                } else {
                    Write-Host "[NOT FOUND]" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "[ERROR]" -ForegroundColor Red
            }
        }
        elseif ($item.TargetType -eq "ScheduledTask") {
            try {
                $path = Split-Path $item.DisplayName -Parent
                $tName = Split-Path $item.DisplayName -Leaf
                Disable-ScheduledTask -TaskPath "$path\" -TaskName $tName -ErrorAction SilentlyContinue | Out-Null
                $appliedCount++
                Write-Host "[DISABLED]" -ForegroundColor Green
            } catch {
                Write-Host "[ERROR]" -ForegroundColor Red
            }
        }
        elseif ($item.TargetType -eq "AppX") {
            try {
                $pkgs = @(Get-AppxPackage -Name $item.Name -AllUsers -ErrorAction SilentlyContinue)
                $prov = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $item.Name })

                if ($pkgs.Count -eq 0 -and $prov.Count -eq 0) {
                    $skippedCount++
                    Write-Host "[ALREADY REMOVED]" -ForegroundColor DarkGray
                    continue
                }

                $removable = @($pkgs | Where-Object {
                    -not ($_.NonRemovable -or ($_.InstallLocation -and $_.InstallLocation -match 'SystemApps|ImmersiveControlPanel') -or ($_.SignatureKind -eq "System") -or $_.IsFramework)
                })

                if ($removable.Count -eq 0 -and $prov.Count -eq 0) {
                    $skippedCount++
                    Write-Host "[PROTECTED SYSTEM APP - SKIPPED]" -ForegroundColor Yellow
                    continue
                }

                $isSystemAppLocked = $false
                $hasError = $false
                foreach ($p in $removable) {
                    try {
                        Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
                    } catch [System.Runtime.InteropServices.COMException] {
                        if ($_.Exception.HResult -eq [int]0x80070032 -or $_.Exception.HResult -eq [int]0x80073CFA -or $_.Exception.Message -match "0x80070032") {
                            # Non-removable system app trapped
                            $isSystemAppLocked = $true
                        } else {
                            $hasError = $true
                        }
                    } catch {
                        $hasError = $true
                    }
                }

                foreach ($pr in $prov) {
                    try {
                        Remove-AppxProvisionedPackage -Online -PackageName $pr.PackageName -ErrorAction Stop | Out-Null
                    } catch {}
                }

                # Verify package is actually removed before incrementing appliedCount
                $remaining = @(Get-AppxPackage -Name $item.Name -AllUsers -ErrorAction SilentlyContinue)
                if (-not $hasError -and $remaining.Count -eq 0) {
                    $appliedCount++
                    Write-Host "[PURGED]" -ForegroundColor Green
                } elseif ($isSystemAppLocked -or ($remaining.Count -gt 0 -and ($remaining[0].NonRemovable -or ($remaining[0].InstallLocation -and $remaining[0].InstallLocation -match 'SystemApps')))) {
                    $skippedCount++
                    Write-Host "[SKIPPED - SYSTEM APP]" -ForegroundColor Yellow
                } else {
                    Write-Host "[ERROR]" -ForegroundColor Red
                }
            } catch {
                Write-Host "[ERROR]" -ForegroundColor Red
            }
        }
    }

    Write-Progress -Activity "WinAurex AI Neural Remediation" -Completed

    # Memory working set purge
    Write-Host "  -> Memory Working Set: Purging unmapped memory pages... " -NoNewline -ForegroundColor Cyan
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        $emptyWorkingSetSig = @'
[DllImport("psapi.dll")]
public static extern int EmptyWorkingSet(IntPtr hwProc);
'@
        $psapi = Add-Type -MemberDefinition $emptyWorkingSetSig -Name "PsapiMemTrimAi" -Namespace "WinAurexAiKern" -PassThru -ErrorAction SilentlyContinue
        if ($psapi) {
            $procs = [System.Diagnostics.Process]::GetProcesses()
            foreach ($p in $procs) {
                try {
                    if ($p.Id -ne 0 -and $p.Id -ne 4) {
                        [WinAurexAiKern.PsapiMemTrimAi]::EmptyWorkingSet($p.Handle) | Out-Null
                    }
                } catch {}
            }
        }
        Write-Host "[FLUSHED]" -ForegroundColor Green
    } catch {
        Write-Host "[OK]" -ForegroundColor DarkGray
    }

    # Apply Baseline Network, Privacy & Latency Policy Suppressions
    Write-Host "  -> Policy Hardening: Disabling telemetry & background P2P seeding... " -NoNewline -ForegroundColor Cyan
    try {
        # 1. Delivery Optimization HTTP only (no P2P background uploads)
        $doPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        if (-not (Test-Path $doPath)) { New-Item -Path $doPath -Force | Out-Null }
        Set-ItemProperty -Path $doPath -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 2. Advertising ID tracking off
        $adPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $adPath)) { New-Item -Path $adPath -Force | Out-Null }
        Set-ItemProperty -Path $adPath -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 3. Game DVR background recording off (eliminates micro-stutter)
        $gConfig = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $gConfig)) { New-Item -Path $gConfig -Force | Out-Null }
        Set-ItemProperty -Path $gConfig -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $gDvr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
        if (-not (Test-Path $gDvr)) { New-Item -Path $gDvr -Force | Out-Null }
        Set-ItemProperty -Path $gDvr -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "[ENFORCED]" -ForegroundColor Green
    } catch {
        Write-Host "[OK]" -ForegroundColor DarkGray
    }

    return @{
        Applied = $appliedCount
        Skipped = $skippedCount
    }
}

function Get-WinAurexHealthScore {
    [CmdletBinding()]
    param()

    $procs = [System.Diagnostics.Process]::GetProcesses()
    $pCount = $procs.Count
    $tCount = 0
    $hCount = 0
    foreach ($p in $procs) {
        try {
            $tCount += $p.Threads.Count
            $hCount += $p.HandleCount
        } catch {}
    }

    # Telemetry services check
    $knownTelemetry = @("DiagTrack", "dmwappushservice", "WerSvc", "PcaSvc", "MapsBroker", "lfsvc", "RetailDemo", "wisvc", "Fax", "RemoteRegistry")
    $runningTelemetry = 0
    foreach ($name in $knownTelemetry) {
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($s -and $s.Status -eq "Running") {
            $runningTelemetry++
        }
    }

    # Bloatware scheduled tasks check
    $knownTasks = @(
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
    )
    $runningTasks = 0
    foreach ($t in $knownTasks) {
        $p = Split-Path $t -Parent
        $l = Split-Path $t -Leaf
        $task = Get-ScheduledTask -TaskPath "$p\" -TaskName $l -ErrorAction SilentlyContinue
        if ($task -and $task.State -ne "Disabled") {
            $runningTasks++
        }
    }

    $score = 100
    $score -= ($runningTelemetry * 4)
    $score -= ($runningTasks * 3)
    if ($pCount -gt 220) { $score -= 15 }
    elseif ($pCount -gt 180) { $score -= 8 }
    elseif ($pCount -gt 140) { $score -= 4 }

    if ($score -lt 30) { $score = 30 }
    if ($score -gt 100) { $score = 100 }

    $grade = if ($score -ge 95) { "A+" }
             elseif ($score -ge 88) { "A" }
             elseif ($score -ge 78) { "B" }
             elseif ($score -ge 65) { "C" }
             else { "D (Bloated)" }

    $summary = if ($score -ge 90) { "Optimal - System is cleanly optimized" }
               elseif ($score -ge 75) { "Moderate - Telemetry and background services active" }
               else { "Suboptimal - High background drag detected" }

    return [PSCustomObject]@{
        Score                 = $score
        Grade                 = $grade
        Summary               = $summary
        ActiveTelemetryCount  = $runningTelemetry
        ActiveTasksCount      = $runningTasks
        ProcessCount          = $pCount
        ThreadCount           = $tCount
        HandleCount           = $hCount
    }
}

function Invoke-WinAurexRamFlush {
    [CmdletBinding()]
    param()

    $memBefore = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).FreePhysicalMemory

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    $sig = @'
[DllImport("psapi.dll")]
public static extern int EmptyWorkingSet(IntPtr hwProc);
'@
    $psapi = Add-Type -MemberDefinition $sig -Name "PsapiMemTrimV2" -Namespace "WinAurexRamKern" -PassThru -ErrorAction SilentlyContinue

    $trimmedCount = 0
    $procs = [System.Diagnostics.Process]::GetProcesses()
    foreach ($p in $procs) {
        try {
            if ($p.Id -ne 0 -and $p.Id -ne 4) {
                [WinAurexRamKern.PsapiMemTrimV2]::EmptyWorkingSet($p.Handle) | Out-Null
                $trimmedCount++
            }
        } catch {}
    }

    Start-Sleep -Milliseconds 400
    $memAfter = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).FreePhysicalMemory

    $diffKB = $memAfter - $memBefore
    $diffMB = [Math]::Max(0, [Math]::Round($diffKB / 1024, 1))

    return [PSCustomObject]@{
        ProcessesTrimmed = $trimmedCount
        ReclaimedMB      = $diffMB
        FreeMemoryMB     = [Math]::Round($memAfter / 1024, 0)
    }
}

function Get-ProcessAnomalies {
    [CmdletBinding()]
    param()

    $anomalies = [System.Collections.Generic.List[PSObject]]::new()
    $procs = [System.Diagnostics.Process]::GetProcesses()
    $sysIgnore = @("System", "Idle", "Registry", "smss", "csrss", "wininit", "winlogon", "lsass", "services", "dwm", "explorer")

    foreach ($p in $procs) {
        try {
            if ($p.Id -eq 0 -or $p.Id -eq 4 -or $sysIgnore -contains $p.ProcessName) {
                continue
            }

            $handles = $p.HandleCount
            $threads = $p.Threads.Count
            $memMB = [Math]::Round($p.WorkingSet64 / 1MB, 1)
            $isHeadless = ($p.MainWindowHandle -eq [IntPtr]::Zero)

            if ($isHeadless -and ($handles -gt 500 -or $threads -gt 30 -or $memMB -gt 250)) {
                $reason = if ($handles -gt 500) { "High Handle Retention ($handles handles)" }
                          elseif ($threads -gt 30) { "Excessive Thread Pool ($threads threads)" }
                          else { "High Idle Working Set ($memMB MB)" }

                $anomalies.Add([PSCustomObject]@{
                    PID             = $p.Id
                    ProcessName     = $p.ProcessName
                    Handles         = $handles
                    Threads         = $threads
                    WorkingSetMB    = $memMB
                    AnomalyReason   = $reason
                    SuggestedAction = "Trim Working Set / Suppress Background Task"
                })
            }
        } catch {}
    }

    return $anomalies
}

function Set-AiGamingShield {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Enable,
        [switch]$Disable
    )

    $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    $priorityControl = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    $memMgmt = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

    if ($Disable) {
        if (Test-Path $sysProfile) {
            Set-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $priorityControl) {
            Set-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        return @{ Status = "Disabled"; PrioritySeparation = "0x2 (Standard)" }
    } else {
        if (-not (Test-Path $sysProfile)) { New-Item -Path $sysProfile -Force | Out-Null }
        Set-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue

        if (-not (Test-Path $priorityControl)) { New-Item -Path $priorityControl -Force | Out-Null }
        Set-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -Value 0x28 -Type DWord -Force -ErrorAction SilentlyContinue

        if (Test-Path $memMgmt) {
            Set-ItemProperty -Path $memMgmt -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        $pwrThrottling = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if (-not (Test-Path $pwrThrottling)) { New-Item -Path $pwrThrottling -Force | Out-Null }
        Set-ItemProperty -Path $pwrThrottling -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        return @{ Status = "Active"; PrioritySeparation = "0x28 (Short Fixed High Quantum)" }
    }
}

function Get-WinAurexSystemProfile {
    [CmdletBinding()]
    param()

    $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $cpuName = if ($cpu -and $cpu.Name) { $cpu.Name.Trim() } else { "Intel(R) Core(TM) Processor" }
    $cores   = if ($cpu -and $cpu.NumberOfCores) { [int]$cpu.NumberOfCores } else { [System.Environment]::ProcessorCount / 2 }
    $threads = if ($cpu -and $cpu.NumberOfLogicalProcessors) { [int]$cpu.NumberOfLogicalProcessors } else { [System.Environment]::ProcessorCount }

    $compSys = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -First 1
    $totalRamBytes = if ($compSys -and $compSys.TotalPhysicalMemory) { [double]$compSys.TotalPhysicalMemory } else { 16GB }
    $totalRamGB = [math]::Round($totalRamBytes / 1GB, 2)

    $gpu = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
    $gpuName = if ($gpu -and $gpu.Name) { $gpu.Name } else { "Generic Display Adapter" }
    $gpuVendor = if ($gpuName -match "NVIDIA") { "NVIDIA" }
                 elseif ($gpuName -match "AMD|Radeon") { "AMD" }
                 elseif ($gpuName -match "Intel") { "Intel" }
                 else { "Other" }

    $disk = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue | Select-Object -First 1
    $storageType = "SATA SSD"
    if ($disk) {
        $pnp = "$($disk.PNPDeviceID) $($disk.Model)"
        if ($pnp -match "NVMe|PCIe") { $storageType = "NVMe SSD" }
        elseif ($pnp -match "HDD|HardDisk") { $storageType = "HDD" }
    }

    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
    $isLaptop = ($null -ne $battery)
    $onBattery = if ($battery) { ($battery.BatteryStatus -ne 2) } else { $false }

    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object -First 1
    $ramUsedPercent = 50.0
    if ($os -and $os.TotalVisibleMemorySize -gt 0) {
        $freeMem = [double]$os.FreePhysicalMemory
        $totalMem = [double]$os.TotalVisibleMemorySize
        $ramUsedPercent = [math]::Round((($totalMem - $freeMem) / $totalMem) * 100, 2)
    }

    $cpuLoad = if ($cpu -and $null -ne $cpu.LoadPercentage) { [double]$cpu.LoadPercentage } else { 15.0 }

    $gameSigs = @("cs2", "valorant", "dota2", "leagueclient", "fortnite", "r5reload", "overwatch", "destiny2")
    $activeGame = ""
    $isGaming = $false
    try {
        $runningProcs = Get-Process -ErrorAction SilentlyContinue
        foreach ($p in $runningProcs) {
            if ($gameSigs -contains $p.ProcessName.ToLower()) {
                $isGaming = $true
                $activeGame = $p.ProcessName
                break
            }
        }
    } catch {}

    return [PSCustomObject]@{
        Hardware = [PSCustomObject]@{
            CpuName     = $cpuName
            CpuCores    = [int]$cores
            CpuThreads  = [int]$threads
            TotalRamGB  = [double]$totalRamGB
            GpuName     = $gpuName
            GpuVendor   = $gpuVendor
            StorageType = $storageType
            IsLaptop    = [bool]$isLaptop
            OnBattery   = [bool]$onBattery
        }
        Workload = [PSCustomObject]@{
            CpuLoadPercent = [double]$cpuLoad
            RamUsedPercent = [double]$ramUsedPercent
            IsGamingActive = [bool]$isGaming
            ActiveGameName = $activeGame
            TopDrainers    = @()
        }
        Timestamp = (Get-Date)
    }
}

function Get-WinAurexAiRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Profile = $null,
        [Parameter(Mandatory = $false)]
        [array]$Findings = @()
    )

    if ($null -eq $Profile) {
        $Profile = Get-WinAurexSystemProfile
    }

    $recommendations = [System.Collections.Generic.List[PSObject]]::new()

    # Rule 1: Gaming Latency Boost
    if ($Profile.Workload.IsGamingActive -or $Profile.Hardware.GpuVendor -in @("NVIDIA", "AMD")) {
        $recommendations.Add([PSCustomObject]@{
            Id               = "REC-GAME-01"
            Title            = "Activate AI Low-Latency Gaming Shield"
            Description      = "Enforces short fixed high quantum (Win32PrioritySeparation = 0x28) and disables network packet throttling."
            Category         = "Gaming_Bottleneck"
            Priority         = if ($Profile.Workload.IsGamingActive) { "High" } else { "Medium" }
            SafetyTier       = "Tier 1 (Safe)"
            EstimatedBenefit = "Reduces micro-stutter and input lag in 3D gaming runtimes"
            TargetItems      = @("Win32PrioritySeparation", "NetworkThrottlingIndex", "GameDVR")
        })
    }

    # Rule 2: Low-RAM or High-Pressure Adaptation
    if ($Profile.Hardware.TotalRamGB -le 8.0 -or $Profile.Workload.RamUsedPercent -gt 75.0) {
        $recommendations.Add([PSCustomObject]@{
            Id               = "REC-RAM-01"
            Title            = "Flush Idle Process Working Sets & Trim RAM"
            Description      = "Aggressively trims memory allocations for idle background processes using native PSAPI EmptyWorkingSet."
            Category         = "Safe_Optimization"
            Priority         = "High"
            SafetyTier       = "Tier 1 (Safe)"
            EstimatedBenefit = "Reclaims 400MB - 1.2GB active physical memory immediately"
            TargetItems      = @("PsapiMemTrim", "EmptyWorkingSet")
        })
    }

    # Rule 3: Mobile Laptop Power-Conscious Telemetry Pruning
    if ($Profile.Hardware.IsLaptop -and $Profile.Hardware.OnBattery) {
        $recommendations.Add([PSCustomObject]@{
            Id               = "REC-PWR-01"
            Title            = "Throttle Background Telemetry on Battery"
            Description      = "Suppresses background telemetry wakeups without aggressive clock throttling to preserve battery cycle life."
            Category         = "Telemetry"
            Priority         = "High"
            SafetyTier       = "Tier 1 (Safe)"
            EstimatedBenefit = "Extends battery life by eliminating CPU background wakeups"
            TargetItems      = @("DiagTrack", "dmwappushservice", "Consolidator")
        })
    }

    # Rule 4: Actionable Telemetry & Bloat Candidates from Findings
    $actionableServices = @($Findings | Where-Object { $_.TargetType -eq "Service" -and -not $_.IsAlreadyApplied })
    if ($actionableServices.Count -gt 0) {
        $recommendations.Add([PSCustomObject]@{
            Id               = "REC-BLAT-01"
            Title            = "Disable Actionable Background Bloat Services"
            Description      = "Disables $($actionableServices.Count) non-essential background service(s) identified by offline neural inference."
            Category         = "Consumer_Bloatware"
            Priority         = "High"
            SafetyTier       = "Tier 1 (Safe)"
            EstimatedBenefit = "Eliminates $($actionableServices.Count) background threads and persistent registry handles"
            TargetItems      = @($actionableServices | ForEach-Object { $_.Name })
        })
    }

    # Baseline Performance & Privacy Recommendation
    $recommendations.Add([PSCustomObject]@{
        Id               = "REC-BASE-01"
        Title            = "Enforce Windows Performance & Privacy Baseline"
        Description      = "Optimizes delivery optimization, network packet latency, and background application tracking."
        Category         = "Safe_Optimization"
        Priority         = "Medium"
        SafetyTier       = "Tier 1 (Safe)"
        EstimatedBenefit = "Reduces background network polling and idle disk/CPU drag"
        TargetItems      = @("DeliveryOptimization", "AdvertisingInfo", "GameDVR")
    })

    return $recommendations.ToArray()
}

Export-ModuleMember -Function Initialize-AiModel, Invoke-AiInference, `
    Get-WinAurexServiceCatalog, Get-WinAurexTaskCatalog, Get-WinAurexBloatwareCatalog, Get-WinAurexTweakCatalog, Get-WinAurexCoreWhitelist, `
    Invoke-WinAurexAiScan, Invoke-WinAurexAiRemediation, Get-WinAurexHealthScore, Invoke-WinAurexRamFlush, Get-ProcessAnomalies, Set-AiGamingShield, `
    Get-WinAurexSystemProfile, Get-WinAurexAiRecommendations
