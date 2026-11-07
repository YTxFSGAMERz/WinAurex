import React, { useState } from 'react';

interface TabItem {
  id: string;
  label: string;
  command: string;
  description: string;
  badge: string;
}

const TABS: TabItem[] = [
  {
    id: 'powershell',
    label: 'PowerShell (1-Click)',
    command: 'irm https://winaurex.tech/apply.ps1 | iex',
    description: 'Instant zero-install execution in elevated PowerShell. Prompts for profile and applies live.',
    badge: 'RECOMMENDED'
  },
  {
    id: 'choco',
    label: 'Chocolatey',
    command: 'choco install winaurex -y',
    description: 'Installs the WinAurex suite and registers global system CLI path via Chocolatey.',
    badge: 'PACKAGE MGR'
  },
  {
    id: 'npm',
    label: 'npm CLI',
    command: 'npm install -g winaurex',
    description: 'Global Node.js cross-platform launcher with interactive terminal menus and headless flags.',
    badge: 'DEVELOPER'
  },
  {
    id: 'python',
    label: 'Python / pip',
    command: 'pip install winaurex',
    description: 'Native Python engine with granular rollback, registry safety modules, and diagnostics.',
    badge: 'ENGINE CORE'
  },
  {
    id: 'gui',
    label: 'Desktop GUI',
    command: 'https://github.com/YTxFSGAMERz/WinAurex/releases/latest',
    description: 'Direct download for the compiled standalone C# WPF GUI Dashboard (.exe).',
    badge: 'GUI APP'
  }
];

export default function QuickInstall() {
  const [activeTab, setActiveTab] = useState<string>('powershell');
  const [copied, setCopied] = useState<boolean>(false);

  const current = TABS.find((t) => t.id === activeTab) || TABS[0];

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(current.command);
      setCopied(true);
      setTimeout(() => setCopied(false), 2200);
    } catch {
      // Fallback if clipboard API is restricted
      const textarea = document.createElement('textarea');
      textarea.value = current.command;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      setCopied(true);
      setTimeout(() => setCopied(false), 2200);
    }
  };

  return (
    <div className="quick-install-container not-content" role="region" aria-label="WinAurex Quick Installation Options">
      <div className="quick-install-header">
        <div className="quick-install-title">
          <span className="hud-indicator-dot" aria-hidden="true" />
          <span className="hud-title-text">DEPLOY WINAUREX ENGINE</span>
        </div>
        <span className="quick-install-badge">{current.badge}</span>
      </div>

      {/* Tab Navigation */}
      <div className="quick-install-tabs" role="tablist" aria-label="Installation Methods">
        {TABS.map((tab) => {
          const isActive = tab.id === activeTab;
          return (
            <button
              key={tab.id}
              role="tab"
              aria-selected={isActive}
              aria-controls={`tabpanel-${tab.id}`}
              id={`tab-${tab.id}`}
              className={`quick-install-tab-btn ${isActive ? 'active' : ''}`}
              onClick={() => {
                setActiveTab(tab.id);
                setCopied(false);
              }}
            >
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Panel */}
      <div
        id={`tabpanel-${current.id}`}
        role="tabpanel"
        aria-labelledby={`tab-${current.id}`}
        className="quick-install-panel"
      >
        <p className="quick-install-desc">{current.description}</p>

        <div className="quick-install-snippet-box">
          <span className="snippet-prompt" aria-hidden="true">
            {current.id === 'gui' ? 'URL' : '>'}
          </span>
          <code className="snippet-code">{current.command}</code>
          <button
            type="button"
            className={`quick-install-copy-btn ${copied ? 'copied' : ''}`}
            onClick={handleCopy}
            aria-label={copied ? 'Command copied to clipboard' : 'Copy command to clipboard'}
          >
            {copied ? (
              <>
                <svg className="copy-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
                <span>COPIED</span>
              </>
            ) : (
              <>
                <svg className="copy-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
                </svg>
                <span>COPY</span>
              </>
            )}
          </button>
        </div>

        {current.id === 'gui' && (
          <div style={{ marginTop: '0.75rem', textAlign: 'right' }}>
            <a
              href="https://github.com/YTxFSGAMERz/WinAurex/releases/latest"
              target="_blank"
              rel="noopener noreferrer"
              className="quick-install-direct-link"
            >
              Open Latest Releases on GitHub &rarr;
            </a>
          </div>
        )}
      </div>
      <div aria-live="polite" className="sr-only">
        {copied ? `Copied ${current.command} to clipboard` : ''}
      </div>
    </div>
  );
}
