# 🌡️ Hardware Monitoring & Diagnostics Guide

The `Hardware/` directory contains portable, industry-standard diagnostic tools designed to monitor hardware specifications, track temperatures, and verify that system optimizations are active and stable.

---

## 🛠️ Integrated Diagnostic Tools

### 1. CPU-Z
*   **File**: `CPU-Z.exe`
*   **Purpose**: Gathers in-depth data regarding your processor, motherboard, chipset, and memory channels.
*   **Key Parameters to Monitor**:
    *   **Core Speed / Multiplier**: Verify that your CPU is scaling to its advertised boost clocks and that custom performance power plans are actively preventing aggressive core parking.
    *   **Memory Tab**: Confirm that your RAM is running in Dual Channel mode and that the motherboard's XMP (Extreme Memory Profile) is active (by checking DRAM Frequency and comparing against advertised timings).

### 2. GPU-Z
*   **File**: `GPU-Z.exe`
*   **Purpose**: A lightweight diagnostic utility tailored specifically to GPU sensors, BIOS revisions, and graphic driver specifications.
*   **Key Parameters to Monitor**:
    *   **Sensors Tab (Real-Time)**: Track GPU Core Clock, Memory Clock, and Fan Speeds during active benchmarking.
    *   **GPU Temperature vs. Hot Spot Temperature**: Ensure the delta between core and hotspot temperatures does not exceed 15-20°C (higher deltas indicate worn thermal paste or uneven cooler pressure).
    *   **PCIe Slot Speed**: Verify that the GPU is running at its maximum bus width (e.g., `PCIe x16 4.0 @ x16 4.0` under load) and not downscaling during gaming.

### 3. HWMonitor
*   **File**: `HW-Monitor.exe`
*   **Purpose**: A comprehensive hardware health monitoring program that tracks motherboard voltages, system fan speeds, disk SSD temperatures, and core CPU/GPU sensors simultaneously.
*   **Key Parameters to Monitor**:
    *   **Temperatures (CPU Cores)**: Confirm that under full workload, CPU core temperatures stay below the thermal throttling limit (typically 90-100°C for modern processors).
    *   **CPU Package Power**: Track power consumption (in Watts) to verify power plan configurations are correctly applying voltages.

---

## 🔍 The "Before & After" Optimization Verification Flow

To confirm your optimizations are successful and safe, follow this baseline diagnostic routine:

```
[1. Baseline HWMonitor Run] ──> [2. Apply Registry Tweaks] ──> [3. Benchmark Run] ──> [4. Verify Thermal Limits]
```

### Phase 1: Establish the Baseline
1. Before applying any tweaks, close all active windows.
2. Launch `HW-Monitor.exe` and let the computer sit idle for 5 minutes.
3. Note your **Idle Temperatures** for CPU and GPU (healthy ranges are typically 35-50°C).
4. Run a demanding game or benchmark (like Cinebench or Superposition) for 10 minutes.
5. Record your **Maximum Temperatures** and CPU boost clock stability.

### Phase 2: Apply System Optimizations
1. Create a System Restore Point.
2. Run your preferred optimization scripts (e.g., MMCSS gaming priority, RAM compression off, CPU Power Plan).

### Phase 3: Verify the Changes
1. **Verify Clock Speeds via CPU-Z / GPU-Z**:
    * Open `CPU-Z.exe`. Ensure the CPU remains at high boost frequencies and does not drop during workload transitions.
    * Open `GPU-Z.exe`. Check the sensors to confirm the graphics card is hitting its maximum clock limits.
2. **Verify Temperatures and Throttling via HWMonitor**:
    * Re-run your benchmark tool with HWMonitor active in the background.
    * Review the **Max Column** in HWMonitor:
        * Ensure motherboard VRMs, NVMe SSDs, and CPU cores stay well within safe limits.
        * If temperatures exceed safe limits (CPU > 90°C or GPU > 85°C), disable custom power plan optimizations or restore CPU mitigations in `InSpectre.exe` to reduce thermal pressure.
