# ==============================================================================
# SCRIPT: Manage Per-Game GPU Selection
# TARGET SYSTEM: Windows 10 & Windows 11
# DESCRIPTION: Interactively assigns specific games or applications to either the
#              High Performance (discrete) GPU or Power Saving (integrated) GPU.
#              Also lists and removes configured application preferences.
# SAFETY LEVEL: Safe & Fully Reversible
# ==============================================================================

$Host.UI.RawUI.WindowTitle = "DirectX Graphics Preference Manager"

# Clear Screen & Print Beautiful Title
Clear-Host
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
    Clear-Host
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

while ($true) {
    Show-Menu
    $choice = Read-Host "Choose an option (1-4)"
    
    switch ($choice) {
        "1" {
            List-Profiles | Out-Null
            Read-Host "Press Enter to return to menu..."
            Clear-Host
        }
        
        "2" {
            Clear-Host
            Write-Host "=== Add/Modify Graphics Profile ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Enter the absolute path to the game executable (.exe):" -ForegroundColor Gray
            $exePath = Read-Host "Path"
            
            # Remove quotes if user dragged and dropped the file
            $exePath = $exePath.Trim('"').Trim("'")

            if (-not (Test-Path $exePath)) {
                Write-Host ""
                Write-Host "[!] Warning: The path specified was not found locally." -ForegroundColor Yellow
                Write-Host "    Make sure the path is correct or double check if the game is installed." -ForegroundColor Yellow
                $confirm = Read-Host "Do you want to save it anyway? (y/n)"
                if ($confirm -ne "y") {
                    Clear-Host
                    continue
                }
            }

            Write-Host ""
            Write-Host "Select GPU Preference:" -ForegroundColor White
            Write-Host "  1. High Performance GPU (Discrete / Dedicated graphics card)" -ForegroundColor Green
            Write-Host "  2. Power Saving GPU (Integrated graphics chip)" -ForegroundColor Yellow
            Write-Host "  3. System Default" -ForegroundColor Gray
            $prefChoice = Read-Host "Choice (1-3)"

            $prefVal = ""
            switch ($prefChoice) {
                "1" { $prefVal = "GpuPreference=2;" }
                "2" { $prefVal = "GpuPreference=1;" }
                "3" { $prefVal = "GpuPreference=0;" }
                default {
                    Write-Host "Invalid preference selection." -ForegroundColor Red
                    Read-Host "Press Enter to return..."
                    Clear-Host
                    continue
                }
            }

            # Add to registry
            try {
                Set-ItemProperty -Path $RegPath -Name $exePath -Value $prefVal -Force | Out-Null
                Write-Host ""
                Write-Host "[+] Successfully saved preference for $exePath!" -ForegroundColor Green
                Write-Host "    Setting applied: $prefVal" -ForegroundColor Gray
            } catch {
                Write-Host "[!] Error: Failed to write registry value." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Gray
            }
            Write-Host ""
            Read-Host "Press Enter to return..."
            Clear-Host
        }
        
        "3" {
            $profiles = List-Profiles
            if (-not $profiles) {
                Read-Host "Press Enter to return..."
                Clear-Host
                continue
            }
            
            $delChoice = Read-Host "Select profile number to remove (or 'q' to cancel)"
            if ($delChoice -eq "q") {
                Clear-Host
                continue
            }

            $selected = $profiles | Where-Object { $_.Index -eq $delChoice }
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
            Write-Host ""
            Read-Host "Press Enter to return..."
            Clear-Host
        }
        
        "4" {
            Write-Host "Exiting..." -ForegroundColor Cyan
            exit
        }
        
        default {
            Write-Host "Invalid choice, please select 1-4." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Clear-Host
        }
    }
}
