# 🌐 Web Browsers Guide

This guide details the web browser installers included in the `Browsers/` directory and provides recommendations based on resource efficiency, user privacy, extensions compatibility, and gaming latency.

---

## 📊 Comprehensive Browser Comparison

| Browser | Engine | Privacy Rating | Memory Footprint | Gaming Suitability | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Brave** | Chromium | 🟢 **Exceptional** (Built-in Shields) | 🟢 **Low** (due to blocked trackers) | 🟢 Excellent | Standard browsing, privacy, and media consumption. |
| **Thorium** | Chromium | 🟡 **Moderate** (Same as Chromium) | 🟢 **Ultra-Low** (Aggressive compilation) | 🟢 **Superior** (Lowest input lag) | Maximum FPS, gaming systems, and older hardware. |
| **Firefox** | Gecko | 🟢 **Exceptional** (Highly customizable) | 🟡 **Moderate** | 🟡 Balanced | Open-source advocates, custom about:config tuning. |
| **Google Chrome**| Chromium | 🔴 **Poor** (Aggressive Telemetry) | 🔴 **High** | 🟡 Balanced | Standard compatibility, large extension systems. |
| **Opera GX** | Chromium | 🔴 **Poor** (Heavy widgets/trackers) | 🔴 **Heavy** (Runs multiple helpers) | 🔴 **Poor** (High CPU on weak PCs) | Desktop styling, stream widgets (Avoid on low-end). |

---

## 🛠️ Integrated Installers

The `Browsers/` directory contains official setup files to install standard options easily:
*   `BraveBrowserSetup-BRV010.exe`: Brave browser setup (Chromium engine with built-in ad-blocking shields).
*   `ChromeSetup.exe`: Google Chrome web browser online installer.
*   `Firefox Installer.exe`: Mozilla Firefox online installer (Gecko engine).
*   `OperaSetup.exe` / `OperaGXSetup.exe`: Standard Opera and Opera GX (Gaming variant) setups.
*   `Internet Explorer 11.bat`: A legacy setup script to install/re-enable Internet Explorer 11 (Strictly for old, enterprise legacy databases only).

---

## 🚀 Key Browser Recommendations

### 1. The Ultimate Standard: **Brave Browser**
*   **Why**: Brave blocks all ads, tracking scripts, and cross-site cookies immediately without requiring third-party extensions. 
*   **Performance**: Since trackers and scripts are blocked at the engine level, pages load up to 3x faster and consume significantly less RAM than standard Chrome.
*   **Extensions**: Fully compatible with the Google Chrome Web Store.

### 2. The Gamers Choice: **Thorium Browser** (External)
*   **Why**: Thorium is an advanced open-source fork of Chromium aggressively compiled with compiler optimizations (AVX, AVX2, SSE4, and Clang parameters).
*   **Benefits**: It offers the fastest rendering times, lowest input latency, and reduced CPU overhead, making it ideal for running in the background while playing competitive games.

### ⚠️ A Warning on Opera GX
While marketed directly to gamers as a "Gaming Browser" featuring CPU and RAM limits, **Opera GX is not recommended for low-end computers**:
1.  **Background Bloat**: It runs a heavily customized interface loaded with integrated background messengers, active sound effects, animated transitions, and gaming news widgets.
2.  **Resource Saturation**: On legacy processors, the browser's own UI rendering causes micro-stutters and high background CPU usage, degrading in-game frames-per-second (FPS) significantly.

---

## 🔒 Recommended Privacy Extensions

If you utilize Firefox or standard Chromium browsers, we recommend installing the following lightweight extensions:

1.  **uBlock Origin** (The Industry Standard):
    *   *Why*: An ultra-lightweight, wide-spectrum blocker that removes ads, popups, tracking scripts, and malicious redirects. Unlike other options, it has virtually no CPU overhead.
2.  **Bitwarden**:
    *   *Why*: Open-source, highly secure, cross-platform password manager.
3.  **Privacy Badger**:
    *   *Why*: Automatically learns and blocks invisible background trackers that standard lists might miss.

---

## ⚡ Performance Optimization Guide

Apply these configurations in your browser settings to conserve RAM and CPU cycles:

### 1. Toggle Hardware Acceleration
*   **Enable It** on modern systems with dedicated GPUs to offload video decoding and layout rendering from your CPU.
*   **Disable It** if you run intensive competitive 3D games on a single monitor, as the browser can sometimes compete with the game for GPU resources, causing frames-per-second spikes.

### 2. Enable Memory Saver / Sleeping Tabs
*   In Chromium browsers (Brave, Chrome, Edge), navigate to **Settings > System and Performance** and turn on **Memory Saver**. This suspends inactive tabs, releasing memory instantly back to your OS.
*   In Firefox, inactive tabs are automatically unloaded when system RAM pressure crosses high boundaries.

### 3. Block Background Apps
*   Go to **Settings > System** and turn off **"Continue running background apps when browser is closed"**. This prevents the browser from spawning hidden update tasks and service loops in Task Manager after you exit.