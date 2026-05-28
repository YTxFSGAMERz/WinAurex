[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Privacy Search Profile (Tweaks/Search/Apply_Privacy_Search_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY PRIVACY SEARCH PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile locks down Windows Search to strictly local files and apps."
Write-Host "It disables Bing web results, dynamic search highlights, and local search history."
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Search" -Action "Aborted Privacy Search Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Search" -Action "Starting Master Privacy Search Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/3] Disabling Web Search (Bing) integration..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Web_Search.ps1") -Force:$Force

Write-Host "`n[2/3] Disabling Dynamic Search Highlights..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Search_Highlights.ps1") -Force:$Force

Write-Host "`n[3/3] Disabling Local Search History tracking..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Local_Search_History.ps1") -Force:$Force

Write-FrameworkLog -ModuleName "Search" -Action "Completed Master Privacy Search Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Privacy Search Profile deployment complete!" -ForegroundColor Green
Write-Host "Restarting Windows Explorer to apply search UI changes immediately..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force

if (-not $Force) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

