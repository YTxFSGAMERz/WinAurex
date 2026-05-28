# Windows Configuration & Optimization Framework
# Reduce Menu Show Delay (Tweaks/Visual/Reduce_Menu_Show_Delay.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Visual" -Action "Initiating Menu Show Delay Reduction"

$RegistryPath = "HKCU:\Control Panel\Desktop"
$Name = "MenuShowDelay"

# 1. Snapshot current state for reversibility
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (10ms for fast snapping, default is 400ms)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value "10" -Type String -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Visual" -Action "Reduced Menu Show Delay" -OldValue $CurrentValue -NewValue "10"

Write-Host "`n[SUCCESS] Windows Menu Show Delay reduced for improved responsiveness." -ForegroundColor Green
Start-Sleep -Seconds 1
