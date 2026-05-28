[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Uninstall OneDrive (Tweaks/Sync/Uninstall_OneDrive.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Sync" -Action "Initiating OneDrive Uninstall"

Write-Host "================================================="
Write-Host "   UNINSTALL ONEDRIVE & SYNC ISOLATION" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This script will completely uninstall OneDrive from your system"
Write-Host "and remove its icon from the Windows Explorer sidebar."
Write-Host "WARNING: Any files stored ONLY in OneDrive (Files On-Demand)"
Write-Host "will become inaccessible unless downloaded first!"
Write-Host "Press 'Y' to confirm or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Sync" -Action "Aborted OneDrive Uninstall"
    Write-Host "`nAborted by user."
    Exit
}

# 1. Kill OneDrive Processes
Write-Host "`n[1/3] Terminating OneDrive processes..." -ForegroundColor Cyan
Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "Microsoft.SharePoint" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. Uninstall OneDrive
Write-Host "[2/3] Uninstalling OneDrive..." -ForegroundColor Cyan
$ODSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
if (-not (Test-Path $ODSetup)) {
    $ODSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
}

if (Test-Path $ODSetup) {
    Start-Process -FilePath $ODSetup -ArgumentList "/uninstall" -Wait -NoNewWindow
    Write-FrameworkLog -ModuleName "Sync" -Action "Uninstalled OneDrive Executable"
} else {
    Write-Host "OneDrive installer not found, it may already be uninstalled." -ForegroundColor Yellow
}

# 3. Remove Explorer Navigation Pane Icon
Write-Host "[3/3] Removing OneDrive from Explorer sidebar..." -ForegroundColor Cyan
$RegistryPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $RegistryPath) {
    Set-ItemProperty -Path $RegistryPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Sync" -Action "Removed OneDrive Explorer Icon"
}

# 4. Remove OneDrive from 64-bit Explorer sidebar
$RegistryPath64 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $RegistryPath64) {
    Set-ItemProperty -Path $RegistryPath64 -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force
}

Write-Host "`n[SUCCESS] OneDrive has been uninstalled." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."

