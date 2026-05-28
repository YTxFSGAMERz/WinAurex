[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Notification Spam & Windows Tips (Tweaks/Shell/Disable_Notification_Spam.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Shell" -Action "Initiating Notification Spam Cleanup"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$Name = "SubscribedContent-338389Enabled"

# 1. Snapshot current state for reversibility
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (0 = Disabled, 1 = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Shell" -Action "Disabled Windows Tips & Suggestions" -OldValue $CurrentValue -NewValue "0"

Write-Host "`n[SUCCESS] Windows tips and suggestion notification spam disabled." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
