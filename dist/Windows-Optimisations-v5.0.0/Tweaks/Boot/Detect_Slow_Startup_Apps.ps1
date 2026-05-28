# Windows Configuration & Optimization Framework
# Detect Slow Startup Apps (Tweaks/Boot/Detect_Slow_Startup_Apps.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   STARTUP APPLICATION ANALYZER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Querying all active startup hooks from the registry..."
Write-Host "=================================================`n"

$Paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)

$StartupApps = @()

foreach ($Path in $Paths) {
    if (Test-Path $Path) {
        $Key = Get-Item -Path $Path
        foreach ($ValueName in $Key.Property) {
            $ValueData = (Get-ItemProperty -Path $Path -Name $ValueName).$ValueName
            $StartupApps += [PSCustomObject]@{
                Name = $ValueName
                Command = $ValueData
                Scope = if ($Path -match "HKLM") { "System-Wide" } else { "Current User" }
            }
        }
    }
}

if ($StartupApps.Count -eq 0) {
    Write-Host "No traditional startup applications found in Run keys." -ForegroundColor Green
} else {
    $StartupApps | Format-Table -AutoSize
}

Write-Host "`nWARNING: The following apps are known to severely delay boot times:" -ForegroundColor Yellow
Write-Host "- Adobe Creative Cloud / Acrobat Update Services"
Write-Host "- RGB/Hardware Software (iCUE, Armoury Crate, Razer Synapse)"
Write-Host "- Game Launchers (Steam, Epic, EA) set to start automatically"
Write-Host "- Third-party Antivirus (McAfee, Norton)"

Write-Host "`nRecommendation: Open Task Manager (Ctrl+Shift+Esc), go to the" -ForegroundColor Cyan
Write-Host "'Startup Apps' tab, and disable everything except your critical audio/GPU drivers."

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
