# Windows Configuration & Optimization Framework
# Disable Tailored Experiences (Tweaks/Diagnostics/Disable_Tailored_Experiences.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Diagnostics" -Action "Initiating Tailored Experiences Disablement"

$RegistryPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
$Name = "DisableTailoredExperiencesWithDiagnosticData"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (1 = Disabled, 0 = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 1 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Diagnostics" -Action "Disabled Tailored Experiences" -OldValue $CurrentValue -NewValue "1"

Write-Host "`n[SUCCESS] Windows Tailored Experiences have been disabled." -ForegroundColor Green
Write-Host "Microsoft will no longer use your diagnostic data to serve personalized ads, tips, or recommendations." -ForegroundColor Yellow
Start-Sleep -Seconds 1
