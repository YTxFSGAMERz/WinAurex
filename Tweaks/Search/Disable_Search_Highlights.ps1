# Windows Configuration & Optimization Framework
# Disable Search Highlights (Tweaks/Search/Disable_Search_Highlights.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Search" -Action "Initiating Search Highlights Disablement"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }

$Name = "IsDynamicSearchBoxEnabled"

# 1. Snapshot current state for reversibility
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (0 = Disabled, 1 = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Search" -Action "Disabled Dynamic Search Highlights" -OldValue $CurrentValue -NewValue "0"

Write-Host "`n[SUCCESS] Windows Search Highlights (daily images, trivia, news) disabled." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
