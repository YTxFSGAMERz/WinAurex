<#
.SYNOPSIS
    WinAurex AI E2E Test Harness & Standalone Assertion Engine
.DESCRIPTION
    Comprehensive test infrastructure module providing mock fixtures, simulated
    hardware/workload profile builders, domain contract assertions, and a portable,
    zero-dependency assertion engine (Describe, Context, It, Should) that executes
    seamlessly in any PowerShell environment (with or without Pester).
#>

# ==============================================================================
# 1. STANDALONE ASSERTION ENGINE STATE & RUNNER
# ==============================================================================

$script:CurrentTestContext = @{
    Total     = 0
    Passed    = 0
    Failed    = 0
    Skipped   = 0
    Failures  = [System.Collections.Generic.List[PSObject]]::new()
    StartTime = [datetime]::UtcNow
}

$script:CurrentDescribe    = ""
$script:CurrentContext     = ""
$script:CurrentBeforeEach  = $null
$script:CurrentAfterEach   = $null

function Reset-TestResults {
    [CmdletBinding()]
    param()
    $script:CurrentTestContext = @{
        Total     = 0
        Passed    = 0
        Failed    = 0
        Skipped   = 0
        Failures  = [System.Collections.Generic.List[PSObject]]::new()
        StartTime = [datetime]::UtcNow
    }
    $script:CurrentDescribe   = ""
    $script:CurrentContext    = ""
    $script:CurrentBeforeEach = $null
    $script:CurrentAfterEach  = $null
}

function Get-TestResultSummary {
    [CmdletBinding()]
    param()
    $duration = [datetime]::UtcNow - $script:CurrentTestContext.StartTime
    return [PSCustomObject]@{
        Total      = $script:CurrentTestContext.Total
        Passed     = $script:CurrentTestContext.Passed
        Failed     = $script:CurrentTestContext.Failed
        Skipped    = $script:CurrentTestContext.Skipped
        Failures   = @($script:CurrentTestContext.Failures)
        Duration   = $duration
        Success    = ($script:CurrentTestContext.Failed -eq 0 -and $script:CurrentTestContext.Total -gt 0)
        PassRate   = if ($script:CurrentTestContext.Total -gt 0) {
            [math]::Round(($script:CurrentTestContext.Passed / $script:CurrentTestContext.Total) * 100, 2)
        } else { 0.0 }
    }
}

function Describe {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Name,
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$Fixture
    )
    $prevDescribe = $script:CurrentDescribe
    $script:CurrentDescribe = $Name
    Write-Host "`n=== Describe: $Name ===" -ForegroundColor Cyan
    try {
        & $Fixture
    } finally {
        $script:CurrentDescribe = $prevDescribe
    }
}

function Context {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Name,
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$Fixture
    )
    $prevContext = $script:CurrentContext
    $script:CurrentContext = $Name
    Write-Host "`n  --- Context: $Name ---" -ForegroundColor Yellow
    try {
        & $Fixture
    } finally {
        $script:CurrentContext = $prevContext
    }
}

function BeforeAll {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][scriptblock]$Script)
    & $Script
}

function AfterAll {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][scriptblock]$Script)
    & $Script
}

function BeforeEach {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][scriptblock]$Script)
    $script:CurrentBeforeEach = $Script
}

function AfterEach {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][scriptblock]$Script)
    $script:CurrentAfterEach = $Script
}

function It {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Name,
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$Test
    )
    $script:CurrentTestContext.Total++

    # Execute BeforeEach if registered
    if ($null -ne $script:CurrentBeforeEach) {
        try { & $script:CurrentBeforeEach } catch {}
    }

    $pass = $false
    $errRecord = $null

    try {
        & $Test
        $pass = $true
    } catch {
        $errRecord = $_
    } finally {
        # Execute AfterEach if registered
        if ($null -ne $script:CurrentAfterEach) {
            try { & $script:CurrentAfterEach } catch {}
        }
    }

    if ($pass) {
        $script:CurrentTestContext.Passed++
        Write-Host "    [PASS] $Name" -ForegroundColor Green
    } else {
        $script:CurrentTestContext.Failed++
        $errMsg = if ($errRecord) { $errRecord.Exception.Message } else { "Unknown assertion failure" }
        $errPos = if ($errRecord -and $errRecord.InvocationInfo) { $errRecord.InvocationInfo.PositionMessage } else { "" }

        $script:CurrentTestContext.Failures.Add([PSCustomObject]@{
            Describe = $script:CurrentDescribe
            Context  = $script:CurrentContext
            Name     = $Name
            Error    = $errMsg
            Location = $errPos
        })

        Write-Host "    [FAIL] $Name" -ForegroundColor Red
        Write-Host "           $errMsg" -ForegroundColor DarkRed
        if ($errPos) {
            Write-Host "           $errPos" -ForegroundColor DarkGray
        }
    }
}

