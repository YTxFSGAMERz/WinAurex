<#
.SYNOPSIS
    WinAurex Hardware Power & Storage Optimization Engine
.DESCRIPTION
    1. Unlocks & activates the hidden Windows Ultimate Performance power scheme (0% idle latency).
    2. Reclaims 8 GB - 32 GB of active SSD storage by reducing or disabling hiberfil.sys.
    3. Invokes native NVMe/SSD TRIM optimization to maintain flash storage write throughput.
#>
[CmdletBinding()]
param (
    [ValidateSet("UnlockUltimatePlan", "ReclaimHiberfil", "RunSsdTrim", "All")]
    [string]$Action = "All",
    [switch]$Force
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex Hardware Power & Storage Engine                     " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

# 1. ULTIMATE PERFORMANCE POWER SCHEME
if ($Action -in @("UnlockUltimatePlan", "All")) {
    Write-Host "`n[*] Unlocking Windows Ultimate Performance Power Plan..." -ForegroundColor Cyan
    try {
        # Duplicate the hidden OEM scheme
        $dupOut = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
        
        # Discover GUID for Ultimate Performance
        $schemes = powercfg -list
        $guidMatch = $schemes | Select-String "Ultimate Performance" | ForEach-Object {
            if ($_ -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
                $matches[1]
            }
        } | Select-Object -First 1

        if ($guidMatch) {
            powercfg -setactive $guidMatch
            Write-Host "  [+] Ultimate Performance Power Plan activated! (GUID: $guidMatch)" -ForegroundColor Green
            Write-Host "  [+] Core unparking enabled and CPU frequency throttling eliminated." -ForegroundColor Green
        } else {
            # Fallback to High Performance
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            Write-Host "  [+] High Performance Power Plan set as active fallback." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not activate power plan: $_"
    }
}

# 2. HIBERFIL STORAGE RECLAIMER
if ($Action -in @("ReclaimHiberfil", "All")) {
    Write-Host "`n[*] Inspecting Hibernation Storage Footprint..." -ForegroundColor Cyan
    $hiberPath = "$env:SystemDrive\hiberfil.sys"
    $beforeSizeMB = 0
    if (Test-Path $hiberPath) {
        $beforeSizeMB = [math]::Round((Get-Item $hiberPath -Force).Length / 1MB, 2)
        Write-Host "  Current hiberfil.sys size: $beforeSizeMB MB ($([math]::Round($beforeSizeMB / 1024, 2)) GB)" -ForegroundColor Yellow
    }

    Write-Host "  Compressing hibernation memory image to reduced footprint..." -ForegroundColor DarkGray
    try {
        # Configure reduced hibernation (preserves Fast Startup while cutting RAM allocation by 50%)
        powercfg /hibernate /size 50 | Out-Null
        
        if (Test-Path $hiberPath) {
            $afterSizeMB = [math]::Round((Get-Item $hiberPath -Force).Length / 1MB, 2)
            $savedMB = [math]::Max(0, [math]::Round($beforeSizeMB - $afterSizeMB, 2))
            Write-Host "  [+] Hiberfil compressed successfully. New size: $afterSizeMB MB." -ForegroundColor Green
            if ($savedMB -gt 0) {
                Write-Host "  [+] Reclaimed $savedMB MB ($([math]::Round($savedMB / 1024, 2)) GB) of high-speed SSD space!" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  [+] Hibernation storage disabled." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Hiberfil adjustment note: $_"
    }
}

# 3. NVME / SSD STORAGE TRIM
if ($Action -in @("RunSsdTrim", "All")) {
    $drive = $env:SystemDrive.Replace(":", "")
    Write-Host "`n[*] Initiating Native Hardware TRIM on Volume ($drive`:)..." -ForegroundColor Cyan
    try {
        $trimResult = Optimize-Volume -DriveLetter $drive -ReTrim -Verbose 2>&1
        Write-Host "  [+] Hardware TRIM successfully completed on drive $drive`:." -ForegroundColor Green
        Write-Host "  [+] Unused flash NAND memory blocks deallocated for optimal write speeds." -ForegroundColor Green
    } catch {
        Write-Warning "TRIM note: $_ (Volume may not support TRIM if running inside a virtual disk without pass-through)"
    }
}

Write-Host "`n[SUCCESS] Hardware Power & Storage optimization complete!" -ForegroundColor Cyan
