import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "WinAurex",
  description: "Comprehensive collection of scripts and tools to optimize Windows 10/11 for peak performance, gaming, and privacy.",
  appearance: 'dark', // Native dark mode first
  head: [
    ['link', { rel: 'icon', href: '/favicon.png' }],
    ['meta', { name: 'description', content: 'Comprehensive collection of scripts and tools to optimize Windows 10/11 for peak performance, gaming, and privacy.' }],
    ['meta', { property: 'og:title', content: 'WinAurex | Next-Gen Windows Optimization & Customization Framework' }],
    ['meta', { property: 'og:description', content: 'Comprehensive collection of scripts and tools to optimize Windows 10/11 for peak performance, gaming, and privacy.' }],
    ['meta', { property: 'og:image', content: 'https://winaurex.netlify.app/og-preview.png' }],
    ['meta', { property: 'og:url', content: 'https://winaurex.netlify.app/' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { name: 'twitter:card', content: 'summary' }],
    ['meta', { name: 'twitter:title', content: 'WinAurex | Next-Gen Windows Optimization Framework' }],
    ['meta', { name: 'twitter:description', content: 'Comprehensive collection of scripts and tools to optimize Windows 10/11 for peak performance, gaming, and privacy.' }],
    ['meta', { name: 'twitter:image', content: 'https://winaurex.netlify.app/og-preview.png' }],
    ['script', {}, `
      if (typeof window !== 'undefined') {
        window.addEventListener('contextmenu', function(e) {
          if (e.target.closest && e.target.closest('.VPHero .image-src, .VPHero .image-container, .VPHero .image-bg')) {
            e.preventDefault();
            return false;
          }
        });
        window.addEventListener('dragstart', function(e) {
          if (e.target.closest && e.target.closest('.VPHero .image-src, .VPHero .image-container, .VPHero .image-bg')) {
            e.preventDefault();
            return false;
          }
        });
      }
    `]
  ],
  themeConfig: {
    logo: '/favicon.png',
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