function Should {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Actual,

        [Parameter(Position = 0)]
        $Arg0,

        [Parameter(Position = 1)]
        $Arg1,

        [Parameter(Position = 2)]
        $Arg2,

        # Named switches for Pester compatibility
        [Parameter()]
        [switch]$Not,

        [Parameter()]
        $Be,

        [Parameter()]
        [switch]$BeTrue,

        [Parameter()]
        [switch]$BeFalse,

        [Parameter()]
        [switch]$BeNullOrEmpty,

        [Parameter()]
        $BeGreaterThan,

        [Parameter()]
        $BeLessThan,

        [Parameter()]
        $BeGreaterOrEqual,

        [Parameter()]
        $BeLessOrEqual,

        [Parameter()]
        $Match,

        [Parameter()]
        $Contain,

        [Parameter()]
        $BeOfType,

        [Parameter()]
        [switch]$Throw
    )

    begin {
        $pipelineItems = [System.Collections.Generic.List[object]]::new()
        $hasPipelineInput = $false
    }

    process {
        $hasPipelineInput = $true
        $pipelineItems.Add($Actual)
    }

    end {
        # Determine actual target value
        $resolvedActual = $null
        if ($hasPipelineInput) {
            if ($pipelineItems.Count -eq 0) {
                $resolvedActual = @()
            } elseif ($pipelineItems.Count -eq 1) {
                # If operator is contain and item is not array, array wrapper preserves collection semantics
                $resolvedActual = $pipelineItems[0]
            } else {
                $resolvedActual = $pipelineItems.ToArray()
            }
        } else {
            $resolvedActual = $Actual
        }

        # 1. Resolve Negation ($isNot)
        $isNot = $false
        if ($Not.IsPresent -or ($Arg0 -is [string] -and $Arg0 -eq "Not")) {
            $isNot = $true
        }

        # 2. Resolve Operator and Expected Value
        $op = ""
        $expected = $null

        if ($Arg0 -is [string] -and $Arg0 -eq "Not") {
            $op = [string]$Arg1
            $expected = $Arg2
        } elseif ($null -ne $Arg0) {
            $op = [string]$Arg0
            $expected = $Arg1
        }

        # Check named parameters if positional operator is unset
        if ([string]::IsNullOrEmpty($op)) {
            if ($PSBoundParameters.ContainsKey('Be')) { $op = "Be"; $expected = $Be }
            elseif ($BeTrue.IsPresent) { $op = "BeTrue" }
            elseif ($BeFalse.IsPresent) { $op = "BeFalse" }
            elseif ($BeNullOrEmpty.IsPresent) { $op = "BeNullOrEmpty" }
            elseif ($PSBoundParameters.ContainsKey('BeGreaterThan')) { $op = "BeGreaterThan"; $expected = $BeGreaterThan }
            elseif ($PSBoundParameters.ContainsKey('BeLessThan')) { $op = "BeLessThan"; $expected = $BeLessThan }
            elseif ($PSBoundParameters.ContainsKey('BeGreaterOrEqual')) { $op = "BeGreaterOrEqual"; $expected = $BeGreaterOrEqual }
            elseif ($PSBoundParameters.ContainsKey('BeLessOrEqual')) { $op = "BeLessOrEqual"; $expected = $BeLessOrEqual }
            elseif ($PSBoundParameters.ContainsKey('Match')) { $op = "Match"; $expected = $Match }
            elseif ($PSBoundParameters.ContainsKey('Contain')) { $op = "Contain"; $expected = $Contain }
            elseif ($PSBoundParameters.ContainsKey('BeOfType')) { $op = "BeOfType"; $expected = $BeOfType }
            elseif ($Throw.IsPresent) { $op = "Throw" }
        }

        # Normalize operator name
        $op = $op.TrimStart('-')

        # 3. Evaluate Assertion
        $passed = $false
        $reason = ""

        switch -Exact ($op.ToLowerInvariant()) {
            "be" {
                if ($null -eq $resolvedActual -and $null -eq $expected) {
                    $passed = $true
                } elseif ($null -eq $resolvedActual -or $null -eq $expected) {
                    $passed = $false
                } elseif ($resolvedActual -is [bool] -or $expected -is [bool]) {
                    $passed = ([bool]$resolvedActual -eq [bool]$expected)
                } elseif ($resolvedActual -is [int] -or $resolvedActual -is [double] -or $expected -is [int] -or $expected -is [double]) {
                    $passed = ([double]$resolvedActual -eq [double]$expected)
                } else {
                    $passed = ($resolvedActual -eq $expected)
                }
                $reason = "Expected: '$expected', Actual: '$resolvedActual'"
            }
            "beexactly" {
                $passed = ($resolvedActual -ceq $expected)
                $reason = "Expected exact match: '$expected', Actual: '$resolvedActual'"
            }
            "betrue" {
                $passed = ($resolvedActual -eq $true)
                $reason = "Expected: `$true, Actual: '$resolvedActual'"
            }
            "befalse" {
                $passed = ($resolvedActual -eq $false)
                $reason = "Expected: `$false, Actual: '$resolvedActual'"
            }
            "benullorempty" {
                if ($null -eq $resolvedActual) {
                    $passed = $true
                } elseif ($resolvedActual -is [string]) {
                    $passed = [string]::IsNullOrEmpty($resolvedActual)
                } elseif ($resolvedActual -is [System.Collections.ICollection]) {
                    $passed = ($resolvedActual.Count -eq 0)
                } elseif ($resolvedActual -is [System.Array]) {
                    $passed = ($resolvedActual.Length -eq 0)
                } else {
                    $passed = $false
                }
                $reason = "Expected Null or Empty, Actual: '$resolvedActual'"
            }
            "begreaterthan" {
                $passed = ($resolvedActual -gt $expected)
                $reason = "Expected > '$expected', Actual: '$resolvedActual'"
            }
            "belessthan" {
                $passed = ($resolvedActual -lt $expected)
                $reason = "Expected < '$expected', Actual: '$resolvedActual'"
            }
            "begreaterorequal" {
                $passed = ($resolvedActual -ge $expected)
                $reason = "Expected >= '$expected', Actual: '$resolvedActual'"
            }
            "begreaterthanorequal" {
                $passed = ($resolvedActual -ge $expected)
                $reason = "Expected >= '$expected', Actual: '$resolvedActual'"
            }
            "belessorequal" {
                $passed = ($resolvedActual -le $expected)
                $reason = "Expected <= '$expected', Actual: '$resolvedActual'"
            }
            "belessthanorequal" {
                $passed = ($resolvedActual -le $expected)
                $reason = "Expected <= '$expected', Actual: '$resolvedActual'"
            }
            "match" {
                if ($null -eq $resolvedActual) {
                    $passed = $false
                } else {
                    $passed = ([string]$resolvedActual -match [string]$expected)
                }
                $reason = "Expected regex match '$expected', Actual: '$resolvedActual'"
            }
            "contain" {
                if ($null -eq $resolvedActual) {
                    $passed = $false
                } elseif ($resolvedActual -is [string]) {
                    $passed = ([string]$resolvedActual).Contains([string]$expected)
                } elseif ($resolvedActual -is [System.Collections.IEnumerable]) {
                    $found = $false
                    foreach ($elem in $resolvedActual) {
                        if ($elem -eq $expected) { $found = $true; break }
                    }
                    $passed = $found
                } else {
                    $passed = ($resolvedActual -eq $expected -or $resolvedActual -contains $expected)
                }
                $reason = "Expected collection to contain '$expected', Actual count: $(if ($resolvedActual -is [System.Collections.ICollection]) { $resolvedActual.Count } else { 'scalar' })"
            }
            "beoftype" {
                if ($null -eq $resolvedActual) {
                    $passed = $false
                } else {
                    $typeName = if ($expected -is [type]) { $expected.Name } else { [string]$expected }
                    $passed = ($resolvedActual.GetType().Name -eq $typeName -or ($resolvedActual -is [type] -and $resolvedActual -is $expected))
                }
                $reason = "Expected type '$expected', Actual type: '$(if ($resolvedActual) { $resolvedActual.GetType().FullName } else { 'null' })'"
            }
            "throw" {
                $caught = $null
                if ($resolvedActual -is [scriptblock]) {
                    try {
                        & $resolvedActual | Out-Null
                    } catch {
                        $caught = $_
                    }
                }
                if ($null -ne $caught) {
                    if ($null -ne $expected -and [string]$expected -ne "") {
                        $passed = ($caught.Exception.Message -match [string]$expected -or $caught.Exception.GetType().Name -match [string]$expected)
                        $reason = "Expected exception matching '$expected', Caught: '$($caught.Exception.Message)'"
                    } else {
                        $passed = $true
                        $reason = "Expected exception thrown. Caught: '$($caught.Exception.Message)'"
                    }
                } else {
                    $passed = $false
                    $reason = "Expected scriptblock to throw, but no exception was thrown."
                }
            }
            default {
                throw [System.ArgumentException]::new("Unsupported Should assertion operator: '$op'")
            }
        }

        # Apply negation if -Not was specified
        $finalCondition = if ($isNot) { -not $passed } else { $passed }

        if (-not $finalCondition) {
            $prefix = if ($isNot) { "Assertion Failed (Negated): Not $op. " } else { "Assertion Failed: $op. " }
            throw [System.Management.Automation.RuntimeException]::new("$prefix$reason")
        }
    }
}

