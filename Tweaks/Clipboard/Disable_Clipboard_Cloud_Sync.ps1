# Windows Configuration & Optimization Framework
# Disable Clipboard Cloud Sync (Tweaks/Clipboard/Disable_Clipboard_Cloud_Sync.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Clipboard" -Action "Initiating Clipboard Cloud Sync Disablement"

$RegistryPath = "HKCU:\Software\Microsoft\Clipboard"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
$Name = "CloudClipboardItemSyncEnabled"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (0 = Disabled, 1 = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Clipboard" -Action "Disabled Clipboard Cloud Sync" -OldValue $CurrentValue -NewValue "0"

Write-Host "`n[SUCCESS] Windows Clipboard Cloud Sync has been disabled." -ForegroundColor Green
Write-Host "Your copied text and images will no longer be uploaded to Microsoft servers." -ForegroundColor Yellow
Start-Sleep -Seconds 1
