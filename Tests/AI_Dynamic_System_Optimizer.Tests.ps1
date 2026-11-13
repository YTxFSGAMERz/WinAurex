<#
.SYNOPSIS
    Automated Pester Verification Test Suite for WinAurex AI Dynamic System Optimizer
.DESCRIPTION
    Validates SystemApp exclusions, accurate service and task state detection,
    remediation parameter binding safety, error resilience, and CLI idempotent execution.
#>

Import-Module Pester -ErrorAction SilentlyContinue

$RootDir = Split-Path -Path $PSScriptRoot -Parent
$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$OptimizerScript = Join-Path $RootDir "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"

Describe "WinAurex AI Dynamic System Optimizer & Engine Tests" {
    BeforeAll {
        Import-Module $AiModulePath -Force
    }

    Context "Feature 3: SystemApp Whitelist and Scan Exclusion" {
        It "Classifies MicrosoftEdgeDevToolsClient as Core_OS_Essential in Invoke-AiInference" {
            $pred = Invoke-AiInference -Name "Microsoft.MicrosoftEdgeDevToolsClient"
            $pred.Category | Should Be "Core_OS_Essential"
            $pred.SafetyTier | Should Be "Tier 0 (Protected)"
            $pred.IsSafeToDisable | Should Be $false
        }

        It "Classifies XboxGameCallableUI as Core_OS_Essential in Invoke-AiInference" {
            $pred = Invoke-AiInference -Name "Microsoft.XboxGameCallableUI"
            $pred.Category | Should Be "Core_OS_Essential"
            $pred.SafetyTier | Should Be "Tier 0 (Protected)"
            $pred.IsSafeToDisable | Should Be $false
        }

        It "Excludes non-removable SystemApps from Invoke-WinAurexAiScan candidates" {
            $findings = Invoke-WinAurexAiScan
            $appxFindings = @($findings | Where-Object { $_.TargetType -eq "AppX" })
            $systemAppLeaks = @($appxFindings | Where-Object { $_.Name -match "MicrosoftEdgeDevToolsClient|XboxGameCallableUI" })
            $systemAppLeaks.Count | Should Be 0
        }
    }

    Context "Feature 1: Accurate Candidate State Evaluation" {
        It "Accurately flags already-disabled stopped services as IsAlreadyApplied" {
            $findings = Invoke-WinAurexAiScan
            $services = @($findings | Where-Object { $_.TargetType -eq "Service" })
            foreach ($s in $services) {
                $wmiSvc = Get-CimInstance Win32_Service -Filter "Name='$($s.Name)'" -ErrorAction SilentlyContinue
                if ($wmiSvc -and $wmiSvc.StartMode -eq "Disabled" -and $wmiSvc.State -ne "Running") {
                    $s.IsAlreadyApplied | Should Be $true
                    $s.CurrentState | Should Be "Already Disabled"
                    $s.IsSelected | Should Be $false
                }
            }
        }

        It "Accurately flags disabled scheduled tasks as IsAlreadyApplied" {
            $findings = Invoke-WinAurexAiScan
            $tasks = @($findings | Where-Object { $_.TargetType -eq "ScheduledTask" })
            foreach ($t in $tasks) {
                $taskPath = Split-Path $t.DisplayName -Parent
                $taskName = Split-Path $t.DisplayName -Leaf
                $taskObj = Get-ScheduledTask -TaskPath "$taskPath\" -TaskName $taskName -ErrorAction SilentlyContinue
                if ($taskObj -and $taskObj.State -eq "Disabled") {
                    $t.IsAlreadyApplied | Should Be $true
                    $t.CurrentState | Should Be "Already Disabled"
                    $t.IsSelected | Should Be $false
                }
            }
        }
    }

    Context "Feature 4 & 5: Remediation Parameter Binding and COMException Safety" {
        It "Handles empty collection @() in Invoke-WinAurexAiRemediation without parameter validation errors" {
            $result = Invoke-WinAurexAiRemediation -SelectedItems @() -Force
            $result | Should Not BeNullOrEmpty
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 0
        }

        It "Handles null SelectedItems in Invoke-WinAurexAiRemediation gracefully" {
            $result = Invoke-WinAurexAiRemediation -SelectedItems $null -Force
            $result | Should Not BeNullOrEmpty
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 0
        }

        It "Defensively handles non-removable SystemApp items without throwing exceptions or falsifying applied counts" {
            $mockItem = [PSCustomObject]@{
                TargetType       = "AppX"
                Name             = "Microsoft.MicrosoftEdgeDevToolsClient"
                DisplayName      = "Microsoft.MicrosoftEdgeDevToolsClient"
                Category         = "Consumer_Bloatware"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = "99%"
                CurrentState     = "Installed"
                IsSelected       = $true
                IsAlreadyApplied = $false
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($mockItem) -Force
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 1
        }
    }

    Context "Feature 2 & 6: CLI End-to-End Scans and Remediation Exit Codes" {
        It "AI_Dynamic_System_Optimizer.ps1 -ScanOnly -Force exits 0 and reports 0 pending candidates on an already-optimized system" {
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
            $stdout | Should Match "Found 0 pending candidates"
            $stdout | Should Match "Background Services\s*:\s*0 detected"
            $stdout | Should Match "Bloatware Packages\s*:\s*0 detected"
            $stdout | Should Match "High-Overhead Tasks\s*:\s*0 detected"
        }

        It "AI_Dynamic_System_Optimizer.ps1 -Auto -Force exits 0 with 0 errors and reports 0 applied remediations on subsequent runs" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -Auto -Force"
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