# ==============================================================================
# 2. SIMULATED FIXTURE BUILDERS & MOCK INVENTORIES
# ==============================================================================

function New-MockSystemProfile {
    [CmdletBinding()]
    param(
        [string]$CpuName = "AMD Ryzen 7 7800X3D 8-Core Processor",
        [int]$CpuCores = 8,
        [int]$CpuThreads = 16,
        [double]$TotalRamGB = 32.0,
        [string]$GpuName = "NVIDIA GeForce RTX 4080",
        [string]$GpuVendor = "NVIDIA",
        [string]$StorageType = "NVMe SSD",
        [bool]$IsLaptop = $false,
        [bool]$OnBattery = $false,
        [double]$CpuLoadPercent = 12.5,
        [double]$RamUsedPercent = 34.0,
        [bool]$IsGamingActive = $false,
        [string]$ActiveGameName = "",
        [array]$TopDrainers = @()
    )

    return [PSCustomObject]@{
        Hardware = [PSCustomObject]@{
            CpuName     = $CpuName
            CpuCores    = $CpuCores
            CpuThreads  = $CpuThreads
            TotalRamGB  = [math]::Round($TotalRamGB, 2)
            GpuName     = $GpuName
            GpuVendor   = $GpuVendor
            StorageType = $StorageType
            IsLaptop    = $IsLaptop
            OnBattery   = $OnBattery
        }
        Workload = [PSCustomObject]@{
            CpuLoadPercent = [math]::Round($CpuLoadPercent, 2)
            RamUsedPercent = [math]::Round($RamUsedPercent, 2)
            IsGamingActive = $IsGamingActive
            ActiveGameName = $ActiveGameName
            TopDrainers    = $TopDrainers
        }
        Timestamp = (Get-Date)
    }
}

