# Input Latency Myths & Facts

The internet is filled with "zero latency" tweaks that are at best placebos, and at worst, detrimental to system stability. The Windows-Optimisations Framework focuses on **hardware-level truths** rather than registry snake oil.

Here is a breakdown of the most common myths surrounding input latency.

---

### Myth 1: "Timer Resolution must be forced to 0.5ms for lowest lag."
**Fact:** 
Prior to Windows 10 Version 2004, games relied heavily on the global system timer. However, modern Windows (and modern games like Valorant, CS2) use **QPC (QueryPerformanceCounter)** for timing, which operates in the microseconds (sub-millisecond) range natively. 
Forcing the global system timer to `0.5ms` via 3rd party apps (like ISLC or TimerResolution) forces the CPU to wake up thousands of times a second needlessly, increasing heat and DPC overhead without actually reducing input lag in modern titles.

### Myth 2: "Disabling HPET in the BIOS gives you 0ms latency."
**Fact:** 
HPET (High Precision Event Timer) is a hardware timer. Windows dynamically chooses the best timing source (usually Invariant TSC on modern CPUs). Forcing HPET off via `bcdedit /deletevalue useplatformclock` or in the BIOS can actually desync audio and cause micro-stutters in games if Windows was relying on it as a fallback. 
**Recommendation:** Leave HPET enabled in the BIOS, and DO NOT touch the `bcdedit` commands. Let Windows manage the timer.

### Myth 3: "8000Hz polling rate mice are always better."
**Fact:** 
A mouse polling at 8000Hz sends 8,000 interrupts per second to your CPU. If your CPU is not top-tier (e.g., Ryzen 7 7800X3D, Intel i9 14900K), this massive influx of interrupts will cause **DPC latency spikes**, leading to skipped frames and massive stutters in-game. 
**Recommendation:** 1000Hz is perfectly stable for 99% of setups. 2000Hz is the safe maximum for modern esports. Only use 4000Hz/8000Hz if you have the CPU headroom and a 240Hz+ monitor.

### Myth 4: "Mouse Acceleration can't be fully disabled in Windows."
**Fact:** 
Windows "Enhance Pointer Precision" (EPP) is a non-linear velocity curve. Turning it off in the GUI disables it. However, older games (like CS 1.6 or old Source engine games) sometimes forcibly re-enable it via the Win32 API. 
The registry fix (like the one deployed by our `Disable_Mouse_Acceleration.ps1`) flattens the fallback curve entirely, guaranteeing 1:1 raw input regardless of what legacy software attempts.

### Myth 5: "Changing USB polling rate in the registry reduces latency."
**Fact:** 
Windows 10/11 ignores legacy registry polling overrides (`HIDUSBF` filters). The only way to change your mouse's polling rate is via the manufacturer's official software/firmware (e.g., Logitech G HUB, Razer Synapse, Wootility).

---

## What Actually Matters?
If you want real input latency improvements:
1. Ensure **Exclusive Fullscreen** is working in your games (bypasses DWM buffering).
2. Enable **NVIDIA Reflex** or **AMD Anti-Lag** (reduces render queue depth).
3. Disable **USB Selective Suspend** (prevents the USB controller from sleeping).
4. Maintain high, stable framerates. (Frame time = Input time).
