# Windows Configuration & Optimization Framework
# Remove Unnecessary MS Apps (Tweaks/Apps/Remove_Unnecessary_MS_Apps.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Apps" -Action "Initiating Unnecessary MS Apps Removal"

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

foreach ($App in $MSApps) {
    # Remove for current user
    $Packages = Get-AppxPackage -Name $App -ErrorAction SilentlyContinue
    
    if ($Packages) {
        foreach ($Pkg in $Packages) {
            Remove-AppxPackage -Package $Pkg.PackageFullName -ErrorAction SilentlyContinue
            Write-FrameworkLog -ModuleName "Apps" -Action "Removed MS App" -OldValue $Pkg.Name -NewValue "Removed"
            $RemovedCount++
        }
    }
    
    # Remove from provisioned packages (so it doesn't reinstall for new users)
    $Provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $App }
    if ($Provisioned) {
        foreach ($Prov in $Provisioned) {
            Remove-AppxProvisionedPackage -Online -PackageName $Prov.PackageName -ErrorAction SilentlyContinue | Out-Null
            Write-FrameworkLog -ModuleName "Apps" -Action "Deprovisioned MS App" -OldValue $Prov.DisplayName -NewValue "Removed"
        }
    }
}

Write-Host "`n[SUCCESS] Successfully removed $RemovedCount unnecessary Microsoft apps." -ForegroundColor Green
Write-Host "Unused default apps like 3D Viewer and Feedback Hub have been uninstalled." -ForegroundColor Yellow
Start-Sleep -Seconds 1