function New-MockAiKnowledgeBase {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        classes = @(
            "Core_OS_Essential",
            "Telemetry_Tracking",
            "OEM_Bloatware",
            "ThirdParty_Updater",
            "Consumer_Bloatware",
            "High_Overhead_Task"
        )
        whitelist = @(
            "RpcSs", "DcomLaunch", "CryptSvc", "wuauserv", "trustedinstaller",
            "audiosrv", "mpssvc", "bfe", "samss", "lsass", "dhcp", "dnscache",
            "lanmanserver", "lanmanworkstation", "eventlog", "plugplay"
        )
        metadata = [PSCustomObject]@{
            model_name     = "WinAurex-FastInfer"
            version        = "1.0.0"
            accuracy       = 0.9927
            features_count = 2100
        }
        log_priors = [PSCustomObject]@{
            Core_OS_Essential  = -1.50
            Telemetry_Tracking = -1.80
            OEM_Bloatware      = -2.00
            ThirdParty_Updater = -2.10
            Consumer_Bloatware = -2.00
            High_Overhead_Task = -2.30
        }
    }
}

function New-MockServiceInventory {
    [CmdletBinding()]
    param(
        [ValidateSet("Standard", "Bloated", "Clean", "Minimal")]
        [string]$Preset = "Standard"
    )

    $services = [System.Collections.Generic.List[PSObject]]::new()

    # Core Protected Windows Services
    $services.Add([PSCustomObject]@{
        Name              = "RpcSs"
        DisplayName       = "Remote Procedure Call (RPC)"
        Description       = "The RPCSS service is the Service Control Manager for COM and DCOM servers."
        PathName          = "C:\Windows\system32\svchost.exe -k rpcss"
        StartMode         = "Auto"
        State             = "Running"
        DependentServices = @()
    })
    $services.Add([PSCustomObject]@{
        Name              = "wuauserv"
        DisplayName       = "Windows Update"
        Description       = "Enables the detection, download, and installation of updates for Windows."
        PathName          = "C:\Windows\system32\svchost.exe -k netsvcs -p"
        StartMode         = "Manual"
        State             = "Running"
        DependentServices = @()
    })
    $services.Add([PSCustomObject]@{
        Name              = "audiosrv"
        DisplayName       = "Windows Audio"
        Description       = "Manages audio for Windows-based programs."
        PathName          = "C:\Windows\System32\svchost.exe -k LocalServiceNetworkRestricted -p"
        StartMode         = "Auto"
        State             = "Running"
        DependentServices = @()
    })
    $services.Add([PSCustomObject]@{
        Name              = "mpssvc"
        DisplayName       = "Windows Defender Firewall"
        Description       = "Windows Defender Firewall helps protect your computer by preventing unauthorized users from gaining access."
        PathName          = "C:\Windows\system32\svchost.exe -k LocalServiceNoNetworkFirewall -p"
        StartMode         = "Auto"
        State             = "Running"
        DependentServices = @()
    })

    # Telemetry and Tracking Daemons
    $services.Add([PSCustomObject]@{
        Name              = "DiagTrack"
        DisplayName       = "Connected User Experiences and Telemetry"
        Description       = "The Connected User Experiences and Telemetry service enables features that support in-application and connected user experiences."
        PathName          = "C:\Windows\System32\svchost.exe -k utcsvc -p"
        StartMode         = if ($Preset -eq "Clean") { "Disabled" } else { "Auto" }
        State             = if ($Preset -eq "Clean") { "Stopped" } else { "Running" }
        DependentServices = @()
    })
    $services.Add([PSCustomObject]@{
        Name              = "dmwappushservice"
        DisplayName       = "Device Management Wireless Application Protocol (WAP) Push"
        Description       = "Routes WAP push messages received by the device for telemetry."
        PathName          = "C:\Windows\System32\svchost.exe -k netsvcs"
        StartMode         = if ($Preset -eq "Clean") { "Disabled" } else { "Auto" }
        State             = if ($Preset -eq "Clean") { "Stopped" } else { "Running" }
        DependentServices = @()
    })

    # OEM & Third-Party Bloat Services
    if ($Preset -in @("Standard", "Bloated")) {
        $services.Add([PSCustomObject]@{
            Name              = "HpTouchpointAnalyticsService"
            DisplayName       = "HP Touchpoint Analytics Client"
            Description       = "Collects diagnostic and telemetry data for HP systems."
            PathName          = "C:\Program Files\HP\Touchpoint\TouchpointAnalytics.exe"
            StartMode         = "Auto"
            State             = "Running"
            DependentServices = @()
        })
        $services.Add([PSCustomObject]@{
            Name              = "DellSupportAssistAgent"
            DisplayName       = "Dell SupportAssist"
            Description       = "Dell SupportAssist agent for telemetry and background telemetry polling."
            PathName          = "C:\Program Files\Dell\SupportAssistAgent\bin\SupportAssistAgent.exe"
            StartMode         = "Auto"
            State             = "Running"
            DependentServices = @()
        })
        $services.Add([PSCustomObject]@{
            Name              = "AdobeARMservice"
            DisplayName       = "Adobe Acrobat Update Service"
            Description       = "Keeps your Adobe software up to date."
            PathName          = "C:\Program Files (x86)\Common Files\Adobe\ARM\1.0\armsvc.exe"
            StartMode         = "Auto"
            State             = "Running"
            DependentServices = @()
        })
    }

    if ($Preset -eq "Bloated") {
        $services.Add([PSCustomObject]@{
            Name              = "MapsBroker"
            DisplayName       = "Downloaded Maps Manager"
            Description       = "Windows service for application access to downloaded maps."
            PathName          = "C:\Windows\System32\svchost.exe -k LocalService -p"
            StartMode         = "Auto"
            State             = "Running"
            DependentServices = @()
        })
        $services.Add([PSCustomObject]@{
            Name              = "RetailDemo"
            DisplayName       = "Retail Demo Service"
            Description       = "The Retail Demo service controls device activity while the device is in retail demo mode."
            PathName          = "C:\Windows\System32\svchost.exe -k LocalServiceNoNetwork"
            StartMode         = "Manual"
            State             = "Stopped"
            DependentServices = @()
        })
    }

    return $services.ToArray()
}

