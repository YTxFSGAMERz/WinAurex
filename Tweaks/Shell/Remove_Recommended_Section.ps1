# Windows Configuration & Optimization Framework
# Remove Start Menu Recommended Section (Tweaks/Shell/Remove_Recommended_Section.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Shell" -Action "Initiating Start Menu Recommended Cleanup"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "HideRecentJumplists"

# 1. Snapshot current state for reversibility
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (1 = Hidden, 0 = Visible)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 1 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Shell" -Action "Disabled Recent/Recommended Jumplists" -OldValue $CurrentValue -NewValue "1"

Write-Host "`n[SUCCESS] Start Menu Recommended section and Jump Lists cleared." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
