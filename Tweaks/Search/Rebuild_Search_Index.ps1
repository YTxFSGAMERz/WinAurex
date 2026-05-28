# Windows Configuration & Optimization Framework
# Rebuild Search Index (Tweaks/Search/Rebuild_Search_Index.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   REBUILD WINDOWS SEARCH INDEX" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "WARNING: Rebuilding the search index will cause a temporary CPU and Disk I/O spike."
Write-Host "Search results will be incomplete until the rebuild finishes (usually 15-60 minutes)."
Write-Host "It is highly recommended to do this when the PC is idle."
Write-Host "Press 'Y' to initiate rebuild, or any other key to abort..." -ForegroundColor Yellow
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Search" -Action "Aborted Search Index Rebuild"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Search" -Action "Initiating Search Index Rebuild" -Level WARNING

$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows Search"
$Name = "SetupCompletedSuccessfully"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Trigger Rebuild (Set to 0 and restart service)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force

Write-Host "`nRestarting Windows Search Service (WSearch)..."
Restart-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Search" -Action "Triggered Windows Search Index Rebuild" -OldValue $CurrentValue -NewValue "0"

Write-Host "`n[SUCCESS] Search Index rebuild has been initiated in the background." -ForegroundColor Green
Write-Host "You can monitor the status in 'Indexing Options' in the Control Panel."
Start-Sleep -Seconds 2
