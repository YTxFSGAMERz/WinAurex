[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Generate System Report (Tools/System-Info/Generate_System_Report.ps1)

Write-Host "Gathering System Information... Please wait.`n" -ForegroundColor Cyan

$OS = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor
$RAM = Get-CimInstance Win32_ComputerSystem
$GPU = Get-CimInstance Win32_VideoController
$PowerPlan = Get-CimInstance -Namespace root\cimv2\power -Class Win32_PowerPlan | Where-Object {$_.IsActive -eq $true}

$Report = @"
=================================================
       WINDOWS SYSTEM DIAGNOSTIC REPORT
=================================================
TIMESTAMP: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
=================================================

[OPERATING SYSTEM]
OS Name:      $($OS.Caption)
Architecture: $($OS.OSArchitecture)
Build Number: $($OS.BuildNumber)
Version:      $($OS.Version)

[CPU]
Processor:    $($CPU.Name)
Cores:        $($CPU.NumberOfCores)
Logical:      $($CPU.NumberOfLogicalProcessors)

[MEMORY]
Total RAM:    $([math]::Round($RAM.TotalPhysicalMemory / 1GB, 2)) GB

[GRAPHICS]
GPU Name:     $($GPU.Name)
Driver Ver:   $($GPU.DriverVersion)

[POWER]
Active Plan:  $($PowerPlan.ElementName)

=================================================
"@

$OutPath = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop\System_Report.txt"
$Report | Out-File -FilePath $OutPath -Encoding UTF8

Write-Host $Report
Write-Host "`n[SUCCESS] Report generated and saved to: $OutPath" -ForegroundColor Green
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