function New-MockAppxInventory {
    [CmdletBinding()]
    param(
        [ValidateSet("Standard", "Bloated", "Clean")]
        [string]$Preset = "Standard"
    )

    $apps = [System.Collections.Generic.List[PSObject]]::new()

    # Core Protected Frameworks & SystemApps
    $apps.Add([PSCustomObject]@{
        Name            = "Microsoft.VCLibs.140.00"
        Publisher       = "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
        NonRemovable    = $true
        SignatureKind   = "System"
        IsFramework     = $true
        InstallLocation = "C:\Program Files\WindowsApps\Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe"
        PackageFullName = "Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe"
    })
    $apps.Add([PSCustomObject]@{
        Name            = "Microsoft.UI.Xaml.2.7"
        Publisher       = "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
        NonRemovable    = $true
        SignatureKind   = "System"
        IsFramework     = $true
        InstallLocation = "C:\Program Files\WindowsApps\Microsoft.UI.Xaml.2.7_7.2208.15001.0_x64__8wekyb3d8bbwe"
        PackageFullName = "Microsoft.UI.Xaml.2.7_7.2208.15001.0_x64__8wekyb3d8bbwe"
    })
    $apps.Add([PSCustomObject]@{
        Name            = "Microsoft.WindowsTerminal"
        Publisher       = "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
        NonRemovable    = $true
        SignatureKind   = "Store"
        IsFramework     = $false
        InstallLocation = "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_1.18.2822.0_x64__8wekyb3d8bbwe"
        PackageFullName = "Microsoft.WindowsTerminal_1.18.2822.0_x64__8wekyb3d8bbwe"
    })
    $apps.Add([PSCustomObject]@{
        Name            = "Microsoft.DesktopAppInstaller"
        Publisher       = "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
        NonRemovable    = $true
        SignatureKind   = "Store"
        IsFramework     = $false
        InstallLocation = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.20.2201.0_x64__8wekyb3d8bbwe"
        PackageFullName = "Microsoft.DesktopAppInstaller_1.20.2201.0_x64__8wekyb3d8bbwe"
    })

    # Removable Bloatware Packages
    if ($Preset -in @("Standard", "Bloated")) {
        $apps.Add([PSCustomObject]@{
            Name            = "Clipchamp.Clipchamp"
            Publisher       = "CN=Clipchamp Pty Ltd, O=Clipchamp Pty Ltd"
            NonRemovable    = $false
            SignatureKind   = "Store"
            IsFramework     = $false
            InstallLocation = "C:\Program Files\WindowsApps\Clipchamp.Clipchamp_2.5.0_x64__yxz76"
            PackageFullName = "Clipchamp.Clipchamp_2.5.0_x64__yxz76"
        })
        $apps.Add([PSCustomObject]@{
            Name            = "Microsoft.BingWeather"
            Publisher       = "CN=Microsoft Corporation, O=Microsoft Corporation"
            NonRemovable    = $false
            SignatureKind   = "Store"
            IsFramework     = $false
            InstallLocation = "C:\Program Files\WindowsApps\Microsoft.BingWeather_4.53.51_x64__8wekyb3d8bbwe"
            PackageFullName = "Microsoft.BingWeather_4.53.51_x64__8wekyb3d8bbwe"
        })
    }

    if ($Preset -eq "Bloated") {
        $apps.Add([PSCustomObject]@{
            Name            = "TikTok.TikTok"
            Publisher       = "CN=TikTok Pte. Ltd."
            NonRemovable    = $false
            SignatureKind   = "Store"
            IsFramework     = $false
            InstallLocation = "C:\Program Files\WindowsApps\TikTok_1.0_x64__abc"
            PackageFullName = "TikTok_1.0_x64__abc"
        })
    }

    return $apps.ToArray()
}

