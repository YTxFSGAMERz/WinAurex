# Windows Configuration & Optimization Framework
# Restore Classic Context Menu (Tweaks/Explorer/Restore_Classic_ContextMenu.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Explorer" -Action "Initiating Classic Context Menu Configuration"

$RegistryPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

# 1. Snapshot current state for reversibility (Check if key exists)
$CurrentValue = "Modern_Windows11_Menu"
if (Test-Path $RegistryPath) {
    $CurrentValue = "Classic_Windows10_Menu"
}

# 2. Apply Configuration (Create key with empty default value)
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
Set-ItemProperty -Path $RegistryPath -Name "(Default)" -Value "" -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Explorer" -Action "Restored Classic Context Menu" -OldValue $CurrentValue -NewValue "Classic_Windows10_Menu"

Write-Host "`n[SUCCESS] Classic Context Menu has been restored." -ForegroundColor Green
Start-Sleep -Seconds 1
