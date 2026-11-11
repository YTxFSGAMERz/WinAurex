[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Restore Privacy Defaults (Tweaks/Privacy/Restore_Privacy_Defaults.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "       RESTORING PRIVACY DEFAULTS                " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Reset Find My Device
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -ErrorAction SilentlyContinue

# 2. Reset Advertising Info & Recommendations
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue

# 3. Reset Inking & Typing
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# 4. Reset App Privacy Capabilities (0 = User in Control)
$appPrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
$capabilities = @(
    "LetAppsActivateWithVoice",
    "LetAppsActivateWithVoiceAboveLock",
    "LetAppsAccessTextAndImageGeneration",
    "LetAppsAccessContacts",
    "LetAppsAccessCalendar",
    "LetAppsAccessTasks",
    "LetAppsAccessCallHistory",
    "LetAppsMakePhoneCalls",
    "LetAppsAccessEmail",
    "LetAppsAccessMessaging",
    "LetAppsAccessRadios",
    "LetAppsGetDiagnosticInfo",
    "LetAppsSyncWithDevices",
    "LetAppsAccessForegroundText",
    "LetAppsAccessAccountInfo"
)
foreach ($cap in $capabilities) {
    Remove-ItemProperty -Path $appPrivacyPath -Name $cap -ErrorAction SilentlyContinue
}

# 5. Reset AI & Copilot Policies
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue

# 6. Reset Feedback Notifications
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -ErrorAction SilentlyContinue

Write-Host "`n[SUCCESS] Privacy settings restored to system defaults." -ForegroundColor Green
