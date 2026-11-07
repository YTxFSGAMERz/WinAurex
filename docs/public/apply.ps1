# ==============================================================================
# WinAurex Quick Optimization Runner
# https://winaurex.tech
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host @"
====================================================================
  __        ___             _                            
  \ \      / (_)_ __   / \  _   _ _ __ _____  __         
   \ \ /\ / /| | '_ \ / _ \| | | | '__/ _ \ \/ /         
    \ V  V / | | | | / ___ \ |_| | | |  __/>  <          
     \_/\_/  |_|_| |/_/   \_\__,_|_|  \___/_/\_\         
                                                         
  Windows Engineering & Optimization Framework
  Rollback-Safe * Open Source * C# WPF + PowerShell
  Web Studio: https://winaurex.tech
====================================================================
"@ -ForegroundColor Cyan

Write-Host "`n[+] Checking administrative privileges..." -ForegroundColor Yellow
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "WinAurex requires elevated administrator rights. Please re-run in an elevated PowerShell prompt."
    return
}

Write-Host "[+] Creating System Restore Point for safety..." -ForegroundColor Green
Checkpoint-Computer -Description "WinAurex-Online-Restore" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

Write-Host "[+] Launching WinAurex Quick Setup..." -ForegroundColor Cyan
Write-Host "For full GUI controls, download WinAurex.App.exe at https://winaurex.tech" -ForegroundColor White
