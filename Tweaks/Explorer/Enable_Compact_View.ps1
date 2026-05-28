# Windows Configuration & Optimization Framework
# Enable Compact View for Explorer (Tweaks/Explorer/Enable_Compact_View.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Explorer" -Action "Initiating Compact View Configuration"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "UseCompactMode"

# 1. Snapshot current state for reversibility
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (1 = Compact Mode Enabled, 0 = Disabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 1 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Explorer" -Action "Enabled Compact View" -OldValue $CurrentValue -NewValue "1"

Write-Host "`n[SUCCESS] File Explorer Compact View has been enabled." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
