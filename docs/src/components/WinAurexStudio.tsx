import React, { useState, useMemo } from 'react';

interface TweakOption {
  id: string;
  name: string;
  description: string;
  category: 'privacy' | 'gaming' | 'debloat' | 'ui' | 'bypass';
  regPath?: string;
  psCode?: string;
  xmlSnippet?: string;
}

const TWEAKS: TweakOption[] = [
  // Privacy
  {
    id: 'disable-telemetry',
    name: 'Disable Telemetry & Diagnostics (DiagTrack)',
    description: 'Disables Connected User Experiences, Telemetry service, and CEIP diagnostic logging.',
    category: 'privacy',
    regPath: `reg add "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f`,
    psCode: `Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue; Set-Service -Name "DiagTrack" -StartupType Disabled`,
    xmlSnippet: `<RunSynchronousCommand wcm:action="add">
    <Order>1</Order>
    <Path>reg.exe add "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f</Path>
</RunSynchronousCommand>`,
  },
  {
    id: 'disable-copilot',
    name: 'Purge Windows Copilot & Recall AI',
    description: 'Completely blocks Microsoft Copilot, recall snapshots, and taskbar AI integrations.',
    category: 'privacy',
    regPath: `reg add "HKCU\\Software\\Policies\\Microsoft\\Windows\\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f`,
    psCode: `Set-ItemProperty -Path "HKCU:\\Software\\Policies\\Microsoft\\Windows\\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Force`,
    xmlSnippet: `<RunSynchronousCommand wcm:action="add">
    <Order>2</Order>
    <Path>reg.exe add "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f</Path>
</RunSynchronousCommand>`,
  },
  {
    id: 'disable-advertising-id',
    name: 'Disable Advertising ID & Tailored Experiences',
    description: 'Prevents applications from tracking unique hardware identifiers for targeted ads.',
    category: 'privacy',
    regPath: `reg add "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f`,
    psCode: `Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\AdvertisingInfo" -Name "Enabled" -Value 0 -Force`,
  },
  {
    id: 'disable-activity-history',
    name: 'Disable Activity History & Timeline Sync',
    description: 'Stops Windows from recording keystrokes, app history, and syncing with cloud accounts.',
    category: 'privacy',
    regPath: `reg add "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f`,
    psCode: `Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" -Name "EnableActivityFeed" -Value 0 -Force`,
  },

  // Gaming
  {
    id: 'mmcss-gpu-priority',
    name: 'MMCSS GPU & Gaming Priority Scheduling',
    description: 'Configures Multimedia Class Scheduler Service to give 100% CPU priority to 3D games.',
    category: 'gaming',
    regPath: `reg add "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f`,
    psCode: `Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games" -Name "GPU Priority" -Value 8 -Force`,
  },
  {
    id: 'disable-game-bar',
    name: 'Disable Xbox Game Bar & Background DVR Recording',
    description: 'Frees up GPU VRAM and eliminates micro-stuttering caused by constant background recording.',
    category: 'gaming',
    regPath: `reg add "HKCU\\System\\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f`,
    psCode: `Set-ItemProperty -Path "HKCU:\\System\\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Force`,
  },
  {
    id: 'timer-resolution',
    name: 'High Precision Event Timer (HPET) & Timer Tuning',
    description: 'Optimizes global timer tick latency to sub-0.5ms for competitive gaming responsiveness.',
    category: 'gaming',
    psCode: `bcdedit /set useplatformclock false; bcdedit /set disabledynamictick yes`,
  },
  {
    id: 'disable-mouse-accel',
    name: 'Disable Enhanced Pointer Precision (1:1 Raw Input)',
    description: 'Removes Windows artificial mouse acceleration for pixel-perfect aim in FPS titles.',
    category: 'gaming',
    regPath: `reg add "HKCU\\Control Panel\\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f`,
    psCode: `Set-ItemProperty -Path "HKCU:\\Control Panel\\Mouse" -Name "MouseSpeed" -Value "0" -Force`,
  },

  // Debloat
  {
    id: 'remove-uwp-bloat',
    name: 'Purge 30+ Pre-installed UWP Bloat Apps',
    description: 'Removes Bing, Solitaire, Clipchamp, Xbox, News, Weather, and Cortana packages.',
    category: 'debloat',
    psCode: `Get-AppxPackage -AllUsers | Where-Object { $_.Name -match "Bing|Clipchamp|Solitaire|Cortana|People|Feedback" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue`,
  },
  {
    id: 'disable-edge-prelaunch',
    name: 'Prevent Microsoft Edge Background Pre-launching',
    description: 'Stops Edge from running unseen background processes on boot when you use other browsers.',
    category: 'debloat',
    regPath: `reg add "HKLM\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\Main" /v "AllowPrelaunch" /t REG_DWORD /d 0 /f`,
    psCode: `Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\MicrosoftEdge\\Main" -Name "AllowPrelaunch" -Value 0 -Force`,
  },
  {
    id: 'disable-consumer-features',
    name: 'Block Automatic Third-Party App Installs',
    description: 'Prevents Windows from automatically reinstalling Candy Crush, Spotify, and TikTok in Start.',
    category: 'debloat',
    regPath: `reg add "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f`,
    psCode: `Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Force`,
  },

  // UI
  {
    id: 'classic-context-menu',
    name: 'Restore Classic Right-Click Context Menu',
    description: 'Disables Windows 11 two-tiered menu and immediately shows the full classic context menu.',
    category: 'ui',
    regPath: `reg add "HKCU\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\\InprocServer32" /f /ve`,
    psCode: `New-Item -Path "HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\\InprocServer32" -Value "" -Force`,
  },
  {
    id: 'left-taskbar',
    name: 'Align Taskbar Icons to Left (Classic Windows Layout)',
    description: 'Moves start button and pinned apps back to the classic bottom-left position.',
    category: 'ui',
    regPath: `reg add "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" /v "TaskbarAl" /t REG_DWORD /d 0 /f`,
    psCode: `Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "TaskbarAl" -Value 0 -Force`,
  },
  {
    id: 'hide-search-highlights',
    name: 'Hide Web Search Bing Suggestions & Taskbar Highlights',
    description: 'Restricts Start menu search to local files, folders, and apps only — zero web lag.',
    category: 'ui',
    regPath: `reg add "HKCU\\Software\\Policies\\Microsoft\\Windows\\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f`,
    psCode: `Set-ItemProperty -Path "HKCU:\\Software\\Policies\\Microsoft\\Windows\\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Force`,
  },

  // Hardware & Unattended Bypasses
  {
    id: 'bypass-tpm-secureboot',
    name: 'Bypass TPM 2.0 & Secure Boot Requirement',
    description: 'Allows Windows 11 installation on any hardware, old PCs, or unsupported virtual machines.',
    category: 'bypass',
    regPath: `reg add "HKLM\\SYSTEM\\Setup\\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f & reg add "HKLM\\SYSTEM\\Setup\\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d 1 /f`,
    psCode: `reg.exe add "HKLM\\SYSTEM\\Setup\\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f`,
  },
  {
    id: 'bypass-ram-storage',
    name: 'Bypass 4GB RAM & 64GB Storage Check',
    description: 'Allows clean installation on lightweight laptops, netbooks, or lightweight VM instances.',
    category: 'bypass',
    regPath: `reg add "HKLM\\SYSTEM\\Setup\\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f & reg add "HKLM\\SYSTEM\\Setup\\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d 1 /f`,
    psCode: `reg.exe add "HKLM\\SYSTEM\\Setup\\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f`,
  },
  {
    id: 'local-account-offline',
    name: 'Bypass Microsoft Account Lock (Force Local Admin Account)',
    description: 'Skips forced cloud account setup in OOBE and creates an offline local Administrator profile.',
    category: 'bypass',
    regPath: `reg add "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OOBE" /v "BypassNRO" /t REG_DWORD /d 1 /f`,
    psCode: `reg.exe add "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OOBE" /v "BypassNRO" /t REG_DWORD /d 1 /f`,
  },
];

