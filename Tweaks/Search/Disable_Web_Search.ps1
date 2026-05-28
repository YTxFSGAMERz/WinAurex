# Windows Configuration & Optimization Framework
# Disable Web Search in Start Menu (Tweaks/Search/Disable_Web_Search.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Search" -Action "Initiating Web Search Disablement"

# 1. Disable Bing Search Integration
$RegPathBing = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $RegPathBing)) { New-Item -Path $RegPathBing -Force | Out-Null }

$CurrentBing = (Get-ItemProperty -Path $RegPathBing -Name "BingSearchEnabled" -ErrorAction SilentlyContinue).BingSearchEnabled
if ($null -eq $CurrentBing) { $CurrentBing = "Not_Set" }

Set-ItemProperty -Path $RegPathBing -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Search" -Action "Disabled Bing Search" -OldValue $CurrentBing -NewValue "0"

# 2. Disable Search Box Web Suggestions (Policies)
$RegPathPolicy = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $RegPathPolicy)) { New-Item -Path $RegPathPolicy -Force | Out-Null }

$CurrentPolicy = (Get-ItemProperty -Path $RegPathPolicy -Name "DisableSearchBoxSuggestions" -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
if ($null -eq $CurrentPolicy) { $CurrentPolicy = "Not_Set" }

Set-ItemProperty -Path $RegPathPolicy -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "Search" -Action "Disabled Search Box Web Suggestions" -OldValue $CurrentPolicy -NewValue "1"

Write-Host "`n[SUCCESS] Web search and Bing integration in the Start Menu has been disabled." -ForegroundColor Green
Write-Host "Local file and app search will now be much faster and strictly private." -ForegroundColor Yellow
Start-Sleep -Seconds 1
