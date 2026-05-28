[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Enable Game Mode (Tweaks/GPU/Enable_Game_Mode.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "GPU" -Action "Initiating Game Mode Enablement"

$RegistryPath = "HKCU:\Software\Microsoft\GameBar"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }

# 1. Enable AutoGameMode
$Name1 = "AutoGameModeEnabled"
$CurrentValue1 = (Get-ItemProperty -Path $RegistryPath -Name $Name1 -ErrorAction SilentlyContinue).$Name1
if ($null -eq $CurrentValue1) { $CurrentValue1 = "Not_Set" }

Set-ItemProperty -Path $RegistryPath -Name $Name1 -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "GPU" -Action "Enabled AutoGameModeEnabled" -OldValue $CurrentValue1 -NewValue "1"

# 2. Allow AutoGameMode
$Name2 = "AllowAutoGameMode"
$CurrentValue2 = (Get-ItemProperty -Path $RegistryPath -Name $Name2 -ErrorAction SilentlyContinue).$Name2
if ($null -eq $CurrentValue2) { $CurrentValue2 = "Not_Set" }

Set-ItemProperty -Path $RegistryPath -Name $Name2 -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "GPU" -Action "Enabled AllowAutoGameMode" -OldValue $CurrentValue2 -NewValue "1"

Write-Host "`n[SUCCESS] Windows Game Mode has been enabled." -ForegroundColor Green
Write-Host "Windows will now prioritize game processes and suppress background updates while gaming." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
