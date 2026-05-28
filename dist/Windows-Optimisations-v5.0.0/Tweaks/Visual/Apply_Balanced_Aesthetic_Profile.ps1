# Windows Configuration & Optimization Framework
# Apply Balanced Aesthetic Profile (Tweaks/Visual/Apply_Balanced_Aesthetic_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY BALANCED AESTHETIC PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile speeds up Windows by disabling slow animations and menu delays,"
Write-Host "while keeping UI Transparency (Mica/Acrylic) and Font Smoothing intact."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Visual" -Action "Aborted Balanced Aesthetic Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Visual" -Action "Starting Master Balanced Aesthetic Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/3] Ensuring UI Transparency is Enabled for aesthetics..." -ForegroundColor Cyan
$RegPathTransp = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $RegPathTransp -Name "EnableTransparency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

Write-Host "`n[2/3] Reducing Menu Show Delay for snappier navigation..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Reduce_Menu_Show_Delay.ps1")

Write-Host "`n[3/3] Disabling Unnecessary Taskbar and Window Animations..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Unnecessary_Animations.ps1")

Write-FrameworkLog -ModuleName "Visual" -Action "Completed Master Balanced Aesthetic Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Balanced Aesthetic Profile deployment complete!" -ForegroundColor Green
Write-Host "Restarting Windows Explorer to apply all visual changes immediately..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