function New-MockTaskInventory {
    [CmdletBinding()]
    param()

    return @(
        [PSCustomObject]@{
            TaskPath = "\Microsoft\Windows\Customer Experience Improvement Program\"
            TaskName = "Consolidator"
            State    = "Ready"
            Enabled  = $true
        },
        [PSCustomObject]@{
            TaskPath = "\Microsoft\Windows\Application Experience\"
            TaskName = "Microsoft Compatibility Appraiser"
            State    = "Ready"
            Enabled  = $true
        },
        [PSCustomObject]@{
            TaskPath = "\Microsoft\Windows\Autochk\"
            TaskName = "Proxy"
            State    = "Disabled"
            Enabled  = $false
        },
        [PSCustomObject]@{
            TaskPath = "\Microsoft\Windows\Maintenance\"
            TaskName = "WinSAT"
            State    = "Ready"
            Enabled  = $true
        }
    )
}

function New-MockCandidateItem {
    [CmdletBinding()]
    param(
        [string]$TargetType = "Service",
        [string]$Name = "DiagTrack",
        [string]$DisplayName = "Connected User Experiences and Telemetry",
        [string]$Category = "Telemetry_Tracking",
        [string]$SafetyTier = "Tier 1 (Safe)",
        [double]$ConfidenceVal = 0.985,
        [string]$CurrentState = "Running",
        [bool]$IsAlreadyApplied = $false,
        [bool]$IsSelected = $true
    )

    $tierText = if ($SafetyTier -match "Tier 1") { "Tier 1 (Safe)" } else { "Tier 2 (Recommended)" }
    $statusText = if ($IsAlreadyApplied) { "Optimized (Disabled)" } else { "Actionable ($CurrentState)" }
    $actionText = if ($IsAlreadyApplied) { "Already Disabled" } else { "Disable $TargetType" }

    return [PSCustomObject]@{
        TargetType       = $TargetType
        Name             = $Name
        DisplayName      = $DisplayName
        Category         = $Category
        SafetyTier       = $SafetyTier
        RiskTier         = $tierText
        TierDisplay      = $tierText
        Confidence       = "$([Math]::Round($ConfidenceVal * 100, 1))%"
        ConfidenceVal    = $ConfidenceVal
        Description      = "Candidate component identified for AI optimization"
        CurrentState     = if ($IsAlreadyApplied) { "Already Disabled" } else { $CurrentState }
        StatusDisplay    = $statusText
        Action           = $actionText
        IsSelected       = $IsSelected
        IsAlreadyApplied = $IsAlreadyApplied
        EstSavings       = if ($IsAlreadyApplied) { "0 RAM Drag (Optimized)" } else { "1 Proc, ~8 Threads, ~180 Handles" }
    }
}

