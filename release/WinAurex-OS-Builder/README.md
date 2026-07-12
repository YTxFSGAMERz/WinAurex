<div align="center">

<!-- ANIMATED CAPSULE-RENDER VENOM HEADER -->
![Header](https://capsule-render.vercel.app/api?type=venom&color=0:000000,100:00bcd4&height=220&text=WINAUREX%20OS%20BUILDER&fontColor=00bcd4&fontSize=65&fontAlignY=55&animation=twinkling&desc=Zero-Bloat+Windows+11+Image+Engineering&descColor=ffffff&descAlignY=75&descSize=22)

<br>

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<br>

<!-- ANIMATED TYPEWRITER BOOT SEQUENCE -->
[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=14&duration=1800&pause=500&color=00BCD4&background=0D1117&center=true&vCenter=true&multiline=true&width=620&height=130&lines=%5B+0.001s+%5D+OK+%3A+DISM+Engine+Initialized;%5B+0.042s+%5D+OK+%3A+Appx+Packages+Stripped;%5B+0.119s+%5D+OK+%3A+Hardware+Checks+Bypassed;%5B+0.180s+%5D+OK+%3A+OOBE+Automation+Injected;%3E+BUILDER+STATUS+%3A+READY+%E2%96%88)](https://github.com/YTxFSGAMERz/WinAurex-OS-Builder)

<br>

<kbd>&nbsp;Windows Image Engineering&nbsp;</kbd> &nbsp;•&nbsp; <kbd>&nbsp;Native DISM Tooling&nbsp;</kbd> &nbsp;•&nbsp; <kbd>&nbsp;Telemetry-Free Base&nbsp;</kbd> &nbsp;•&nbsp; <kbd>&nbsp;Open Source&nbsp;</kbd>

<br><br>

<!-- BADGE GRID — TWO-TONE DARK+NEON -->
<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/ENGINE-NATIVE_DISM-00bcd4?style=for-the-badge&logo=windows&logoColor=00bcd4&labelColor=0D1117"></a>
  <a href="#"><img src="https://img.shields.io/badge/ENGINE-OSCDIMG_ISO_COMPILER-00bcd4?style=for-the-badge&logo=powershell&logoColor=00bcd4&labelColor=0D1117"></a>
  <a href="#"><img src="https://img.shields.io/badge/SAFETY-NO_THIRD_PARTY_BINS-00FF41?style=for-the-badge&logo=checkmarx&logoColor=00FF41&labelColor=0D1117"></a>
  <br>
  <a href="#"><img src="https://img.shields.io/badge/PLATFORM-WINDOWS_11_BYPASS-00bcd4?style=for-the-badge&logo=windows11&logoColor=00bcd4&labelColor=0D1117"></a>
  <a href="#"><img src="https://img.shields.io/badge/AUTOMATION-UNATTENDED_XML-9B59B6?style=for-the-badge&logo=xml&logoColor=9B59B6&labelColor=0D1117"></a>
  <br>
  <a href="#"><img src="https://img.shields.io/badge/SCRIPTS-OPEN_SOURCE-E74C3C?style=for-the-badge&logo=github&logoColor=E74C3C&labelColor=0D1117"></a>
  <a href="#"><img src="https://img.shields.io/badge/LANGUAGE-POWERSHELL_7%2B-00bcd4?style=for-the-badge&logo=powershell&logoColor=00bcd4&labelColor=0D1117"></a>
</p>

</div>

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ WHAT WINAUREX OS BUILDER IS</h2>

<div align="center">

<!-- RED MANIFESTO TYPING ANIMATION -->
[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=14&pause=400&color=FF4444&center=true&vCenter=true&width=620&lines=This+is+NOT+a+sketchy+custom+ISO.;NOT+a+blackbox+compilation.;We+use+ONLY+native+Microsoft+tools.;This+is+pure+OS+Engineering.)](https://github.com/YTxFSGAMERz/WinAurex-OS-Builder)

</div>

<br>

WinAurex OS Builder is an automated PowerShell script framework designed to strip down a standard Windows 11 installation image into a lightweight, high-performance, and privacy-respecting ISO (similar in concept to Tiny10/Tiny11).

Instead of relying on third-party blackbox tools, it leverages native Microsoft binaries (`DISM` and `oscdimg`) to ensure complete transparency, safety, and lack of malware.

<div align="center">

```text
[ STOCK ISO ] ──▶ [ DISM MOUNT ] ──▶ [ REGISTRY INJECTIONS & APP REMOVAL ] ──▶ [ OSCDIMG COMPILE ] ──▶ [ DEBLOATED ISO ]
```

</div>

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ CORE CAPABILITIES</h2>

### 🛡️ Hardware & Requirement Bypasses
* **TPM 2.0 & Secure Boot:** Bypassed natively during the WinPE setup phase.
* **CPU & RAM Restrictions:** Removes the hard lock for older hardware.
* **Microsoft Account (MSA):** Enforces Local Account creation during OOBE.

### 🗑️ Aggressive Debloating
* Removes **Microsoft Edge** & **Edge WebView**.
* Strips out **Copilot** and AI integrations.
* Eliminates **OneDrive**, Teams, and Xbox integrations.
* Purges 30+ Provisioned AppxPackages (Weather, News, Solitaire, etc.).

### 🔒 Privacy & Telemetry
* Injecting registry hives offline to disable telemetry collection.
* Turns off Sponsored Apps and Content Delivery Manager.
* Disables Advertising IDs and Cloud Content optimization.

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ DEPLOYMENT INSTRUCTIONS</h2>

<div align="center">

<!-- CYAN DEPLOYMENT ANIMATION -->
[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=14&pause=700&color=00BCD4&center=true&vCenter=true&width=600&lines=Initializing+OS+Builder...;Mounting+install.wim...;Purging+Telemetry...;%3E+BUILDING+ISO...)](https://github.com/YTxFSGAMERz/WinAurex-OS-Builder)

<br>

**1. Prepare Your Files**
Download an official Windows 11 ISO from Microsoft and mount it to a drive letter (e.g., `E:`).

**2. Run The Builder**
Execute the builder script as Administrator. Pass the mounted ISO drive and a Scratch drive (for temporary extraction).

```powershell
# Syntax: .\WinAurexMaker.ps1 -ISO <Mounted_Drive> -SCRATCH <Temp_Drive>
PS> .\WinAurexMaker.ps1 -ISO E -SCRATCH D
```

**3. Wait for Compilation**
The script will copy the ISO contents, convert `.esd` to `.wim` if necessary, mount the registry offline to apply tweaks, purge bloatware, and compile a brand new `WinAurex.iso` in the directory.

</div>

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ DOWNLOADING THE PRE-BUILT ISO</h2>

If you prefer not to build the ISO yourself, you can download a pre-compiled version directly from our [Releases page](https://github.com/YTxFSGAMERz/WinAurex-OS-Builder/releases).

**Instructions:**
1. Navigate to the **Releases** section of this repository.
2. Download both parts of the compressed ISO archive (`compressed1.7z.001` and `compressed1.7z.002`). *We've split the files into two parts to easily accommodate file size limits and fast downloading.*
3. Place both files in the same directory.
4. Right-click on `compressed1.7z.001` and use [7-Zip](https://www.7-zip.org/) (or WinRAR) to extract the files. The archive will automatically merge the two parts and extract the complete `WinAurex.iso`.

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ USING THE SCRIPTS & AUTOUNATTEND.XML</h2>

For a fully unattended Windows 11 installation that bypasses OOBE prompts, forces a local account, and applies essential tweaks automatically:

1. Copy the `autounattend.xml` file to the root of your bootable USB installation media (created via Rufus or Ventoy).
2. During the Windows setup process, this XML file will be automatically detected and processed, bypassing the Microsoft Account requirement and applying custom configurations on-the-fly.
3. Once the installation is complete, you can run any post-install scripts provided to finalize your WinAurex setup.

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ DOCUMENTATION & SYNERGY</h2>

<div align="center">

`[ OS Builder Architecture ]` &nbsp; `[ OOBE Unattended ]` &nbsp; `[ Image Servicing ]`

<br>

WinAurex OS Builder is designed to be the foundational layer. Once you install your custom ISO, use our post-install framework to finalize the optimization process:

🔗 **[ACCESS THE WINAUREX LIVE OPTIMISATION DASHBOARD](https://winaurex.netlify.app/)**

</div>

<!-- ═══ ANIMATED DIVIDER ═══ -->
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%">

<h2 align="center">⬛ CREDITS & AUTHOR</h2>

<div align="center">

<img src="https://avatars.githubusercontent.com/u/94067297?v=4" width="120" style="border-radius: 50%; border: 3px solid #00bcd4; box-shadow: 0 0 20px rgba(0, 188, 212, 0.6);">

<br><br>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=18&pause=1000&color=00BCD4&center=true&vCenter=true&width=500&lines=Farhan+%2F%2F+System+Architect;Cybersecurity+%26+AI+Enthusiast;Full-Stack+Developer;Building+scalable%2C+intelligent+systems+%F0%9F%9A%80)](https://github.com/YTxFSGAMERz)

<br>

> *Eradicate software bloat at the source. Maximize raw hardware performance. Restore absolute user control.*

<br>

<a href="https://github.com/YTxFSGAMERz">
  <img src="https://img.shields.io/badge/GitHub-YTxFSGAMERz-white?style=for-the-badge&logo=github&logoColor=white&labelColor=181717&color=181717">
</a>
&nbsp;&nbsp;
<a href="https://t.me/YTxFSGAMERz">
  <img src="https://img.shields.io/badge/Telegram-YTxFSGAMERz-white?style=for-the-badge&logo=telegram&logoColor=white&labelColor=229ED9&color=229ED9">
</a>
&nbsp;&nbsp;
<a href="https://wa.me/917778906798">
  <img src="https://img.shields.io/badge/WhatsApp-Connect-white?style=for-the-badge&logo=whatsapp&logoColor=white&labelColor=25D366&color=25D366">
</a>

</div>

<br><br>

<!-- ANIMATED CAPSULE-RENDER WAVING FOOTER -->
<div align="center">

![Footer](https://capsule-render.vercel.app/api?type=waving&color=0:00bcd4,100:000000&height=140&section=footer&text=Engineered+for+Control&fontColor=00bcd4&fontSize=26&fontAlignY=65&animation=twinkling)

</div>
