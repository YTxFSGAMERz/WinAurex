# Windows Configuration & Optimization Framework
# Enable Hardware Accelerated GPU Scheduling (Tweaks/GPU/Enable_Hardware_Accelerated_GPU_Scheduling.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "GPU" -Action "Initiating Hardware Accelerated GPU Scheduling Enablement"

$RegistryPath = "HKLM:\System\CurrentControlSet\Control\GraphicsDrivers"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
$Name = "HwSchMode"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (2 = Enabled, 1 = Disabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 2 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "GPU" -Action "Enabled Hardware Accelerated GPU Scheduling" -OldValue $CurrentValue -NewValue "2"

Write-Host "`n[SUCCESS] Hardware Accelerated GPU Scheduling (HAGS) is now enabled." -ForegroundColor Green
Write-Host "This offloads scheduling from the CPU to the GPU, lowering latency and improving FPS." -ForegroundColor Yellow
Write-Host "A system reboot is required for this to take effect." -ForegroundColor Red
Start-Sleep -Seconds 1
