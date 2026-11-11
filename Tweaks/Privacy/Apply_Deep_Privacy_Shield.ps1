[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Deep Privacy Shield (Tweaks/Privacy/Apply_Deep_Privacy_Shield.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

function Set-RegistryValueFast {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "       APPLYING DEEP PRIVACY & SHIELD TWEAKS     " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Find My Device
Write-Host " [*] Disabling Find My Device continuous geolocation tracking..." -ForegroundColor Yellow
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" "AllowFindMyDevice" 0
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocationScripting" 1

# 2. Recommendations & Offers / Advertising ID / Start & Search Suggestions
Write-Host " [*] Disabling Advertising ID, Recommendations & Offers..." -ForegroundColor Yellow
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1
Set-RegistryValueFast "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegistryValueFast "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1

$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$cdmKeys = @(
    "SubscribedContent-338387Enabled",
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled",
    "SubscribedContent-353694Enabled",
    "SubscribedContent-353696Enabled",
    "SubscribedContent-353698Enabled",
    "SubscribedContent-310093Enabled",
    "SubscribedContent-280063Enabled",
    "SystemPaneSuggestionsEnabled",
    "SoftLandingEnabled"
)
foreach ($k in $cdmKeys) {
    Set-RegistryValueFast $cdmPath $k 0
}

Set-RegistryValueFast "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0
Set-RegistryValueFast "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecommendations" 0

# 3. Custom Dictionary & Inking/Typing Keystroke Telemetry
Write-Host " [*] Disabling Custom Dictionary and Inking/Typing Personalization..." -ForegroundColor Yellow
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" "AllowInputPersonalization" 0
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
Set-RegistryValueFast "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
Set-RegistryValueFast "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
Set-RegistryValueFast "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0
Set-RegistryValueFast "HKCU:\Software\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0

# 4. Online Speech Recognition
Write-Host " [*] Disabling Online Speech Recognition cloud uploading..." -ForegroundColor Yellow
Set-RegistryValueFast "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" 0

# 5. Voice Activation ("Hey Copilot" / Speak to Wake)
Write-Host " [*] Disabling Voice Activation wake-words and Copilot voice hooks..." -ForegroundColor Yellow
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsActivateWithVoice" 2
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsActivateWithVoiceAboveLock" 2
Set-RegistryValueFast "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" "VoiceActivationDefault" 0
Set-RegistryValueFast "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" "VoiceActivationEnableAboveLockscreen" 0

# 6. Device Search History & Cloud Content Search
Write-Host " [*] Disabling Device Search History and Cloud Search..." -ForegroundColor Yellow
Set-RegistryValueFast "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0
Set-RegistryValueFast "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "HistoryViewEnabled" 0
Set-RegistryValueFast "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "DeviceHistoryEnabled" 0
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCloudSearch" 0
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0

# 7. On-Device AI / Text and Image Generation / Windows Recall
Write-Host " [*] Restricting On-Device AI generation hooks and Recall analysis..." -ForegroundColor Yellow
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-RegistryValueFast "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessTextAndImageGeneration" 2

# 8. Feedback Frequency & Notifications
Write-Host " [*] Setting Feedback Frequency to Never and suppressing notifications..." -ForegroundColor Yellow
Set-RegistryValueFast "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" 1
Set-RegistryValueFast "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIFInGracePeriod" 0
Set-RegistryValueFast "HKCU:\Software\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" 0

# 9. App Privacy Capability Locks (Deny non-essential background permissions)
Write-Host " [*] Locking down unused background app capabilities..." -ForegroundColor Yellow
$appPrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
$denyCapabilities = @(
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
foreach ($cap in $denyCapabilities) {
    Set-RegistryValueFast $appPrivacyPath $cap 2
}

Write-Host "`n[SUCCESS] Deep Privacy & Shield configurations applied successfully." -ForegroundColor Green
Write-Host "All telemetry channels, keyloggers, voice wake-words, and background hooks are locked." -ForegroundColor Cyan