function New-MockRecommendation {
    [CmdletBinding()]
    param(
        [string]$Id = "REC-OPT-001",
        [string]$Title = "Disable Telemetry Daemons",
        [string]$Description = "Prevents Windows diagnostic telemetry from uploading host usage logs.",
        [string]$Category = "Telemetry",
        [string]$Priority = "High",
        [string]$SafetyTier = "Tier 1 (Safe)",
        [string]$EstimatedBenefit = "Reduces idle disk & CPU background wakeups",
        [array]$TargetItems = @("DiagTrack", "dmwappushservice")
    )

    return [PSCustomObject]@{
        Id               = $Id
        Title            = $Title
        Description      = $Description
        Category         = $Category
        Priority         = $Priority
        SafetyTier       = $SafetyTier
        EstimatedBenefit = $EstimatedBenefit
        TargetItems      = $TargetItems
    }
}

function New-MockTransactionSnapshot {
    [CmdletBinding()]
    param(
        [string]$TransactionID = "TXN-20261113-001",
        [string]$Profile = "AI_Dynamic_Remediation",
        [array]$Changes = @()
    )

    return [PSCustomObject]@{
        TransactionID = $TransactionID
        Profile       = $Profile
        Timestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        OSBuild       = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild -ErrorAction SilentlyContinue).CurrentBuild
        Changes       = $Changes
    }
}

# ==============================================================================
# 3. INTERFACE CONTRACT VALIDATORS
# ==============================================================================

function Assert-AiInferenceContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Inference)

    $validCategories = @(
        "Core_OS_Essential",
        "Core_OS_Required",
        "Telemetry_Tracking",
        "Telemetry",
        "OEM_Bloatware",
        "ThirdParty_Updater",
        "Consumer_Bloatware",
        "High_Overhead_Task",
        "Gaming_Bottleneck",
        "Safe_Optimization",
        "Unknown"
    )

    $validTiers = @(
        "Tier 0 (Protected)",
        "Tier 1 (Safe)",
        "Tier 2 (Recommended)",
        "Tier 3 (Advanced)"
    )

    if ($null -eq $Inference) { throw "AiInference result cannot be null" }

    $cat = if ($Inference.Category) { $Inference.Category } else { $Inference["Category"] }
    $tier = if ($Inference.SafetyTier) { $Inference.SafetyTier } else { $Inference["SafetyTier"] }
    $conf = if ($null -ne $Inference.Confidence) { [double]$Inference.Confidence } else { [double]$Inference["Confidence"] }
    $isSafe = if ($null -ne $Inference.IsSafeToDisable) { [bool]$Inference.IsSafeToDisable } else { [bool]$Inference["IsSafeToDisable"] }

    if ($cat -notin $validCategories) {
        throw "AiInference Category '$cat' is not in valid categories taxonomy: $($validCategories -join ', ')"
    }
    if ($tier -notin $validTiers) {
        throw "AiInference SafetyTier '$tier' is not in valid tiers taxonomy: $($validTiers -join ', ')"
    }
    if ($conf -lt 0.0 -or $conf -gt 1.0) {
        throw "AiInference Confidence '$conf' is out of bounds [0.0, 1.0]"
    }
    if ($cat -in @("Core_OS_Essential", "Core_OS_Required") -and $isSafe -ne $false) {
        throw "Core OS item MUST have IsSafeToDisable = `$false"
    }
    return $true
}

