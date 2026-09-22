# ==============================================================================
# SCRIPT: Manage Per-Game GPU Selection
# TARGET SYSTEM: Windows 10 & Windows 11
# DESCRIPTION: Interactively assigns specific games or applications to either the
#              High Performance (discrete) GPU or Power Saving (integrated) GPU.
#              Also lists and removes configured application preferences.
# SAFETY LEVEL: Safe & Fully Reversible
# ==============================================================================

param(
    [switch]$Force,
    [ValidateSet("1", "2", "3", "4")][string]$Choice,
    [string]$ExePath,
    [ValidateSet("1", "2", "3")][string]$PrefChoice,
    [string]$DelChoice
)

$Host.UI.RawUI.WindowTitle = "DirectX Graphics Preference Manager"

function Clear-Screen {
    try {
        if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
            Clear-Host
        }
    } catch {}
}

# Clear Screen & Print Beautiful Title
Clear-Screen
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                DIRECTX PER-GAME GPU PREFERENCE MANAGER               " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Check Windows Version
$OS = Get-CimInstance Win32_OperatingSystem
$Build = [int]$OS.BuildNumber
Write-Host "[*] OS: $($OS.Caption) (Build $Build)" -ForegroundColor Gray
Write-Host ""

# Registry Path
$RegPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"

# Ensure the key exists
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

function Show-Menu {
    Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  1. View Current Custom Graphics Profiles" -ForegroundColor White
    Write-Host "  2. Add/Modify Game Graphics Profile" -ForegroundColor White
    Write-Host "  3. Remove a Game Graphics Profile" -ForegroundColor White
    Write-Host "  4. Exit" -ForegroundColor White
    Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function List-Profiles {
    Clear-Screen
    Write-Host "=== Current Custom GPU Settings ===" -ForegroundColor Cyan
    Write-Host ""
    
    $props = Get-Item -Path $RegPath | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    
    if (-not $props) {
        Write-Host "No custom graphics preferences found in the registry." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $index = 1
    $profiles = @()
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $RegPath -Name $p).$p
        
        # Parse value
        # Example format: "GpuPreference=2;" or "GpuPreference=1;DefaultSetting=1;"
        $pref = "Default"
        if ($val -like "*GpuPreference=2*") { $pref = "High Performance" }
        elseif ($val -like "*GpuPreference=1*") { $pref = "Power Saving" }
        elseif ($val -like "*GpuPreference=0*") { $pref = "System Default" }

        Write-Host "  [$index] App: $p" -ForegroundColor White
        Write-Host "       Setting: $pref ($val)" -ForegroundColor Gray
        Write-Host ""
        
        $profiles += [PSCustomObject]@{
            Index = $index
            App = $p
            Value = $val
        }
        $index++
    }
    return $profiles
}

$runningAutomated = $Force -or ($Choice -ne "")

while ($true) {
    Show-Menu
    
    $activeChoice = if ($Choice) { $Choice } elseif ($Force -or [Console]::IsInputRedirected) { "1" } else { Read-Host "Select an option [1-4]" }

    switch ($activeChoice) {
        "1" {
            List-Profiles | Out-Null
            if (-not $runningAutomated -and -not [Console]::IsInputRedirected) {
                Read-Host "Press Enter to return to menu..."
            }
        }
        
        "2" {
            Clear-Screen
            Write-Host "=== Add/Modify Graphics Profile ===" -ForegroundColor Cyan
            Write-Host ""
            
            $rawExe = if ($ExePath) { $ExePath } elseif ([Console]::IsInputRedirected) { "" } else { Read-Host "Enter the absolute path to the game executable (.exe)" }
            
            if ([string]::IsNullOrWhiteSpace($rawExe)) {
                Write-Host "No path entered. Returning to menu..." -ForegroundColor Yellow
                if (-not $runningAutomated) { Start-Sleep -Seconds 1 }
                continue
            }

            # Remove quotes if user dragged and dropped the file
            $cleanExePath = $rawExe.Trim('"').Trim("'")

            if (-not (Test-Path $cleanExePath)) {
                Write-Host ""
                Write-Host "[!] Warning: The path specified was not found locally: $cleanExePath" -ForegroundColor Yellow
                Write-Host "    Make sure the path is correct or double check if the game is installed." -ForegroundColor Yellow
                $confirm = if ($Force -or [Console]::IsInputRedirected) { "y" } else { Read-Host "Do you want to add it anyway? [y/n]" }
                if ($confirm -ne "y") {
                    continue
                }
            }

            Write-Host ""
            Write-Host "Select GPU Preference:" -ForegroundColor White
            Write-Host "  1. High Performance GPU (Discrete / Dedicated graphics card)" -ForegroundColor Green
            Write-Host "  2. Power Saving GPU (Integrated graphics chip)" -ForegroundColor Yellow
            Write-Host "  3. System Default" -ForegroundColor Gray

            $activePrefChoice = if ($PrefChoice) { $PrefChoice } elseif ($Force -or [Console]::IsInputRedirected) { "1" } else { Read-Host "Enter GPU Preference [1-3]" }

            $prefVal = ""
            switch ($activePrefChoice) {
                "1" { $prefVal = "GpuPreference=2;" }
                "2" { $prefVal = "GpuPreference=1;" }
                "3" { $prefVal = "GpuPreference=0;" }
                default {
                    Write-Host "Invalid preference selection." -ForegroundColor Red
                    if (-not $runningAutomated) { Start-Sleep -Seconds 1 }
                    continue
                }
            }

            # Add to registry
            try {
                Set-ItemProperty -Path $RegPath -Name $cleanExePath -Value $prefVal -Force | Out-Null
                Write-Host ""
                Write-Host "[+] Successfully saved preference for $cleanExePath!" -ForegroundColor Green
                Write-Host "    Setting applied: $prefVal" -ForegroundColor Gray
            } catch {
                Write-Host "[!] Error: Failed to write registry value." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Gray
            }
            if (-not $runningAutomated) { Start-Sleep -Seconds 2 }
        }
        
        "3" {
            $profiles = List-Profiles
            if (-not $profiles) {
                if (-not $runningAutomated) { Start-Sleep -Seconds 1 }
                continue
            }
            
            $activeDelChoice = if ($DelChoice) { $DelChoice } elseif ([Console]::IsInputRedirected) { "q" } else { Read-Host "Enter profile number to remove (or 'q' to cancel)" }
            if ($activeDelChoice -eq "q" -or [string]::IsNullOrWhiteSpace($activeDelChoice)) {
                continue
            }

            $selected = $profiles | Where-Object { "$($_.Index)" -eq $activeDelChoice }
            if ($selected) {
                try {
                    Remove-ItemProperty -Path $RegPath -Name $selected.App -Force | Out-Null
                    Write-Host ""
                    Write-Host "[+] Successfully removed graphics profile for $($selected.App)!" -ForegroundColor Green
                } catch {
                    Write-Host "[!] Error: Failed to remove registry value." -ForegroundColor Red
                }
            } else {
                Write-Host "Invalid selection." -ForegroundColor Red
            }
            if (-not $runningAutomated) { Start-Sleep -Seconds 2 }
        }
        
        "4" {
            Write-Host "Exiting..." -ForegroundColor Cyan
            break
        }
        
        default {
            Write-Host "Invalid choice, please select 1-4." -ForegroundColor Red
            if ($runningAutomated) { break }
            Start-Sleep -Seconds 1
        }
    }

    if ($runningAutomated) {
        break
    }
}
