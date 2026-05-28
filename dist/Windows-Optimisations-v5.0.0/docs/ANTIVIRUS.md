# 🛡️ Antivirus & Security Recommendations

This guide provides strategic advice on securing your system, choosing the right antivirus software, utilizing advanced sandboxes, and establishing safe browsing habits without crippling your system's performance.

---

## 📊 Comparative Antivirus Table

If you prefer resident (always-on) protection, choose a lightweight, highly-effective scanner. Below is a comparison of the top three recommended solutions:

| Antivirus Solution | Resource Footprint | Malware Detection | Real-Time Protection | Best Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **ESET NOD32** | 🟢 **Ultra-Lightweight** (Low RAM) | 🟢 Excellent | 🟢 Strong & Silent | Low-end PCs, gamers, and advanced power users. |
| **Malwarebytes** | 🟡 **Moderate** (Cleans deeply) | 🟢 Superior | 🟡 Moderate (Better as scanner) | On-demand scanning and active threat removal. |
| **Kaspersky Security**| 🟡 **Moderate** (Highly optimized) | 🟢 Exceptional | 🟢 Industry-Leading | Complete protection for standard, high-resource PCs. |

---

## 🛠️ Integrated Clean Installers

The `Antivirus/` directory contains official setup launchers for the recommended programs:
*   `eset_internet_security_live_installer.exe`: Live bootstrap installer for ESET Internet Security / NOD32.
*   `MBSetup.exe`: Standalone setup for Malwarebytes Anti-Malware.
*   `Kaspersky.exe`: Standalone setup launcher for Kaspersky Internet Security.

---

## 🔍 Advanced Online Scanners (No Installation)

For maximum performance, you can run a debloated, antivirus-free system while utilizing cloud-based diagnostics to scan individual downloads:

1.  **VirusTotal (virustotal.com)**:
    *   An open cloud scanning portal that analyzes uploaded files and URLs using over 70 distinct antivirus engines simultaneously.
    *   **How to Use**: Upload any executable (`.exe`, `.bat`, `.scr`, `.msi`) before running it. If a file displays more than 3-4 detections from major vendors, treat it as highly suspect.
2.  **Triage Sandbox (tria.ge)**:
    *   A high-performance automated malware analysis sandbox.
    *   **How to Use**: Upload files to run them in an isolated cloud-based virtual machine. Triage registers VM system modifications, network calls, and registry injections, outputting a clear safety score and execution recording.

---

## ⚠️ Antivirus Suites to Avoid

According to community telemetry and system analysis, the following antivirus suites are **highly discouraged** and should be avoided:

*   **Avast Free Antivirus**
*   **AVG Antivirus** (Owned by Avast)
*   **Avira Security**

### Why Avoid Them?
1.  **System Saturation**: These engines install multiple background update daemons, system helper services, and web shields that consume heavy amounts of RAM and disk write operations.
2.  **Aggressive Popups**: Frequently display marketing popups, upgrading prompts, and registry-cleaning upsells.
3.  **Telemetry Concerns**: Known to bundle data collection trackers and share browsing logs with external analytics platforms.
4.  **Ineffective Cleanup**: Often flag false-positives while failing to completely clean deep-seated rootkits or trojans.

---

## 🔒 Layered Security Practices

To maintain a secure operating system without using heavy resident antivirus software, apply these habits:

### 1. Account Isolation
*   Do not use the default built-in **Administrator** account for daily browsing.
*   Create a secondary **Standard User** account for daily activities, and only authenticate via User Account Control (UAC) prompts when installing verified software.

### 2. Browser Safeguards
*   Equip your web browsers with premium ad-blocking and script filtering extensions:
    *   **uBlock Origin**: The absolute standard in lightweight, highly-effective ad and tracker blocking.
    *   **Privacy Badger**: Learns and blocks invisible trackers automatically.
*   Avoid clicking on sponsored results in search engines, as these are frequently hijacked by malicious actors to host cloned software installers.

### 3. File Execution Hygiene
*   **Check File Extensions**: Always show file extensions in File Explorer. Beware of double extensions such as `Document.pdf.exe` or `Setup.zip.bat`.
*   **Avoid Cracks**: Keygens, cracks, and custom gaming injectors are highly dangerous and often inject silent miners, spyware, or keyloggers into system files.