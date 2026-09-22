[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Generate System Report (Tools/System-Info/Generate_System_Report.ps1)

Write-Host "Gathering System Information... Please wait.`n" -ForegroundColor Cyan

$OS = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
$RAM = Get-CimInstance Win32_ComputerSystem
$GPUs = Get-CimInstance Win32_VideoController
$PowerPlan = Get-CimInstance -Namespace root\cimv2\power -Class Win32_PowerPlan -ErrorAction SilentlyContinue | Where-Object {$_.IsActive -eq $true} | Select-Object -First 1

$gpuInfo = ($GPUs | ForEach-Object { "$($_.Name) (Driver: $($_.DriverVersion))" }) -join "`nGPU:          "

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
GPU:          $gpuInfo

[POWER]
Active Plan:  $($PowerPlan.ElementName)

=================================================
"@

$OutPath = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop\System_Report.txt"
$Report | Out-File -FilePath $OutPath -Encoding UTF8

Write-Host $Report
Write-Host "`n[SUCCESS] Report generated and saved to: $OutPath" -ForegroundColor Green

if (-not $Force -and -not [Console]::IsInputRedirected) {
    Read-Host "Press Enter to exit..."
}
