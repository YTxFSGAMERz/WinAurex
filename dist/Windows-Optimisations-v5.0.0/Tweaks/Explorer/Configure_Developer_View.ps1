# Windows Configuration & Optimization Framework
# Configure Developer View for Explorer (Tweaks/Explorer/Configure_Developer_View.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Explorer" -Action "Initiating Developer View Configuration"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Setting 1: Show Hidden Files (1 = Show, 2 = Hide)
$HiddenVal = (Get-ItemProperty -Path $RegistryPath -Name "Hidden" -ErrorAction SilentlyContinue).Hidden
if ($null -eq $HiddenVal) { $HiddenVal = "Not_Set" }
Set-ItemProperty -Path $RegistryPath -Name "Hidden" -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "Explorer" -Action "Show Hidden Files" -OldValue $HiddenVal -NewValue "1"

# Setting 2: Show File Extensions (0 = Show, 1 = Hide)
$ExtVal = (Get-ItemProperty -Path $RegistryPath -Name "HideFileExt" -ErrorAction SilentlyContinue).HideFileExt
if ($null -eq $ExtVal) { $ExtVal = "Not_Set" }
Set-ItemProperty -Path $RegistryPath -Name "HideFileExt" -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Explorer" -Action "Show File Extensions" -OldValue $ExtVal -NewValue "0"

# Setting 3: Show Protected OS Files (1 = Show, 0 = Hide)
$SuperHiddenVal = (Get-ItemProperty -Path $RegistryPath -Name "ShowSuperHidden" -ErrorAction SilentlyContinue).ShowSuperHidden
if ($null -eq $SuperHiddenVal) { $SuperHiddenVal = "Not_Set" }
Set-ItemProperty -Path $RegistryPath -Name "ShowSuperHidden" -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "Explorer" -Action "Show Protected OS Files" -OldValue $SuperHiddenVal -NewValue "1"

Write-Host "`n[SUCCESS] Developer View Configured (Extensions, Hidden Files, and OS Files are now visible)." -ForegroundColor Green
Start-Sleep -Seconds 1
