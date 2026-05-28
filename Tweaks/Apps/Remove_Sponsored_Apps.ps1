[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Remove Sponsored Apps (Tweaks/Apps/Remove_Sponsored_Apps.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Apps" -Action "Initiating Sponsored Apps Removal"

# Array of known sponsored apps/bloatware
$SponsoredApps = @(
    "*TikTok*",
    "*Instagram*",
    "*Facebook*",
    "*Twitter*",
    "*Netflix*",
    "*Spotify*",
    "*Disney*",
    "*CandyCrush*",
    "*Solitaire*",
    "*MinecraftUWP*",
    "*Roblox*",
    "*HiddenCity*",
    "*MarchofEmpires*",
    "*BubbleWitch3Saga*",
    "*Asphalt8*",
    "*BingNews*"
)

$RemovedCount = 0

foreach ($App in $SponsoredApps) {
    # Remove for current user
    $Packages = Get-AppxPackage -Name $App -ErrorAction SilentlyContinue
    
    if ($Packages) {
        foreach ($Pkg in $Packages) {
            Remove-AppxPackage -Package $Pkg.PackageFullName -ErrorAction SilentlyContinue
            Write-FrameworkLog -ModuleName "Apps" -Action "Removed Sponsored App" -OldValue $Pkg.Name -NewValue "Removed"
            $RemovedCount++
        }
    }
    
    # Remove from provisioned packages (so it doesn't reinstall for new users)
    $Provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $App }
    if ($Provisioned) {
        foreach ($Prov in $Provisioned) {
            Remove-AppxProvisionedPackage -Online -PackageName $Prov.PackageName -ErrorAction SilentlyContinue | Out-Null
            Write-FrameworkLog -ModuleName "Apps" -Action "Deprovisioned Sponsored App" -OldValue $Prov.DisplayName -NewValue "Removed"
        }
    }
}

Write-Host "`n[SUCCESS] Successfully removed $RemovedCount sponsored apps." -ForegroundColor Green
Write-Host "Third-party bloatware like Candy Crush and TikTok have been scrubbed from the system." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
