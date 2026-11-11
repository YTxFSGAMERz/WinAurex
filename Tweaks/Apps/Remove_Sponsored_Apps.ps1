[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Remove Sponsored Apps (Tweaks/Apps/Remove_Sponsored_Apps.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

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

# Fast batch query
$allPackages = @(Get-AppxPackage -ErrorAction SilentlyContinue)
$allProv = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)

foreach ($App in $SponsoredApps) {
    # Remove for current user
    $matching = $allPackages | Where-Object { $_.Name -like $App }
    foreach ($Pkg in $matching) {
        Remove-AppxPackage -Package $Pkg.PackageFullName -ErrorAction SilentlyContinue
        $RemovedCount++
    }
    
    # Remove from provisioned packages
    $matchingProv = $allProv | Where-Object { $_.DisplayName -like $App }
    foreach ($Prov in $matchingProv) {
        Remove-AppxProvisionedPackage -Online -PackageName $Prov.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}

if ($RemovedCount -eq 0) {
    Write-Host "  [-] No third-party sponsored shovelware found on system (Already clean)." -ForegroundColor DarkGray
} else {
    Write-Host "`n[SUCCESS] Successfully removed $RemovedCount sponsored apps." -ForegroundColor Green
    Write-Host "Third-party bloatware like Candy Crush and TikTok have been scrubbed from the system." -ForegroundColor Yellow
}