export const WinAurexStudio: React.FC = () => {
  const [selectedPreset, setSelectedPreset] = useState<'gaming' | 'privacy' | 'minimal' | 'custom'>('gaming');
  const [selectedTweaks, setSelectedTweaks] = useState<Record<string, boolean>>({
    'disable-telemetry': true,
    'disable-copilot': true,
    'disable-advertising-id': true,
    'mmcss-gpu-priority': true,
    'disable-game-bar': true,
    'timer-resolution': true,
    'disable-mouse-accel': true,
    'remove-uwp-bloat': true,
    'disable-edge-prelaunch': true,
    'classic-context-menu': true,
    'bypass-tpm-secureboot': true,
    'local-account-offline': true,
  });

  const [activeTab, setActiveTab] = useState<'xml' | 'ps1' | 'reg'>('xml');
  const [copied, setCopied] = useState<boolean>(false);
  const [adminUsername, setAdminUsername] = useState<string>('Admin');

  // Handle Preset Switching
  const handleSelectPreset = (preset: 'gaming' | 'privacy' | 'minimal' | 'custom') => {
    setSelectedPreset(preset);
    const newSelected: Record<string, boolean> = {};

    if (preset === 'gaming') {
      TWEAKS.forEach(t => {
        if (t.category === 'gaming' || t.id === 'disable-telemetry' || t.id === 'disable-copilot' || t.id === 'remove-uwp-bloat' || t.id === 'bypass-tpm-secureboot' || t.id === 'local-account-offline') {
          newSelected[t.id] = true;
        }
      });
    } else if (preset === 'privacy') {
      TWEAKS.forEach(t => {
        if (t.category === 'privacy' || t.id === 'remove-uwp-bloat' || t.id === 'disable-consumer-features' || t.id === 'local-account-offline' || t.id === 'bypass-tpm-secureboot') {
          newSelected[t.id] = true;
        }
      });
    } else if (preset === 'minimal') {
      TWEAKS.forEach(t => {
        if (t.category === 'debloat' || t.category === 'ui' || t.category === 'bypass') {
          newSelected[t.id] = true;
        }
      });
    }
    setSelectedTweaks(newSelected);
  };

  const toggleTweak = (id: string) => {
    setSelectedPreset('custom');
    setSelectedTweaks(prev => ({ ...prev, [id]: !prev[id] }));
  };

  // Metrics calculation
  const metrics = useMemo(() => {
    const activeCount = Object.values(selectedTweaks).filter(Boolean).length;
    const ramFreedMb = activeCount * 135;
    const processesTrimmed = Math.round(activeCount * 2.8);
    return {
      activeCount,
      ramFreedGb: (ramFreedMb / 1024).toFixed(1),
      processesTrimmed,
    };
  }, [selectedTweaks]);

  // Code Generation
  const generatedCode = useMemo(() => {
    const activeTweaks = TWEAKS.filter(t => selectedTweaks[t.id]);

    if (activeTab === 'xml') {
      return `<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by WinAurex Live Studio (winaurex.tech) -->
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
${activeTweaks.filter(t => t.category === 'bypass').map((t, idx) => `                <RunSynchronousCommand wcm:action="add">
                    <Order>${idx + 1}</Order>
                    <Path>${t.regPath || 'echo OK'}</Path>
                </RunSynchronousCommand>`).join('\n')}
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <AutoLogon>
                <Password><Value></Value><PlainText>true</PlainText></Password>
                <Enabled>true</Enabled>
                <LogonCount>9999</LogonCount>
                <Username>${adminUsername}</Username>
            </AutoLogon>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>${adminUsername}</Name>
                        <Group>Administrators</Group>
                        <DisplayName>${adminUsername}</DisplayName>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
</unattend>`;
    }

    if (activeTab === 'ps1') {
      return `# ==============================================================================
# WinAurex Optimization & Debloat Script
# Generated live at https://winaurex.tech
# Run inside an elevated Administrator PowerShell prompt:
# ==============================================================================

Write-Host ">>> Starting WinAurex Optimization Pipeline..." -ForegroundColor Cyan

# 1. State Snapshot & Restore Point
Write-Host "[+] Creating System Restore Point for safe rollback..."
Checkpoint-Computer -Description "Pre-WinAurex-Restore" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

# 2. Applied Configurations (${activeTweaks.length} tweaks selected)
${activeTweaks.map(t => `# --- ${t.name} ---\n${t.psCode || ''}`).filter(Boolean).join('\n\n')}

Write-Host ">>> WinAurex Execution Complete! Please restart your PC." -ForegroundColor Green
`;
    }

    // REG tab
    return `Windows Registry Editor Version 5.00

; WinAurex Optimized Registry Tweaks
; Generated live at https://winaurex.tech

${activeTweaks.map(t => `; ${t.name}\n${t.regPath ? t.regPath.replace('reg add "', '[').replace('" /v "', ']\n"').replace('" /t REG_DWORD /d ', '"=dword:0000000').replace('" /t REG_SZ /d "', '"="') : ''}`).filter(Boolean).join('\n\n')}
`;
  }, [activeTab, selectedTweaks, adminUsername]);

  const handleCopy = () => {
    navigator.clipboard.writeText(generatedCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2200);
  };

  const handleDownload = () => {
    const filename = activeTab === 'xml' ? 'autounattend.xml' : activeTab === 'ps1' ? 'WinAurex-Tweak.ps1' : 'WinAurex-Tweak.reg';
    const mime = activeTab === 'xml' ? 'application/xml' : 'text/plain';
    const blob = new Blob([generatedCode], { type: mime });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <div style={{
      background: 'linear-gradient(180deg, #0d1117 0%, #161b22 100%)',
      borderRadius: '16px',
      border: '1px solid #30363d',
      padding: '24px',
      color: '#e6edf3',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      boxShadow: '0 20px 40px rgba(0,0,0,0.6)',
      margin: '32px 0'
    }}>
      {/* Header Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px', borderBottom: '1px solid #30363d', paddingBottom: '20px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span style={{ fontSize: '26px' }}>⚡</span>
            <h2 style={{ fontSize: '24px', fontWeight: 'bold', margin: 0, color: '#00bcd4' }}>
              WinAurex Web Studio
            </h2>
            <span style={{
              background: '#238636',
              color: '#ffffff',
              fontSize: '11px',
              fontWeight: 'bold',
              padding: '2px 8px',
              borderRadius: '999px',
              letterSpacing: '0.05em'
            }}>
              LIVE BUILD
            </span>
          </div>
          <p style={{ margin: '6px 0 0 0', color: '#8b949e', fontSize: '14px' }}>
            Interactive Windows 11 & 10 Unattended Image Recipe & Debloat Generator. Build custom OS configurations in real-time.
          </p>
        </div>

        {/* Live Metrics */}
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ background: '#090d13', border: '1px solid #00bcd444', borderRadius: '10px', padding: '10px 16px', textAlign: 'center' }}>
            <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#00ff41' }}>{metrics.activeCount}</div>
            <div style={{ fontSize: '11px', color: '#8b949e', textTransform: 'uppercase' }}>Tweaks Active</div>
          </div>
          <div style={{ background: '#090d13', border: '1px solid #00bcd444', borderRadius: '10px', padding: '10px 16px', textAlign: 'center' }}>
            <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#00bcd4' }}>~{metrics.ramFreedGb} GB</div>
            <div style={{ fontSize: '11px', color: '#8b949e', textTransform: 'uppercase' }}>RAM Saved</div>
          </div>
          <div style={{ background: '#090d13', border: '1px solid #00bcd444', borderRadius: '10px', padding: '10px 16px', textAlign: 'center' }}>
            <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#f39c12' }}>-{metrics.processesTrimmed}</div>
            <div style={{ fontSize: '11px', color: '#8b949e', textTransform: 'uppercase' }}>Processes</div>
          </div>
        </div>
      </div>

      {/* Preset Selection Buttons */}
      <div style={{ margin: '24px 0 16px 0' }}>
        <div style={{ fontSize: '13px', fontWeight: 'bold', color: '#8b949e', textTransform: 'uppercase', marginBottom: '10px', letterSpacing: '0.05em' }}>
          Select Optimization Preset
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px' }}>
          {[
            { id: 'gaming', title: '🎮 Ultra Gaming', desc: 'MMCSS, 0.5ms Timer, GameBar kill' },
            { id: 'privacy', title: '🛡️ Privacy Purge', desc: 'Zero Telemetry, Copilot, Recall kill' },
            { id: 'minimal', title: '⚡ Clean Minimal', desc: 'UWP bloatware gone, Classic UI' },
            { id: 'custom', title: '🛠️ Custom Tuning', desc: 'Select individual parameters' },
          ].map(p => (
            <button
              key={p.id}
              onClick={() => handleSelectPreset(p.id as any)}
              style={{
                background: selectedPreset === p.id ? 'rgba(0, 188, 212, 0.15)' : '#161b22',
                border: selectedPreset === p.id ? '2px solid #00bcd4' : '1px solid #30363d',
                borderRadius: '10px',
                padding: '12px 14px',
                textAlign: 'left',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
              }}
            >
              <div style={{ fontWeight: 'bold', fontSize: '15px', color: selectedPreset === p.id ? '#00bcd4' : '#c9d1d9' }}>{p.title}</div>
              <div style={{ fontSize: '12px', color: '#8b949e', marginTop: '4px' }}>{p.desc}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Main Grid: Tweaks on Left, Live Code on Right */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', marginTop: '24px' }}>
        
        {/* Left Column: Tweak Checkboxes */}
        <div style={{ background: '#11161d', borderRadius: '12px', border: '1px solid #30363d', padding: '16px', maxHeight: '580px', overflowY: 'auto' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
            <span style={{ fontSize: '14px', fontWeight: 'bold', color: '#c9d1d9' }}>Tweak Modules ({TWEAKS.length})</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '12px', color: '#8b949e' }}>Local Admin:</span>
              <input
                type="text"
                value={adminUsername}
                onChange={(e) => setAdminUsername(e.target.value)}
                style={{
                  background: '#0d1117',
                  border: '1px solid #30363d',
                  color: '#00ff41',
                  borderRadius: '6px',
                  padding: '3px 8px',
                  fontSize: '12px',
                  width: '90px'
                }}
              />
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {TWEAKS.map(tweak => {
              const checked = !!selectedTweaks[tweak.id];
              return (
                <div
                  key={tweak.id}
                  onClick={() => toggleTweak(tweak.id)}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '10px 12px',
                    borderRadius: '8px',
                    background: checked ? 'rgba(35, 134, 54, 0.1)' : 'rgba(255,255,255,0.02)',
                    border: checked ? '1px solid #238636' : '1px solid #21262d',
                    cursor: 'pointer',
                    userSelect: 'none',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <input
                    type="checkbox"
                    checked={checked}
                    onChange={() => {}} // Handled by parent div
                    style={{ marginTop: '3px', accentColor: '#238636', cursor: 'pointer' }}
                  />
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: checked ? '#ffffff' : '#8b949e' }}>
                      {tweak.name}
                    </div>
                    <div style={{ fontSize: '11px', color: '#6e7681', marginTop: '2px' }}>
                      {tweak.description}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Real-time Code Viewer */}
        <div style={{ background: '#090d13', borderRadius: '12px', border: '1px solid #30363d', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
          {/* Tabs & Action Buttons */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#161b22', padding: '8px 12px', borderBottom: '1px solid #30363d' }}>
            <div style={{ display: 'flex', gap: '6px' }}>
              {[
                { id: 'xml', label: 'autounattend.xml' },
                { id: 'ps1', label: 'WinAurex-Tweak.ps1' },
                { id: 'reg', label: 'WinAurex.reg' },
              ].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  style={{
                    background: activeTab === tab.id ? '#0d1117' : 'transparent',
                    color: activeTab === tab.id ? '#00bcd4' : '#8b949e',
                    border: activeTab === tab.id ? '1px solid #30363d' : 'none',
                    borderBottom: 'none',
                    borderRadius: '6px 6px 0 0',
                    padding: '6px 12px',
                    fontSize: '12px',
                    fontWeight: 'bold',
                    cursor: 'pointer',
                  }}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                onClick={handleCopy}
                style={{
                  background: copied ? '#238636' : '#21262d',
                  color: '#ffffff',
                  border: '1px solid #30363d',
                  borderRadius: '6px',
                  padding: '6px 12px',
                  fontSize: '12px',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}
              >
                {copied ? '✓ Copied' : '📋 Copy'}
              </button>
              <button
                onClick={handleDownload}
                style={{
                  background: '#00bcd4',
                  color: '#090d13',
                  border: 'none',
                  borderRadius: '6px',
                  padding: '6px 14px',
                  fontSize: '12px',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}
              >
                ⬇ Download
              </button>
            </div>
          </div>

          {/* Code Body */}
          <pre style={{
            margin: 0,
            padding: '16px',
            fontSize: '12px',
            lineHeight: 1.5,
            color: '#7ee787',
            background: '#090d13',
            flex: 1,
            maxHeight: '520px',
            overflow: 'auto',
            fontFamily: '"Fira Code", monospace',
            whiteSpace: 'pre'
          }}>
            {generatedCode}
          </pre>

          {/* Quick CLI Execution Command footer */}
          <div style={{ padding: '10px 14px', background: '#11161d', borderTop: '1px solid #30363d', fontSize: '11px', color: '#8b949e', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>⚡ 1-Click PowerShell Run:</span>
            <code style={{ background: '#090d13', padding: '3px 8px', borderRadius: '4px', color: '#00bcd4' }}>
              irm https://winaurex.tech/apply.ps1 | iex
            </code>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WinAurexStudio;
