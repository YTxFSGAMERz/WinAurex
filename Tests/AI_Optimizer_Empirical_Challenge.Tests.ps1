<#
.SYNOPSIS
    Empirical Adversarial Stress Test Suite for WinAurex AI Dynamic System Optimizer
.DESCRIPTION
    Comprehensive challenger test harness covering:
    - Strict ErrorActionPreference = 'Stop' enforcement
    - Idempotence verification over repeated runs
    - Defensive remediation parameter fuzzing (null, empty, malformed, injections)
    - SystemApp protection and error handling (0x80070032 COMExceptions)
    - AI Inference boundary conditions and casing
    - Concurrency and pipeline resilience
#>

Import-Module Pester -ErrorAction SilentlyContinue

$RootDir = Split-Path -Path $PSScriptRoot -Parent
$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$OptimizerScript = Join-Path $RootDir "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"

Describe "WinAurex AI Dynamic System Optimizer - Empirical Challenge Suite" {
    BeforeAll {
        Import-Module $AiModulePath -Force
    }

    Context "1. Strict ErrorActionPreference = 'Stop' CLI Execution" {
        It "Executes -ScanOnly -Force under ErrorActionPreference='Stop' with ExitCode 0" {
            $cmd = "& { `$ErrorActionPreference = 'Stop'; & '$OptimizerScript' -ScanOnly -Force }; exit `$LASTEXITCODE"
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            $proc.ExitCode | Should Be 0
            $stderr | Should BeNullOrEmpty
            $stdout | Should Match "Found 0 pending candidates"
            $stdout | Should Match "Background Services\s*:\s*0 detected"
            $stdout | Should Match "Bloatware Packages\s*:\s*0 detected"
            $stdout | Should Match "High-Overhead Tasks\s*:\s*0 detected"
        }

        It "Executes -Auto -Force under ErrorActionPreference='Stop' with ExitCode 0 and 0 errors" {
            $cmd = "& { `$ErrorActionPreference = 'Stop'; & '$OptimizerScript' -Auto -Force }; exit `$LASTEXITCODE"
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            $proc.ExitCode | Should Be 0
            $stderr | Should BeNullOrEmpty
            $stdout | Should Match "Applied Remediation\s*:\s*0 components"
            $stdout | Should Match "All components are already optimized"
        }
    }

    Context "2. Idempotence Verification Over Repeated Runs" {
        It "Maintains 0 applied remediations and 0 errors across 3 consecutive -Auto runs" {
            for ($i = 1; $i -le 3; $i++) {
                $cmd = "& { `$ErrorActionPreference = 'Stop'; & '$OptimizerScript' -Auto -Force }; exit `$LASTEXITCODE"
                $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                $pinfo.FileName = "powershell.exe"
                $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
                $pinfo.RedirectStandardOutput = $true
                $pinfo.RedirectStandardError = $true
                $pinfo.UseShellExecute = $false
                $pinfo.CreateNoWindow = $true

                $proc = [System.Diagnostics.Process]::Start($pinfo)
                $stdout = $proc.StandardOutput.ReadToEnd()
                $stderr = $proc.StandardError.ReadToEnd()
                $proc.WaitForExit()

                $proc.ExitCode | Should Be 0
                $stderr | Should BeNullOrEmpty
                $stdout | Should Match "Applied Remediation\s*:\s*0 components"
            }
        }
    }

    Context "3. Adversarial Fuzzing & Edge Cases for Invoke-WinAurexAiRemediation" {
        BeforeEach {
            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'
        }
        AfterEach {
            $ErrorActionPreference = $prevEAP
        }

        It "Gracefully handles $null SelectedItems under Stop preference" {
            $res = Invoke-WinAurexAiRemediation -SelectedItems $null -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "Gracefully handles empty array @() under Stop preference" {
            $res = Invoke-WinAurexAiRemediation -SelectedItems @() -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "Gracefully handles single item passed without array wrapper" {
            $mockItem = [PSCustomObject]@{
                TargetType       = "Service"
                Name             = "WinAurexMockNonExistentService123"
                DisplayName      = "WinAurexMockNonExistentService123"
                Category         = "Telemetry_Diagnostic"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = "95%"
                CurrentState     = "Not Found"
                IsSelected       = $true
                IsAlreadyApplied = $false
            }
            $res = Invoke-WinAurexAiRemediation -SelectedItems $mockItem -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "Gracefully handles array with $null elements mixed with valid items" {
            $mockItem = [PSCustomObject]@{
                TargetType       = "Service"
                Name             = "WinAurexMockNonExistentService123"
                DisplayName      = "WinAurexMockNonExistentService123"
                Category         = "Telemetry_Diagnostic"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = "95%"
                CurrentState     = "Not Found"
                IsSelected       = $true
                IsAlreadyApplied = $true
            }
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($null, $mockItem, $null) -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 1
        }

        It "Gracefully handles unknown or malformed TargetType without crashing" {
            $mockItem1 = [PSCustomObject]@{
                TargetType       = "UnknownRegistryTweak"
                Name             = "BadKey"
                IsAlreadyApplied = $false
            }
            $mockItem2 = [PSCustomObject]@{
                TargetType       = $null
                Name             = "NullType"
                IsAlreadyApplied = $false
            }
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($mockItem1, $mockItem2) -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
        }

        It "Safely handles non-existent scheduled task with bare task name (no backslash)" {
            $mockTask = [PSCustomObject]@{
                TargetType       = "ScheduledTask"
                Name             = "BareTaskNameWithoutPath"
                DisplayName      = "BareTaskNameWithoutPath"
                Category         = "Background_Drag"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = "90%"
                CurrentState     = "Ready"
                IsSelected       = $true
                IsAlreadyApplied = $false
            }
            { Invoke-WinAurexAiRemediation -SelectedItems @($mockTask) -Force } | Should Not Throw
        }

        It "Safely handles multiple non-removable Windows SystemApps without terminating errors" {
            $systemApps = @(
                [PSCustomObject]@{
                    TargetType       = "AppX"
                    Name             = "Microsoft.MicrosoftEdgeDevToolsClient"
                    DisplayName      = "Microsoft.MicrosoftEdgeDevToolsClient"
                    Category         = "Consumer_Bloatware"
                    SafetyTier       = "Tier 1 (Safe)"
                    Confidence       = "99%"
                    CurrentState     = "Installed"
                    IsSelected       = $true
                    IsAlreadyApplied = $false
                },
                [PSCustomObject]@{
                    TargetType       = "AppX"
                    Name             = "Microsoft.XboxGameCallableUI"
                    DisplayName      = "Microsoft.XboxGameCallableUI"
                    Category         = "Consumer_Bloatware"
                    SafetyTier       = "Tier 1 (Safe)"
                    Confidence       = "99%"
                    CurrentState     = "Installed"
                    IsSelected       = $true
                    IsAlreadyApplied = $false
                },
                [PSCustomObject]@{
                    TargetType       = "AppX"
                    Name             = "Microsoft.AAD.BrokerPlugin"
                    DisplayName      = "Microsoft.AAD.BrokerPlugin"
                    Category         = "Consumer_Bloatware"
                    SafetyTier       = "Tier 1 (Safe)"
                    Confidence       = "99%"
                    CurrentState     = "Installed"
                    IsSelected       = $true
                    IsAlreadyApplied = $false
                }
            )

            $res = Invoke-WinAurexAiRemediation -SelectedItems $systemApps -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 3
        }

        It "Correctly skips items marked IsAlreadyApplied = $true without attempting remediation" {
            $alreadyAppliedItem = [PSCustomObject]@{
                TargetType       = "Service"
                Name             = "Spooler"
                DisplayName      = "Print Spooler"
                Category         = "Print_Document"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = "99%"
                CurrentState     = "Already Disabled"
                IsSelected       = $false
                IsAlreadyApplied = $true
            }

            $res = Invoke-WinAurexAiRemediation -SelectedItems @($alreadyAppliedItem) -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 1
        }
    }

    Context "4. Adversarial Inference & Classifier Robustness" {
        It "Handles uppercase and mixed-case SystemApp names correctly" {
            $cases = @(
                "MICROSOFT.MICROSOFTEDGEDEVTOOLSCLIENT",
                "Microsoft.XboxGameCallableUI",
                "MICROSOFT.AAD.BROKERPLUGIN",
                "microsoft.windows.contentdeliverymanager"
            )

            foreach ($c in $cases) {
                $pred = Invoke-AiInference -Name $c
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should Be $false
            }
        }

        It "Handles boundary input strings (spaces, regex characters, empty)" {
            { Invoke-AiInference -Name "  Microsoft.XboxGameCallableUI  " } | Should Not Throw
            { Invoke-AiInference -Name "RandomService[0-9]*+?^$" } | Should Not Throw
            { Invoke-AiInference -Name "" } | Should Not Throw
            { Invoke-AiInference -Name ("A" * 5000) } | Should Not Throw
        }
    }

    Context "5. Concurrency & Pipeline Resilience" {
        It "Rejects unbounded pipeline input with standard ParameterBindingException without corrupting system state" {
            $cmd = "1..3 | & '$OptimizerScript' -ScanOnly -Force; exit `$LASTEXITCODE"
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            # PowerShell CmdletBinding correctly prevents unbounded pipeline pollution
            $stderr | Should Match "ParameterBindingException"
        }

        It "Handles conflicting switches (-ScanOnly and -Auto together) safely" {
            $cmd = "& '$OptimizerScript' -ScanOnly -Auto -Force; exit `$LASTEXITCODE"
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            $proc.ExitCode | Should Be 0
            $stderr | Should BeNullOrEmpty
        }
    }
}
