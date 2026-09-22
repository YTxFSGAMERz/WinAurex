#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const cliScript = path.join(repoRoot, 'Core', 'CLI', 'WinAurex.CLI.ps1');

// Forward all CLI arguments
const userArgs = process.argv.slice(2);

const psArgs = [
  '-NoProfile',
  '-ExecutionPolicy',
  'Bypass',
  '-File',
  cliScript,
  ...userArgs
];

const child = spawn('powershell.exe', psArgs, {
  stdio: 'inherit',
  windowsHide: false
});

child.on('error', (err) => {
  console.error('[WinAurex Error] Failed to launch PowerShell:', err.message);
  process.exit(1);
});

child.on('exit', (code) => {
  process.exit(code !== null ? code : 0);
});
