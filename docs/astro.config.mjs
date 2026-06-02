// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

import tailwindcss from '@tailwindcss/vite';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  site: 'https://winaurex.netlify.app',
  integrations: [starlight({
			title: 'WinAurex',
			defaultColorScheme: 'dark',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/YTxFSGAMERz/Windows-Optimisations' }],
			customCss: ['./src/styles/custom.css'],
			components: {},
			disable404Route: false,
			sidebar: [
          {
              label: 'OS Image Building',
              items: [
                  { label: 'OS Builder Framework', slug: 'os_builder' },
                  { label: 'Unattended Install', slug: 'autounattend' },
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
                  { label: 'OS Compatibility', slug: 'compatibility_matrix' },
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
			],
  }), react()],

  vite: {
    plugins: [tailwindcss()],
  },
});