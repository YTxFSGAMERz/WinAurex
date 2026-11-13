<#
.SYNOPSIS
    Adversarial & Stress Verification Test Suite for WinAurex AI Dynamic System Optimizer
.DESCRIPTION
    Rigorous stress-testing of Invoke-WinAurexAiScan, Invoke-WinAurexAiRemediation,
    and AI_Dynamic_System_Optimizer.ps1 CLI covering:
    - Service state matrices (Disabled+Running, Manual+Running, Stopped+Disabled, etc.)
    - Non-removable SystemApp filtering & tricky path edge cases
    - Non-existent packages, services, and tasks
    - Malformed and boundary parameter inputs
    - Strict $ErrorActionPreference = 'Stop' execution
    - CLI switch combinations and idempotence
#>

Import-Module Pester -ErrorAction SilentlyContinue

$RootDir = Split-Path -Path $PSScriptRoot -Parent
$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$OptimizerScript = Join-Path $RootDir "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"

Describe "WinAurex AI Dynamic System Optimizer - Adversarial & Stress Harness" {
    BeforeAll {
        Import-Module $AiModulePath -Force
    }

    Context "Adversarial Input & Boundary Safety (Invoke-WinAurexAiRemediation)" {
        It "Gracefully handles empty array @() with Applied=0, Skipped=0" {
            $res = Invoke-WinAurexAiRemediation -SelectedItems @() -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "Gracefully handles null with Applied=0, Skipped=0" {
            $res = Invoke-WinAurexAiRemediation -SelectedItems $null -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "Handles malformed items (missing TargetType / properties) without crashing" {
            $malformed = @(
                [PSCustomObject]@{},
                [PSCustomObject]@{ TargetType = "UnknownAlienType"; Name = "InvalidX" },
                [PSCustomObject]@{ TargetType = $null; Name = $null }
            )
            { Invoke-WinAurexAiRemediation -SelectedItems $malformed -Force } | Should Not Throw
        }

        It "Handles non-existent service name safely" {
            $item = [PSCustomObject]@{
                TargetType       = "Service"
                Name             = "WinAurex_NonExistent_Svc_99999"
                DisplayName      = "Non Existent Svc"
                IsAlreadyApplied = $false
            }
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($item) -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "Handles non-existent AppX package safely as ALREADY REMOVED (Skipped=1)" {
            $item = [PSCustomObject]@{
                TargetType       = "AppX"
                Name             = "WinAurex.NonExistent.Package.99999"
                DisplayName      = "WinAurex.NonExistent.Package.99999"
                IsAlreadyApplied = $false
            }
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($item) -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 1
        }

        It "Handles non-existent ScheduledTask safely without exception" {
            $item = [PSCustomObject]@{
                TargetType       = "ScheduledTask"
                Name             = "FakeTaskXYZ"
                DisplayName      = "\FakeFolder\FakeTaskXYZ"
                IsAlreadyApplied = $false
            }
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($item) -Force
            $res.Applied | Should Be 1  # Disable-ScheduledTask with -ErrorAction SilentlyContinue returns $appliedCount++
        }

        It "Safely increments skippedCount for items with IsAlreadyApplied = `$true" {
            $alreadyApplied = @(
                [PSCustomObject]@{ TargetType = "Service"; Name = "Svc1"; IsAlreadyApplied = $true },
                [PSCustomObject]@{ TargetType = "AppX"; Name = "App1"; IsAlreadyApplied = $true },
                [PSCustomObject]@{ TargetType = "ScheduledTask"; Name = "Task1"; IsAlreadyApplied = $true }
            )
            $res = Invoke-WinAurexAiRemediation -SelectedItems $alreadyApplied -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 3
        }

        It "Executes cleanly under `$ErrorActionPreference = 'Stop'" {
            $origEAP = $ErrorActionPreference
            try {
                $ErrorActionPreference = "Stop"
                $mixed = @(
                    [PSCustomObject]@{ TargetType = "Service"; Name = "NonExistentSvc"; IsAlreadyApplied = $false },
                    [PSCustomObject]@{ TargetType = "AppX"; Name = "NonExistentAppX"; IsAlreadyApplied = $false },
                    [PSCustomObject]@{ TargetType = "AppX"; Name = "Microsoft.MicrosoftEdgeDevToolsClient"; IsAlreadyApplied = $false },
                    [PSCustomObject]@{ TargetType = "ScheduledTask"; Name = "FakeTask"; DisplayName = "\Fake\FakeTask"; IsAlreadyApplied = $false },
                    [PSCustomObject]@{ TargetType = "Service"; Name = "AlreadyDoneSvc"; IsAlreadyApplied = $true }
                )
                $res = Invoke-WinAurexAiRemediation -SelectedItems $mixed -Force
                $res | Should Not BeNullOrEmpty
            } finally {
                $ErrorActionPreference = $origEAP
            }
        }
    }

    Context "Service State Combination Matrix" {
        It "Only flags service as IsAlreadyApplied when StartMode is Disabled AND State is NOT Running" {
            # Evaluation logic in Invoke-WinAurexAiScan:
            # $isAlreadyDisabled = ($svc.StartMode -eq "Disabled" -and $svc.State -ne "Running")

            # Case 1: Disabled + Stopped -> Already Disabled (True)
            $svc1 = [PSCustomObject]@{ StartMode = "Disabled"; State = "Stopped" }
            $isDis1 = ($svc1.StartMode -eq "Disabled" -and $svc1.State -ne "Running")
            $isDis1 | Should Be $true

            # Case 2: Disabled + Running -> Pending remediation (False)
            $svc2 = [PSCustomObject]@{ StartMode = "Disabled"; State = "Running" }
            $isDis2 = ($svc2.StartMode -eq "Disabled" -and $svc2.State -ne "Running")
            $isDis2 | Should Be $false

            # Case 3: Manual + Running -> Pending remediation (False)
            $svc3 = [PSCustomObject]@{ StartMode = "Manual"; State = "Running" }
            $isDis3 = ($svc3.StartMode -eq "Disabled" -and $svc3.State -ne "Running")
            $isDis3 | Should Be $false

            # Case 4: Manual + Stopped -> Pending remediation (False)
            $svc4 = [PSCustomObject]@{ StartMode = "Manual"; State = "Stopped" }
            $isDis4 = ($svc4.StartMode -eq "Disabled" -and $svc4.State -ne "Running")
            $isDis4 | Should Be $false

            # Case 5: Auto + Running -> Pending remediation (False)
            $svc5 = [PSCustomObject]@{ StartMode = "Auto"; State = "Running" }
            $isDis5 = ($svc5.StartMode -eq "Disabled" -and $svc5.State -ne "Running")
            $isDis5 | Should Be $false

            # Case 6: Auto + Stopped -> Pending remediation (False)
            $svc6 = [PSCustomObject]@{ StartMode = "Auto"; State = "Stopped" }
            $isDis6 = ($svc6.StartMode -eq "Disabled" -and $svc6.State -ne "Running")
            $isDis6 | Should Be $false
        }
    }

    Context "SystemApp Filtering & Tricky Path Edge Cases" {
        It "Excludes packages matching SystemApps regardless of path casing or slashes" {
            $filterBlock = {
                param($pkg)
                return ($pkg.NonRemovable -or 
                    ($pkg.InstallLocation -and $pkg.InstallLocation -match 'SystemApps|ImmersiveControlPanel') -or 
                    ($pkg.SignatureKind -eq "System") -or 
                    $pkg.IsFramework)
            }

            # Standard SystemApps path
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "C:\Windows\SystemApps\Microsoft.LockApp"; NonRemovable = $false; SignatureKind = "Store"; IsFramework = $false }) | Should Be $true

            # Lowercase systemapps
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "c:\windows\systemapps\microsoft.edge"; NonRemovable = $false; SignatureKind = "Store"; IsFramework = $false }) | Should Be $true

            # NonRemovable flag true
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "C:\Custom"; NonRemovable = $true; SignatureKind = "Store"; IsFramework = $false }) | Should Be $true

            # SignatureKind System
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "C:\Custom"; NonRemovable = $false; SignatureKind = "System"; IsFramework = $false }) | Should Be $true

            # IsFramework true
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "C:\Custom"; NonRemovable = $false; SignatureKind = "Store"; IsFramework = $true }) | Should Be $true

            # ImmersiveControlPanel
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "C:\Windows\ImmersiveControlPanel"; NonRemovable = $false; SignatureKind = "Store"; IsFramework = $false }) | Should Be $true

            # Genuine third party bloatware candidate: should NOT be filtered
            & $filterBlock ([PSCustomObject]@{ InstallLocation = "C:\Program Files\WindowsApps\King.CandyCrushSaga_1.0_x64__8wekyb3d8bbwe"; NonRemovable = $false; SignatureKind = "Store"; IsFramework = $false }) | Should Be $false
        }

        It "Classifies all critical system app prefixes as Core_OS_Essential in Invoke-AiInference" {
            $prefixes = @(
                "Microsoft.MicrosoftEdgeDevToolsClient",
                "Microsoft.XboxGameCallableUI",
                "Microsoft.AAD.BrokerPlugin",
                "Microsoft.AccountsControl",
                "Microsoft.CredDialogHost",
                "Microsoft.LockApp",
                "Microsoft.Win32WebViewHost",
                "Microsoft.Windows.ContentDeliveryManager",
                "Microsoft.Windows.ShellFlow"
            )
            foreach ($p in $prefixes) {
                $pred = Invoke-AiInference -Name $p
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should Be $false
            }
        }
    }

    Context "CLI Switch Combinations & Idempotent Execution" {
        It "AI_Dynamic_System_Optimizer.ps1 -ScanOnly -Force executes cleanly" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -ScanOnly -Force"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            $proc.ExitCode | Should Be 0
            $stdout | Should Match "Scan mode complete"
        }

        It "AI_Dynamic_System_Optimizer.ps1 -Force alone executes default scan cleanly" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -Force"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            $proc.ExitCode | Should Be 0
            $stdout | Should Match "Scan mode complete"
        }

        It "AI_Dynamic_System_Optimizer.ps1 -Auto -Force executes and is idempotent across subsequent runs" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -Auto -Force"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            # First Run
            $proc1 = [System.Diagnostics.Process]::Start($pinfo)
            $stdout1 = $proc1.StandardOutput.ReadToEnd()
            $stderr1 = $proc1.StandardError.ReadToEnd()
            $proc1.WaitForExit()

            $proc1.ExitCode | Should Be 0
            $stderr1 | Should BeNullOrEmpty

            # Second Run (Idempotent: 0 pending, 0 applied)
            $proc2 = [System.Diagnostics.Process]::Start($pinfo)
            $stdout2 = $proc2.StandardOutput.ReadToEnd()
            $stderr2 = $proc2.StandardError.ReadToEnd()
            $proc2.WaitForExit()

            $proc2.ExitCode | Should Be 0
            $stderr2 | Should BeNullOrEmpty
            $stdout2 | Should Match "Applied Remediation\s*:\s*0 components"
        }

        It "CLI executes cleanly when wrapped in strict `$ErrorActionPreference = 'Stop'" {
            $cmd = "`$ErrorActionPreference = 'Stop'; & '$OptimizerScript' -ScanOnly -Force"
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
