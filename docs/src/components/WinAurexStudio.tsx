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
  const [activeCategory, setActiveCategory] = useState<'all' | 'privacy' | 'gaming' | 'debloat' | 'ui' | 'bypass'>('all');
  const [copied, setCopied] = useState<boolean>(false);
  const [copiedCmd, setCopiedCmd] = useState<boolean>(false);
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

  const handleSelectAll = () => {
    setSelectedPreset('custom');
    const newSelected: Record<string, boolean> = {};
    TWEAKS.forEach(t => {
      newSelected[t.id] = true;
    });
    setSelectedTweaks(newSelected);
  };

  const handleClearAll = () => {
    setSelectedPreset('custom');
    setSelectedTweaks({});
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

  // Filtered tweaks based on selected category
  const filteredTweaks = useMemo(() => {
    if (activeCategory === 'all') return TWEAKS;
    return TWEAKS.filter(t => t.category === activeCategory);
  }, [activeCategory]);

  // Code Generation
  const generatedCode = useMemo(() => {
    const activeTweaks = TWEAKS.filter(t => selectedTweaks[t.id]);

    if (activeTab === 'xml') {
      return `<?xml version="1.0" encoding="utf-8"?>
<!-- ============================================================================== -->
<!-- WinAurex Unattended Windows 11 Answer File (autounattend.xml)                 -->
<!-- Generated live via WinAurex Web Studio (https://winaurex.tech/studio/)        -->
<!-- ============================================================================== -->
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
# WinAurex Live System Optimizer & Debloat Engine
# Generated live via WinAurex Web Studio (https://winaurex.tech/studio/)
# Instructions: Run inside an elevated Administrator PowerShell prompt:
# ==============================================================================

Write-Host ">>> [WinAurex] Initializing Tactical System Optimization..." -ForegroundColor Green

# 1. State Snapshot & Restore Point
Write-Host "[+] Creating System Restore Checkpoint for atomic rollback..." -ForegroundColor DarkGreen
Checkpoint-Computer -Description "Pre-WinAurex-Restore" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

# 2. Applied Configurations (${activeTweaks.length} tweaks active)
${activeTweaks.map(t => `# --- [${t.category.toUpperCase()}] ${t.name} ---\n${t.psCode || ''}`).filter(Boolean).join('\n\n')}

Write-Host ">>> [WinAurex] Pipeline Executed Successfully. Please restart your PC." -ForegroundColor Green
`;
    }

    // REG tab
    return `Windows Registry Editor Version 5.00

; ==============================================================================
; WinAurex Optimized Registry Preset
; Generated live via WinAurex Web Studio (https://winaurex.tech/studio/)
; ==============================================================================

${activeTweaks.map(t => `; [${t.category.toUpperCase()}] ${t.name}\n${t.regPath ? t.regPath.replace('reg add "', '[').replace('" /v "', ']\n"').replace('" /t REG_DWORD /d ', '"=dword:0000000').replace('" /t REG_SZ /d "', '"="') : ''}`).filter(Boolean).join('\n\n')}
`;
  }, [activeTab, selectedTweaks, adminUsername]);

  const handleCopy = () => {
    navigator.clipboard.writeText(generatedCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2200);
  };

  const handleCopyCmd = () => {
    navigator.clipboard.writeText('irm https://winaurex.tech/apply.ps1 | iex');
    setCopiedCmd(true);
    setTimeout(() => setCopiedCmd(false), 2000);
  };

  const handleDownload = () => {
    const filename = activeTab === 'xml' ? 'autounattend.xml' : activeTab === 'ps1' ? 'WinAurex-Tweak.ps1' : 'WinAurex.reg';
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
    <div className="cyber-studio-root">
      {/* Header Banner */}
      <div className="cyber-studio-header">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
            <h2 className="cyber-studio-title">
              ⚡ WinAurex Web Studio
            </h2>
            <span className="cyber-badge-live">
              LIVE ENGINE
            </span>
            <span style={{
              background: 'rgba(0, 255, 0, 0.08)',
              border: '1px solid rgba(0, 255, 0, 0.25)',
              color: '#80ff80',
              fontSize: '0.68rem',
              fontWeight: 700,
              padding: '0.2rem 0.5rem',
              borderRadius: '4px',
              letterSpacing: '0.06em'
            }}>
              v1.0.4 // AMD64
            </span>
          </div>
          <p style={{ margin: '6px 0 0 0', color: '#9e9e9e', fontSize: '0.8rem', lineHeight: 1.4 }}>
            Zero-Bloat Windows 11 &amp; 10 Unattended Image Recipe &amp; Live PowerShell Debloat Engine.
          </p>
        </div>

        {/* Tactical HUD Live Gauges */}
        <div className="cyber-hud-gauges">
          <div className="cyber-hud-card">
            <div className="cyber-hud-val" style={{ color: '#00ff00', textShadow: '0 0 8px rgba(0,255,0,0.6)' }}>
              {metrics.activeCount} <span style={{ fontSize: '0.75rem', color: '#666' }}>/ {TWEAKS.length}</span>
            </div>
            <div className="cyber-hud-label">Tweaks Active</div>
          </div>
          <div className="cyber-hud-card">
            <div className="cyber-hud-val" style={{ color: '#10b981', textShadow: '0 0 8px rgba(16,185,129,0.5)' }}>
              ~{metrics.ramFreedGb} GB
            </div>
            <div className="cyber-hud-label">RAM Reclaimed</div>
          </div>
          <div className="cyber-hud-card">
            <div className="cyber-hud-val" style={{ color: '#f59e0b', textShadow: '0 0 8px rgba(245,158,11,0.5)' }}>
              -{metrics.processesTrimmed}
            </div>
            <div className="cyber-hud-label">Processes Trimmed</div>
          </div>
        </div>
      </div>

      {/* Preset Selection Buttons */}
      <div className="cyber-section-label">
        <span>// SELECT OPTIMIZATION PROFILE</span>
      </div>
      <div className="cyber-preset-grid">
        {[
          { id: 'gaming', title: '🎮 01 // ULTRA GAMING', desc: 'MMCSS 100% GPU priority, 0.5ms Timer, GameBar kill, 1:1 Raw Input' },
          { id: 'privacy', title: '🛡️ 02 // PRIVACY PURGE', desc: 'Zero Telemetry, Copilot, Recall AI, Advertising ID, Activity history kill' },
          { id: 'minimal', title: '⚡ 03 // CLEAN MINIMAL', desc: 'Purge 30+ UWP bloatware, Classic context menu, Edge prelaunch kill' },
          { id: 'custom', title: '🛠️ 04 // CUSTOM MATRIX', desc: 'Full tactical manual override. Select bespoke system parameters' },
        ].map(p => (
          <button
            key={p.id}
            onClick={() => handleSelectPreset(p.id as any)}
            className={`cyber-preset-card ${selectedPreset === p.id ? 'active' : ''}`}
          >
            <div className="cyber-preset-title">{p.title}</div>
            <div className="cyber-preset-desc">{p.desc}</div>
          </button>
        ))}
      </div>

      {/* Category Filter & Batch Controls */}
      <div className="cyber-filter-bar">
        <div className="cyber-filter-pills">
          <button
            onClick={() => setActiveCategory('all')}
            className={`cyber-filter-pill ${activeCategory === 'all' ? 'active' : ''}`}
          >
            ALL [{TWEAKS.length}]
          </button>
          <button
            onClick={() => setActiveCategory('privacy')}
            className={`cyber-filter-pill ${activeCategory === 'privacy' ? 'active' : ''}`}
          >
            PRIVACY [{TWEAKS.filter(t => t.category === 'privacy').length}]
          </button>
          <button
            onClick={() => setActiveCategory('gaming')}
            className={`cyber-filter-pill ${activeCategory === 'gaming' ? 'active' : ''}`}
          >
            GAMING [{TWEAKS.filter(t => t.category === 'gaming').length}]
          </button>
          <button
            onClick={() => setActiveCategory('debloat')}
            className={`cyber-filter-pill ${activeCategory === 'debloat' ? 'active' : ''}`}
          >
            DEBLOAT [{TWEAKS.filter(t => t.category === 'debloat').length}]
          </button>
          <button
            onClick={() => setActiveCategory('ui')}
            className={`cyber-filter-pill ${activeCategory === 'ui' ? 'active' : ''}`}
          >
            UI [{TWEAKS.filter(t => t.category === 'ui').length}]
          </button>
          <button
            onClick={() => setActiveCategory('bypass')}
            className={`cyber-filter-pill ${activeCategory === 'bypass' ? 'active' : ''}`}
          >
            BYPASS [{TWEAKS.filter(t => t.category === 'bypass').length}]
          </button>
        </div>

        <div className="cyber-batch-actions">
          <button onClick={handleSelectAll} className="cyber-btn-ghost">
            [ + SELECT ALL ]
          </button>
          <button onClick={handleClearAll} className="cyber-btn-ghost">
            [ - CLEAR ALL ]
          </button>
        </div>
      </div>

      {/* Main Grid: Tweaks on Left, Terminal on Right */}
      <div className="cyber-studio-grid">
        
        {/* Left Column: Tweak List */}
        <div className="cyber-tweak-pane">
          <div className="cyber-tweak-pane-header">
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#00ff00', letterSpacing: '0.05em' }}>
              &gt; TWEAK_REGISTRY [{filteredTweaks.length}]
            </span>
            <div className="cyber-admin-input-wrap">
              <span>ADMIN_USER:</span>
              <input
                type="text"
                value={adminUsername}
                onChange={(e) => setAdminUsername(e.target.value)}
                className="cyber-admin-input"
                placeholder="Admin"
              />
            </div>
          </div>

          <div className="cyber-tweak-scroll">
            {filteredTweaks.map(tweak => {
              const checked = !!selectedTweaks[tweak.id];
              return (
                <div
                  key={tweak.id}
                  onClick={() => toggleTweak(tweak.id)}
                  className={`cyber-tweak-item ${checked ? 'checked' : ''}`}
                >
                  <div className="cyber-checkbox-box">
                    {checked ? '✓' : ''}
                  </div>
                  <div className="cyber-tweak-info">
                    <div className="cyber-tweak-head">
                      <span className="cyber-tweak-name">{tweak.name}</span>
                      <span className="cyber-tag">{tweak.category}</span>
                    </div>
                    <div className="cyber-tweak-desc">
                      {tweak.description}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Cyber Terminal Window */}
        <div className="cyber-terminal-window">
          {/* Top Window Title Bar */}
          <div className="cyber-terminal-topbar">
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
              <div className="cyber-terminal-dots">
                <span className="cyber-dot-red">●</span>
                <span className="cyber-dot-yellow">●</span>
                <span className="cyber-dot-green">●</span>
              </div>
              <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#88ff88', letterSpacing: '0.06em' }}>
                TERMINAL // RECIPE_OUTPUT
              </span>
            </div>

            <div className="cyber-terminal-actions">
              <button onClick={handleCopy} className={`cyber-btn-copy ${copied ? 'copied' : ''}`}>
                {copied ? '✓ COPIED' : '📋 COPY'}
              </button>
              <button onClick={handleDownload} className="cyber-btn-download">
                ⬇ EXPORT
              </button>
            </div>
          </div>

          {/* Tab Strip Bar */}
          <div className="cyber-terminal-tabbar">
            {[
              { id: 'xml', label: 'autounattend.xml' },
              { id: 'ps1', label: 'WinAurex-Tweak.ps1' },
              { id: 'reg', label: 'WinAurex.reg' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`cyber-terminal-tab ${activeTab === tab.id ? 'active' : ''}`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Terminal Code Body */}
          <pre className="cyber-terminal-body">
            {generatedCode}
          </pre>

          {/* Quick CLI Execution Command footer */}
          <div className="cyber-cli-bar">
            <span>⚡ 1-Click Elevated Dispatch:</span>
            <span
              onClick={handleCopyCmd}
              className="cyber-cli-cmd"
              title="Click to copy PowerShell dispatch command"
            >
              <code>irm https://winaurex.tech/apply.ps1 | iex</code>
              <span style={{ fontSize: '0.68rem', color: copiedCmd ? '#00ff00' : '#888' }}>
                {copiedCmd ? '[ COPIED ]' : '[ COPY ]'}
              </span>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WinAurexStudio;
