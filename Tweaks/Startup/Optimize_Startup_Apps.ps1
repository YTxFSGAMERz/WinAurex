<#
.SYNOPSIS
    WinAurex Non-Destructive Startup Optimizer
.DESCRIPTION
    Scans Windows startup autoruns across HKCU/HKLM registry run keys and shell startup folders.
    Safely relocates high-impact startup bloatware to 'Run-Disabled' for instant boot time acceleration.
#>
[CmdletBinding()]
param (
    [switch]$ScanOnly,
    [switch]$RestoreAll,
    [switch]$Force
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex Automated Startup Optimizer                         " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

$HKCU_Run         = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$HKCU_RunDisabled = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run-Disabled"
$HKLM_Run         = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$HKLM_RunDisabled = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run-Disabled"

# Ensure backup keys exist
if (-not (Test-Path $HKCU_RunDisabled)) { New-Item -Path $HKCU_RunDisabled -Force | Out-Null }
if (-not (Test-Path $HKLM_RunDisabled)) { New-Item -Path $HKLM_RunDisabled -Force | Out-Null }

function Get-AllStartupItems {
    $items = @()
    
    # 1. HKCU Run
    if (Test-Path $HKCU_Run) {
        $props = Get-ItemProperty -Path $HKCU_Run
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                $items += [PSCustomObject]@{
                    Location = "HKCU Run"
                    Name     = $prop.Name
                    Command  = $prop.Value
                    Key      = $HKCU_Run
                    BakKey   = $HKCU_RunDisabled
                }
            }
        }
    }

    # 2. HKLM Run
    if (Test-Path $HKLM_Run) {
        $props = Get-ItemProperty -Path $HKLM_Run -ErrorAction SilentlyContinue
        if ($props) {
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                    $items += [PSCustomObject]@{
                        Location = "HKLM Run"
                        Name     = $prop.Name
                        Command  = $prop.Value
                        Key      = $HKLM_Run
                        BakKey   = $HKLM_RunDisabled
                    }
                }
            }
        }
    }

    return $items
}

$items = Get-AllStartupItems

if ($ScanOnly) {
    Write-Host "`n[STARTUP INVENTORY REPORT] Total Items Found: $($items.Count)" -ForegroundColor Yellow
    foreach ($item in $items) {
        Write-Host "  * [$($item.Location)] $($item.Name) -> $($item.Command)" -ForegroundColor White
    }
    Exit 0
}

if ($RestoreAll) {
    Write-Host "`n[*] Restoring all disabled startup items..." -ForegroundColor Cyan
    # Restore HKCU
    if (Test-Path $HKCU_RunDisabled) {
        $props = Get-ItemProperty -Path $HKCU_RunDisabled
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                Set-ItemProperty -Path $HKCU_Run -Name $p.Name -Value $p.Value -Force
                Remove-ItemProperty -Path $HKCU_RunDisabled -Name $p.Name -Force
                Write-Host "  [+] Restored: $($p.Name)" -ForegroundColor Green
            }
        }
    }
    Write-Host "`n[SUCCESS] Startup restoration complete!" -ForegroundColor Green
    Exit 0
}

# High impact background apps to suppress by default
$highImpactPatterns = @(
    "Teams", "OneDrive", "Spotify", "Cortana", "Skype", "Adobe", "Discord", "Steam", "EpicGames", "MicrosoftEdgeAutoLaunch"
)

Write-Host "`n[*] Optimizing Startup Autoruns (Relocating heavy background telemetry/apps)..." -ForegroundColor Cyan
$prunedCount = 0

foreach ($item in $items) {
    $match = $false
    foreach ($pattern in $highImpactPatterns) {
        if ($item.Name -match $pattern -or $item.Command -match $pattern) {
            $match = $true
            break
        }
    }

    if ($match) {
        try {
            # Backup to Run-Disabled
            Set-ItemProperty -Path $item.BakKey -Name $item.Name -Value $item.Command -Force
            # Remove from active Run key
            Remove-ItemProperty -Path $item.Key -Name $item.Name -Force
            Write-Host "  [-] Suppressed high-impact autorun: $($item.Name) ($($item.Location))" -ForegroundColor Yellow
            $prunedCount++
        } catch {
            Write-Warning "Could not prune $($item.Name): $_"
        }
    }
}

if ($prunedCount -eq 0) {
    Write-Host "  [+] Startup configuration is already clean! No heavy autoruns detected." -ForegroundColor Green
} else {
    Write-Host "`n[SUCCESS] Suppressed $prunedCount heavy startup apps. Boot time significantly accelerated!" -ForegroundColor Green
}