function Assert-SystemProfileContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Profile)

    if ($null -eq $Profile) { throw "SystemProfile cannot be null" }
    if ($null -eq $Profile.Hardware) { throw "SystemProfile missing Hardware object" }
    if ($null -eq $Profile.Workload) { throw "SystemProfile missing Workload object" }

    $hw = $Profile.Hardware
    if ([string]::IsNullOrWhiteSpace($hw.CpuName)) { throw "Profile.Hardware.CpuName cannot be empty" }
    if ($hw.CpuCores -le 0) { throw "Profile.Hardware.CpuCores must be > 0" }
    if ($hw.CpuThreads -lt $hw.CpuCores) { throw "Profile.Hardware.CpuThreads must be >= CpuCores" }
    if ($hw.TotalRamGB -le 0.0) { throw "Profile.Hardware.TotalRamGB must be > 0" }
    if ([string]::IsNullOrWhiteSpace($hw.StorageType)) { throw "Profile.Hardware.StorageType cannot be empty" }

    $wl = $Profile.Workload
    if ($wl.CpuLoadPercent -lt 0.0 -or $wl.CpuLoadPercent -gt 100.0) {
        throw "Profile.Workload.CpuLoadPercent '$($wl.CpuLoadPercent)' out of bounds [0, 100]"
    }
    if ($wl.RamUsedPercent -lt 0.0 -or $wl.RamUsedPercent -gt 100.0) {
        throw "Profile.Workload.RamUsedPercent '$($wl.RamUsedPercent)' out of bounds [0, 100]"
    }
    return $true
}

function Assert-CandidateItemContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Item)

    $requiredProps = @(
        "TargetType", "Name", "DisplayName", "Category", "SafetyTier",
        "RiskTier", "TierDisplay", "Confidence", "CurrentState",
        "StatusDisplay", "Action", "IsSelected", "IsAlreadyApplied"
    )

    foreach ($prop in $requiredProps) {
        if (-not ($Item.PSObject.Properties.Match($prop).Count -gt 0)) {
            throw "Candidate item is missing required contract property: '$prop'"
        }
    }

    if ($Item.TargetType -notin @("Service", "AppX", "ScheduledTask", "Process", "SystemTweak")) {
        throw "Candidate item TargetType '$($Item.TargetType)' is invalid"
    }
    return $true
}

function Assert-RecommendationContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Rec)

    $requiredProps = @("Id", "Title", "Description", "Category", "Priority", "SafetyTier", "EstimatedBenefit", "TargetItems")
    foreach ($prop in $requiredProps) {
        if (-not ($Rec.PSObject.Properties.Match($prop).Count -gt 0)) {
            throw "Recommendation object is missing required contract property: '$prop'"
        }
    }
    if ($Rec.Priority -notin @("High", "Medium", "Low")) {
        throw "Recommendation Priority '$($Rec.Priority)' is invalid (must be High, Medium, or Low)"
    }
    return $true
}

# ==============================================================================
# 4. DOMAIN FALLBACK & REFERENCE LOGIC (PROJECT.md ALIGNMENT)
# ==============================================================================

function Get-WinAurexSystemProfileFallback {
    [CmdletBinding()]
    param()
    return Get-WinAurexSystemProfile
}

function Get-WinAurexAiRecommendationsFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Profile = $null,
        [Parameter(Mandatory = $false)]
        [array]$Findings = @()
    )
    return Get-WinAurexAiRecommendations -Profile $Profile -Findings $Findings
}

# ==============================================================================
# 5. MODULE EXPORTS
# ==============================================================================

Export-ModuleMember -Function `
    Describe, Context, BeforeAll, AfterAll, BeforeEach, AfterEach, It, Should, `
    Reset-TestResults, Get-TestResultSummary, `
    New-MockSystemProfile, New-MockAiKnowledgeBase, New-MockServiceInventory, `
    New-MockAppxInventory, New-MockTaskInventory, New-MockCandidateItem, `
    New-MockRecommendation, New-MockTransactionSnapshot, `
    Assert-AiInferenceContract, Assert-SystemProfileContract, `
    Assert-CandidateItemContract, Assert-RecommendationContract, `
    Get-WinAurexSystemProfileFallback, Get-WinAurexAiRecommendationsFallback
