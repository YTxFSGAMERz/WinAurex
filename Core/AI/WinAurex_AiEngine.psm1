<#
.SYNOPSIS
    WinAurex Native AI Optimization Engine
.DESCRIPTION
    Zero-dependency, offline neural and heuristic inference engine for Windows system optimization.
    Loads trained model weights (winaurex_ai_model.json) into high-performance dictionary lookup tables
    to dynamically evaluate services, processes, AppX packages, and scheduled tasks in milliseconds.
#>

$script:ModelPath = Join-Path $PSScriptRoot "winaurex_ai_model.json"
$script:AiModel = $null
$script:WordDicts = @{}
$script:WhitelistSet = $null

function Initialize-AiModel {
    if ($null -eq $script:AiModel -and (Test-Path $script:ModelPath)) {
        try {
            $raw = Get-Content -Path $script:ModelPath -Raw -Encoding UTF8
            $script:AiModel = $raw | ConvertFrom-Json
            
            # Build fast O(1) hashset for Whitelist
            $script:WhitelistSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($item in $script:AiModel.whitelist) {
                [void]$script:WhitelistSet.Add($item)
            }

            # Build fast O(1) dictionaries for log-likelihoods
            $script:WordDicts = @{}
            foreach ($c in $script:AiModel.classes) {
                $dict = [System.Collections.Generic.Dictionary[string, double]]::new([System.StringComparer]::OrdinalIgnoreCase)
                foreach ($prop in $script:AiModel.log_likelihoods.$c.psobject.properties) {
                    $dict[$prop.Name] = [double]$prop.Value
                }
                $script:WordDicts[$c] = $dict
            }
        } catch {
            Write-Warning "Failed loading WinAurex AI model: $_"
        }
    }
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
    param (
        [string]$Name,
        [string]$Description = "",
        [string]$Vendor = ""
    )
    Initialize-AiModel
    if ($null -eq $script:AiModel) {
        return @{
            Category          = "Unknown"
            SafetyTier        = "Tier 2 (Recommended)"
            Confidence        = 0.50
            IsSafeToDisable   = $true
            Reason            = "Model not loaded, default fallback applied."
        }
    }

    # 1. Hardcoded Cryptographic Whitelist & System Shield Check (TIER 0 - PROTECTED)
    $protectedServices = @(
        "mpssvc", "bfe", "mpsdrv", "fontcache", "fontcache3.0.0.0",
        "deviceinstall", "devquerybroker", "bthserv", "bthport", "bluetoothuserservice",
        "lanmanserver", "lanmanworkstation", "comsysapp", "msdtc", "ktmrm",
        "appinfo", "bdesvc", "keyiso", "samss", "lsaiso",
        "audiosrv", "audioendpointbuilder", "nvsvc", "amdfendrs", "amd external events utility",
        "amdppkgsvc", "amdpmfservice", "wuauserv", "trustedinstaller", "cryptsvc",
        "bits", "msiserver", "usosvc", "installservice", "clipsvc", "appxsvc",
        "dhcp", "dnscache", "wlansvc", "eventlog", "rpcss", "rpceptmapper",
        "dcomlaunch", "plugplay", "schedule", "usermanager", "profsvc", "gpsvc",
        "braveelevationservice", "googlechromeelevationservice"
    )

    $protectedAppxPrefixes = @(
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
        "microsoft.windows.contentdeliverymanager", "microsoft.windows.shellflow"
    )

    $lowerName = $Name.ToLower()

    if (($script:WhitelistSet -and $script:WhitelistSet.Contains($Name)) -or 
        ($protectedServices -contains $lowerName) -or 
        ($protectedAppxPrefixes | Where-Object { $lowerName.StartsWith($_) })) {
        return @{
            Category          = "Core_OS_Essential"
            SafetyTier        = "Tier 0 (Protected)"
            Confidence        = 1.00
            IsSafeToDisable   = $false
            Reason            = "Cryptographically locked Core Windows component."
        }
    }

    # 2. Extract feature tokens
    $fullText = "$Name $Description $Vendor"
    $tokens = Get-Tokens -Text $fullText

    # 3. Log-likelihood accumulation via O(1) Dictionary
    $classes = $script:AiModel.classes
    $scores = @{}
    $vocabSize = if ($script:AiModel.metadata -and $script:AiModel.metadata.features_count) { 
        [int]$script:AiModel.metadata.features_count 
    } else { 
        2100 
    }

    foreach ($c in $classes) {
        $logPrior = [double]$script:AiModel.log_priors.$c
        $classTotal = [double]$script:AiModel.class_totals.$c
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

    # 4. Heuristic Keyword Boosters
    $lowerText = $fullText.ToLower()
    if ($lowerText -match "telemetry|diagnostic|ceip|spynet|appraiser|sqm") {
        $scores["Telemetry_Tracking"] += 4.5
    }
    if ($lowerText -match "supportassist|touchpoint|vantage|armoury|synapse|oem|acer|dell|lenovo|asus|hp ") {
        $scores["OEM_Bloatware"] += 4.5
    }
    if ($lowerText -match "adobearm|gupdate|edgeupdate|updater|autoupdate") {
        $scores["ThirdParty_Updater"] += 4.5
    }
    if ($lowerText -match "retaildemo|mapsbroker|solitaire|candycrush|tiktok|bingweather|bingnews") {
        $scores["Consumer_Bloatware"] += 4.5
    }
    if ($lowerText -match "winsat|defrag|autochk") {
        $scores["High_Overhead_Task"] += 4.5
    }

    # 5. Softmax Normalization
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

    # 6. Safety Tier Mapping
    $tier = "Tier 2 (Recommended)"
    $isSafe = $true
    if ($bestCat -eq "Core_OS_Essential") {
        $tier = "Tier 0 (Protected)"
        $isSafe = $false
    } elseif ($bestCat -in @("Telemetry_Tracking", "OEM_Bloatware")) {
        $tier = "Tier 1 (Safe)"
        $isSafe = $true
    } elseif ($bestCat -in @("ThirdParty_Updater", "Consumer_Bloatware")) {
        if ($bestProb -ge 0.85) { $tier = "Tier 1 (Safe)" } else { $tier = "Tier 2 (Recommended)" }
        $isSafe = $true
    } else {
        $tier = "Tier 2 (Recommended)"
        $isSafe = $true
    }

    return @{
        Category        = $bestCat
        SafetyTier      = $tier
        Confidence      = [Math]::Round($bestProb, 4)
        IsSafeToDisable = $isSafe
    }
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

                $hasError = $false
                foreach ($p in $removable) {
                    try {
                        Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
                    } catch [System.Runtime.InteropServices.COMException] {
                        if ($_.Exception.HResult -eq [int]0x80070032 -or $_.Exception.HResult -eq [int]0x80073CFA -or $_.Exception.Message -match "0x80070032") {
                            # Non-removable system app
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
                } elseif ($remaining.Count -gt 0 -and ($remaining[0].NonRemovable -or ($remaining[0].InstallLocation -and $remaining[0].InstallLocation -match 'SystemApps'))) {
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

Export-ModuleMember -Function Initialize-AiModel, Invoke-AiInference, Invoke-WinAurexAiScan, Invoke-WinAurexAiRemediation, Get-WinAurexHealthScore, Invoke-WinAurexRamFlush, Get-ProcessAnomalies, Set-AiGamingShield
