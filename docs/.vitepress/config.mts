import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "Windows Optimisations",
  description: "Comprehensive collection of scripts and tools to optimize Windows 10/11 for peak performance, gaming, and privacy.",
  appearance: 'dark', // Native dark mode first
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Installation', items: [
        { text: 'Unattended Install', link: '/AUTOUNATTEND' },
        { text: 'Activators', link: '/ACTIVATORS' }
      ]},
      { text: 'System Tweaks', link: '/TWEAKS' },
      { text: 'Architecture', items: [
        { text: 'System Blueprint', link: '/Architecture_Blueprint' },
        { text: 'GUI Architecture', link: '/Dashboard_Architecture' },
        { text: 'OS Compatibility', link: '/Compatibility_Matrix' }
      ]},
      { text: 'Deep Dives', items: [
        { text: 'Input Latency Myths', link: '/Input_Latency_Myths' },
        { text: 'Myths & Anti-Patterns', link: '/Myths_and_Anti_Patterns' },
        { text: 'Registry Reference', link: '/Registry_Reference' }
      ]}
    ],
    sidebar: [
      {
        text: 'Installation',
        collapsed: false,
        items: [
          { text: 'Unattended Install', link: '/AUTOUNATTEND' },
          { text: 'Activators', link: '/ACTIVATORS' }
        ]
      },
      {
        text: 'Core Components',
        collapsed: false,
        items: [
          { text: 'System Tweaks', link: '/TWEAKS' },
          { text: 'Drivers', link: '/DRIVERS' },
          { text: 'Antivirus & Security', link: '/ANTIVIRUS' },
          { text: 'Windows Update', link: '/WINDOWS_UPDATE' },
          { text: 'Web Browsers', link: '/BROWSERS' },
          { text: 'WebView2 Info', link: '/WEBVIEW' }
        ]
      },
      {
        text: 'Utilities & Diagnostics',
        collapsed: false,
        items: [
          { text: 'Hardware Monitoring', link: '/HARDWARE' },
          { text: 'Extra Utilities', link: '/EXTRA' }
        ]
      },
      {
        text: 'Architecture',
        collapsed: false,
        items: [
          { text: 'System Blueprint', link: '/Architecture_Blueprint' },
          { text: 'GUI Architecture', link: '/Dashboard_Architecture' },
          { text: 'OS Compatibility', link: '/Compatibility_Matrix' }
        ]
      },
      {
        text: 'Deep Dives',
        collapsed: false,
        items: [
          { text: 'Input Latency Myths', link: '/Input_Latency_Myths' },
          { text: 'Myths & Anti-Patterns', link: '/Myths_and_Anti_Patterns' },
          { text: 'Registry Reference', link: '/Registry_Reference' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/YTxFSGAMERz/Windows-Optimisations' }
    ],
    search: {
      provider: 'local'
    }
  }
})
