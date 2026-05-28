[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Local Search History (Tweaks/Search/Disable_Local_Search_History.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Search" -Action "Initiating Local Search History Disablement"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }

$Name = "SaveSearchHistory"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (0 = Disabled, 1 = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Search" -Action "Disabled Local Search History" -OldValue $CurrentValue -NewValue "0"

Write-Host "`n[SUCCESS] Local device search history has been disabled." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
