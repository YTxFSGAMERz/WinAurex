[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Set Launch Explorer to This PC (Tweaks/Explorer/Set_Launch_To_This_PC.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Explorer" -Action "Initiating This PC Launch Configuration"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "LaunchTo"

# 1. Snapshot current state for reversibility
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (1 = This PC, 2 = Quick Access / Home)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 1 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Explorer" -Action "Set Explorer Launch to This PC" -OldValue $CurrentValue -NewValue "1"

Write-Host "`n[SUCCESS] File Explorer will now open to 'This PC' by default." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
