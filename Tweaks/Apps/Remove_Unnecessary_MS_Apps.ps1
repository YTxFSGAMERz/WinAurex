[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Remove Unnecessary MS Apps (Tweaks/Apps/Remove_Unnecessary_MS_Apps.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

# Array of Microsoft apps that are generally safe to remove and often considered bloatware
$MSApps = @(
    "*Microsoft3DViewer*",
    "*WindowsFeedbackHub*",
    "*GetHelp*",
    "*MixedReality.Portal*",
    "*ZuneVideo*", # Movies & TV
    "*ZuneMusic*", # Groove Music (legacy)
    "*WindowsMaps*",
    "*Office.OneNote*",
    "*People*",
    "*YourPhone*", # Phone Link
    "*WindowsAlarms*",
    "*WindowsCamera*",
    "*Microsoft.Getstarted*", # Tips
    "*SkypeApp*",
    "*BingWeather*"
)

$RemovedCount = 0

# Fast batch query
$allPackages = @(Get-AppxPackage -ErrorAction SilentlyContinue)
$allProv = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)

foreach ($App in $MSApps) {
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
    Write-Host "  [-] No unused default MS apps found on system (Already clean)." -ForegroundColor DarkGray
} else {
    Write-Host "`n[SUCCESS] Successfully removed $RemovedCount unnecessary Microsoft apps." -ForegroundColor Green
    Write-Host "Unused default apps like 3D Viewer and Feedback Hub have been uninstalled." -ForegroundColor Yellow
}
