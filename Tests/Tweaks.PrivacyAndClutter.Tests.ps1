<#
.SYNOPSIS
    Tweaks.PrivacyAndClutter.Tests.ps1 - Automated Verification for Deep Privacy, Widgets, & Shell Clutter Tweaks
#>

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $RootDir "Tweaks"))) {
    $RootDir = $PSScriptRoot
}

$passedTests = 0
$failedTests = 0

function Assert-Condition($name, [bool]$condition, $failMessage = "") {
    if ($condition) {
        Write-Host " [PASS] $name" -ForegroundColor Green
        $script:passedTests++
    } else {
        Write-Host " [FAIL] $($name): $failMessage" -ForegroundColor Red
        $script:failedTests++
    }
}

Write-Host "=== RUNNING PRIVACY, WIDGETS & SHELL CLUTTER TEST SUITE ===" -ForegroundColor Cyan

# 1. Verify existence of all new/modified tweak scripts
$scripts = @(
    "Tweaks\Privacy\Apply_Deep_Privacy_Shield.ps1",
    "Tweaks\Privacy\Restore_Privacy_Defaults.ps1",
    "Tweaks\Shell\Disable_Windows_Widgets.ps1",
    "Tweaks\Shell\Enable_Windows_Widgets.ps1",
    "Tweaks\Shell\Disable_Desktop_Spotlight.ps1",
    "Tweaks\Shell\Enable_Desktop_Spotlight.ps1",
    "Tweaks\Sync\Disable_OneDrive_Nag_And_Backup.ps1",
    "Tweaks\Sync\Enable_OneDrive_Nag_And_Backup.ps1"
)

foreach ($s in $scripts) {
    $p = Join-Path $RootDir $s
    Assert-Condition "Script exists: $s" (Test-Path $p)
    if (Test-Path $p) {
        $content = Get-Content -Path $p -Raw
        $invalidRedir = $content | Select-String -Pattern '>\s*nul(l)?\b'
        Assert-Condition "No invalid device redirection in: $s" ($null -eq $invalidRedir)
    }
}

# 2. Verify XAML syntax and control presence in Dashboard.xaml
$xamlPath = Join-Path $RootDir "GUI\Dashboard.xaml"
Assert-Condition "Dashboard.xaml exists" (Test-Path $xamlPath)
if (Test-Path $xamlPath) {
    [xml]$doc = Get-Content -Path $xamlPath
    Assert-Condition "Dashboard.xaml is valid XML" ($null -ne $doc)
    $rawContent = Get-Content -Path $xamlPath -Raw
    Assert-Condition "Card 9 control BtnApplyPrivacyShield present" ($rawContent.Contains('Name="BtnApplyPrivacyShield"'))
    Assert-Condition "Card 9 control BtnRestorePrivacy present" ($rawContent.Contains('Name="BtnRestorePrivacy"'))
    Assert-Condition "Card 10 control BtnKillShellClutter present" ($rawContent.Contains('Name="BtnKillShellClutter"'))
    Assert-Condition "Card 10 control BtnRestoreShellClutter present" ($rawContent.Contains('Name="BtnRestoreShellClutter"'))
}

# 3. Test execution of Deep Privacy Shield
Write-Host "`n[*] Testing Deep Privacy Shield execution..." -ForegroundColor Yellow
$privacyScript = Join-Path $RootDir "Tweaks\Privacy\Apply_Deep_Privacy_Shield.ps1"
& $privacyScript -Force

$findDevice = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -ErrorAction SilentlyContinue).AllowFindMyDevice
Assert-Condition "Find My Device disabled (AllowFindMyDevice = 0)" ($findDevice -eq 0)

$adPolicy = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue).DisabledByGroupPolicy
Assert-Condition "Advertising ID disabled by policy (DisabledByGroupPolicy = 1)" ($adPolicy -eq 1)

$appContacts = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessContacts" -ErrorAction SilentlyContinue).LetAppsAccessContacts
Assert-Condition "Contacts background access Denied (LetAppsAccessContacts = 2)" ($appContacts -eq 2)

$appVoice = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsActivateWithVoice" -ErrorAction SilentlyContinue).LetAppsActivateWithVoice
Assert-Condition "Voice Activation Denied (LetAppsActivateWithVoice = 2)" ($appVoice -eq 2)

$aiAnalysis = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -ErrorAction SilentlyContinue).DisableAIDataAnalysis
Assert-Condition "Windows AI / Recall data analysis disabled (DisableAIDataAnalysis = 1)" ($aiAnalysis -eq 1)

$inputPers = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -ErrorAction SilentlyContinue).AllowInputPersonalization
Assert-Condition "Inking & Typing Personalization disabled (AllowInputPersonalization = 0)" ($inputPers -eq 0)

# 4. Test execution of Widgets Disablement
Write-Host "`n[*] Testing Widgets Disablement execution..." -ForegroundColor Yellow
$widgetScript = Join-Path $RootDir "Tweaks\Shell\Disable_Windows_Widgets.ps1"
& $widgetScript -Force

$dshNews = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue).AllowNewsAndInterests
Assert-Condition "Widgets News & Interests policy disabled (AllowNewsAndInterests = 0)" ($dshNews -eq 0)

$taskbarDa = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue).TaskbarDa
Assert-Condition "TaskbarDa set to 0 (TaskbarDa = 0)" ($taskbarDa -eq 0)

# 5. Test execution of Desktop Spotlight Disablement
Write-Host "`n[*] Testing Desktop Spotlight Disablement execution..." -ForegroundColor Yellow
$spotlightScript = Join-Path $RootDir "Tweaks\Shell\Disable_Desktop_Spotlight.ps1"
& $spotlightScript -Force

$iconGuid = "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}"
$hideIcon = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name $iconGuid -ErrorAction SilentlyContinue).$iconGuid
Assert-Condition "'Learn about this picture' desktop icon hidden (GUID = 1)" ($hideIcon -eq 1)

# 6. Test execution of OneDrive Nag Disablement
Write-Host "`n[*] Testing OneDrive Nag Disablement execution..." -ForegroundColor Yellow
$oneDriveScript = Join-Path $RootDir "Tweaks\Sync\Disable_OneDrive_Nag_And_Backup.ps1"
& $oneDriveScript -Force

$kfmBlock = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptIn" -ErrorAction SilentlyContinue).KFMBlockOptIn
Assert-Condition "OneDrive Known Folder Move 'Turn On Windows Backup' blocked (KFMBlockOptIn = 1)" ($kfmBlock -eq 1)

# 7. Test Idempotency predicate evaluation for Apply_Curated_Safe_Suite
$safeSuite = Join-Path $RootDir "Apply_Curated_Safe_Suite.ps1"
Assert-Condition "Apply_Curated_Safe_Suite.ps1 contains new privacy tweak" ((Get-Content -Path $safeSuite -Raw).Contains("Apply_Deep_Privacy_Shield.ps1"))
Assert-Condition "Apply_Curated_Safe_Suite.ps1 contains desktop spotlight tweak" ((Get-Content -Path $safeSuite -Raw).Contains("Disable_Desktop_Spotlight.ps1"))
Assert-Condition "Apply_Curated_Safe_Suite.ps1 contains OneDrive nag tweak" ((Get-Content -Path $safeSuite -Raw).Contains("Disable_OneDrive_Nag_And_Backup.ps1"))

Write-Host ""
Write-Host "==============================================" -ForegroundColor DarkCyan
Write-Host "TEST RESULTS: Passed: $passedTests | Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "==============================================" -ForegroundColor DarkCyan

if ($failedTests -gt 0) {
    exit 1
}
exit 0
