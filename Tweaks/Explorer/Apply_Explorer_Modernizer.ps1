<#
.SYNOPSIS
    WinAurex Windows 11 Explorer & UI Modernizer
.DESCRIPTION
    Applies high-productivity visual and shell tweaks:
    - Restores instant classic right-click context menu (bypasses Windows 11 "Show more options" delay)
    - Enables compact list view in File Explorer
    - Forces file extensions and hidden items to be visible
    - Configures File Explorer to open directly to "This PC"
    - Decouples Start menu search from Bing cloud web search (makes local search instant and offline)
    - Removes Copilot and Widgets clutter from the taskbar
    - Gracefully refreshes the Windows Explorer shell
#>
[CmdletBinding()]
param (
    [switch]$Revert,
    [switch]$Force,
    [switch]$SkipExplorerRestart
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex Windows 11 Explorer & UI Modernizer                 " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

$ClsidPath     = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
$ExplorerAdv   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$SearchPolPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
$SearchPath    = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

if ($Revert) {
    Write-Host "`n[*] Reverting Explorer & UI tweaks to Windows 11 defaults..." -ForegroundColor Yellow
    
    # 1. Restore Windows 11 Modern Context Menu
    if (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}") {
        Remove-Item "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [+] Modern Windows 11 Context Menu restored." -ForegroundColor Green
    }
    
    # 2. Reset Explorer Advanced settings
    if (Test-Path $ExplorerAdv) {
        Set-ItemProperty -Path $ExplorerAdv -Name "CompactMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ExplorerAdv -Name "HideFileExt" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ExplorerAdv -Name "Hidden" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ExplorerAdv -Name "LaunchTo" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ExplorerAdv -Name "ShowCopilotButton" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ExplorerAdv -Name "TaskbarDa" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  [+] Explorer view settings reverted to default." -ForegroundColor Green
    }
    
    # 3. Re-enable Bing search
    if (Test-Path $SearchPolPath) {
        Remove-ItemProperty -Path $SearchPolPath -Name "DisableSearchBoxSuggestions" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $SearchPath) {
        Set-ItemProperty -Path $SearchPath -Name "BingSearchEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  [+] Start menu web search suggestions restored." -ForegroundColor Green
} else {
    Write-Host "`n[*] Applying WinAurex Explorer & UI Productivity Suite..." -ForegroundColor Cyan

    # 1. Classic Right-Click Context Menu (Instant, zero lag)
    if (-not (Test-Path $ClsidPath)) {
        New-Item -Path $ClsidPath -Force | Out-Null
    }
    Set-ItemProperty -Path $ClsidPath -Name "(Default)" -Value "" -Force
    Write-Host "  [+] Classic instant context menu enabled (Windows 10 style)." -ForegroundColor Green

    # 2. Explorer Advanced Tweaks (Compact view, extensions, hidden files, This PC)
    if (-not (Test-Path $ExplorerAdv)) {
        New-Item -Path $ExplorerAdv -Force | Out-Null
    }
    try { Set-ItemProperty -Path $ExplorerAdv -Name "CompactMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $ExplorerAdv -Name "HideFileExt" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $ExplorerAdv -Name "Hidden" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $ExplorerAdv -Name "LaunchTo" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $ExplorerAdv -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $ExplorerAdv -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    Write-Host "  [+] File Explorer: Compact padding, file extensions visible, opens to 'This PC'." -ForegroundColor Green
    Write-Host "  [+] Taskbar: Copilot button and Widgets board removed." -ForegroundColor Green

    # 3. Offline Start Menu Search (Disables Bing web suggestions & telemetry)
    if (-not (Test-Path $SearchPolPath)) {
        New-Item -Path $SearchPolPath -Force | Out-Null
    }
    Set-ItemProperty -Path $SearchPolPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force

    if (-not (Test-Path $SearchPath)) {
        New-Item -Path $SearchPath -Force | Out-Null
    }
    Set-ItemProperty -Path $SearchPath -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $SearchPath -Name "CortanaConsent" -Value 0 -Type DWord -Force
    Write-Host "  [+] Start Search: Decoupled from Bing web search for instant offline file lookups." -ForegroundColor Green

    # 4. Suppress Windows Copilot Policy Globally
    $CopilotPolPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $CopilotPolPath)) {
        New-Item -Path $CopilotPolPath -Force | Out-Null
    }
    Set-ItemProperty -Path $CopilotPolPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
    Write-Host "  [+] Windows Copilot background policy suppressed." -ForegroundColor Green
}

# 5. Refresh Explorer Shell Gracefully
if (-not $SkipExplorerRestart) {
    Write-Host "`n[*] Restarting Windows Explorer shell to apply changes..." -ForegroundColor Yellow
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe
        }
        Write-Host "  [+] Windows Explorer restarted successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Could not restart explorer automatically: $_"
    }
}

Write-Host "`n[SUCCESS] Explorer & UI Modernization complete!" -ForegroundColor Cyan
