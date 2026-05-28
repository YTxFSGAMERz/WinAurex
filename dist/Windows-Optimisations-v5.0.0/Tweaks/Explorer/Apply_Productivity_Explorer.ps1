# Windows Configuration & Optimization Framework
# Apply Productivity Explorer Orchestrator (Tweaks/Explorer/Apply_Productivity_Explorer.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY PRODUCTIVITY EXPLORER PRESET" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will configure Developer View, This PC launch, Compact View, Classic Context Menus,"
Write-Host "and disable Recent/Frequent file tracking."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Explorer" -Action "Aborted Productivity Explorer Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Explorer" -Action "Starting Master Productivity Explorer Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/5] Configuring Developer View (Extensions, Hidden Files)..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Configure_Developer_View.ps1")

Write-Host "`n[2/5] Setting File Explorer default to 'This PC'..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Set_Launch_To_This_PC.ps1")

Write-Host "`n[3/5] Disabling Recent Files and Frequent Folders tracking..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Recent_Frequent.ps1")

Write-Host "`n[4/5] Enabling Compact View for higher information density..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Enable_Compact_View.ps1")

Write-Host "`n[5/5] Restoring Classic Context Menus..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Restore_Classic_ContextMenu.ps1")

Write-FrameworkLog -ModuleName "Explorer" -Action "Completed Master Productivity Explorer Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Productivity Explorer deployment complete!" -ForegroundColor Green
Write-Host "Restarting Windows Explorer to apply all visual changes immediately..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
