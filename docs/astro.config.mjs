// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

import tailwindcss from '@tailwindcss/vite';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  site: 'https://winaurex.tech',
  prefetch: true,
  integrations: [starlight({
			title: 'WinAurex',
			description: 'Free, open-source toolkit to debloat Windows 11 and 10, neutralize Recall, prevent silent BitLocker, boost FPS, build custom ISOs, and disable telemetry.',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/YTxFSGAMERz/WinAurex' }],
			head: [
				{ tag: 'link', attrs: { rel: 'icon', href: '/favicon.ico' } },
				{ tag: 'meta', attrs: { name: 'keywords', content: 'windows 11 debloater, windows 11 26h2, windows 11 25h2, windows 11 24h2, windows 11 optimizer, disable recall, prevent bitlocker, fps boost, gaming performance, remove telemetry, os builder, win ui 3, custom iso, autounattend generator' } },
				{ tag: 'meta', attrs: { name: 'author', content: 'Farhan' } },
				{ tag: 'meta', attrs: { property: 'og:type', content: 'website' } },
				{ tag: 'meta', attrs: { property: 'og:site_name', content: 'WinAurex' } },
				{ tag: 'meta', attrs: { name: 'twitter:card', content: 'summary_large_image' } },
				{ tag: 'meta', attrs: { name: 'theme-color', content: '#16a34a' } },
			],
			customCss: ['./src/styles/custom.css'],
			// Override components with custom implementations
			components: {
				ThemeSelect: './src/components/ThemeSelect.astro',
				Head: './src/components/HeadSEO.astro',
				Footer: './src/components/Footer.astro',
				Header: './src/components/Header.astro',
			},
			sidebar: [
          {
              label: '🚀 Interactive Studio',
              items: [
                  { label: 'Web Studio (Live Build)', slug: 'studio' },
              ],
          },
          {
              label: 'OS Image Building',
              items: [
                  { label: 'OS Builder Framework', slug: 'os_builder' },
                  { label: 'Unattended Windows Install', slug: 'autounattend' },
              ],
          },
          {
              label: 'Live System Optimization',
              items: [
                  { label: 'System Tweaks', slug: 'tweaks' },
                  { label: 'Windows Update', slug: 'windows_update' },
                  { label: 'Web Browsers', slug: 'browsers' },
                  { label: 'WebView2 Info', slug: 'webview' },
                  { label: 'Activators', slug: 'activators' },
              ],
          },
          {
              label: 'Hardware & Security',
              items: [
                  { label: 'Drivers', slug: 'drivers' },
                  { label: 'Antivirus & Security', slug: 'antivirus' },
                  { label: 'Hardware Monitoring', slug: 'hardware' },
                  { label: 'Extra Utilities', slug: 'extra' },
              ],
          },
          {
              label: 'Architecture',
              items: [
                  { label: 'System Blueprint', slug: 'architecture_blueprint' },
                  { label: 'GUI Architecture', slug: 'dashboard_architecture' },
                  { label: 'OS Compatibility Matrix', slug: 'compatibility_matrix' },
              ],
          },
          {
              label: 'Deep Dives',
              items: [
                  { label: 'Frequently Asked Questions', slug: 'faq' },
                  { label: 'Input Latency Myths', slug: 'input_latency_myths' },
                  { label: 'Myths & Anti-Patterns', slug: 'myths_and_anti_patterns' },
                  { label: 'Registry Reference', slug: 'registry_reference' },
              ],
          },
          {
              label: '🛡️ Legal & Support',
              items: [
                  { label: 'Privacy Policy', slug: 'privacy' },
                  { label: 'Terms of Service', slug: 'terms' },
                  { label: 'Contact & Community', slug: 'contact' },
              ],
          },
			],
  }), react()],

  vite: {
    plugins: [tailwindcss()],
  },
});