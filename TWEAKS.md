# Windows Tweaks and Optimizations

This document provides detailed information about the various system tweaks and optimizations available in the `Tweaks/` directory. Each tweak is designed to improve system performance, privacy, or usability on Windows 10/11 systems.

## Table of Contents
1. [Appearance Tweaks](#appearance-tweaks)
2. [CPU Priority Tweaks](#cpu-priority-tweaks)
3. [CPU Mitigations](#cpu-mitigations)
4. [CPU Power Plans](#cpu-power-plans)
5. [Mem Reduct RAM](#mem-reduct-ram)
6. [Optimize SSD](#optimize-ssd)
7. [RAM Compression](#ram-compression)
8. [Services Tweaks](#services-tweaks)
9. [Telemetry Tweaks](#telemetry-tweaks)
10. [Apply Optimizations Script](#apply-optimizations-script)

## Appearance Tweaks

Located in: `Tweaks/Appearance/`

These registry files modify visual elements of Windows to improve performance or change the appearance:

### Available Tweaks:
- **Disable Transparency.reg** - Disables transparency effects in taskbar, start menu, and action center
- **Enable Transparency.reg** - Re-enables transparency effects
- **Dark Theme.reg** - Applies dark theme to Windows interface
- **Light Theme.reg** - Applies light theme to Windows interface
- **Disable Action Center.reg** - Disables the Windows Action Center
- **Enable Action Center.reg** - Re-enables the Windows Action Center
- **Disable Cortana.reg** - Disables Cortana digital assistant
- **Enable Cortana.reg** - Re-enables Cortana digital assistant

### Performance Impact:
Disabling transparency and visual effects can significantly improve performance on older or lower-end systems by reducing GPU and CPU usage.

## CPU Priority Tweaks

Located in: `Tweaks/Recursos\CPU Priority\`

These registry files adjust process priority settings to favor either system responsiveness or gaming performance:

### Available Tweaks:
- **Windows Priority.reg** - Sets default Windows process priorities (balanced)
- **Games Priority.reg** - Increases priority of gaming processes for better FPS
- **Revert Changes.reg** - Restores default priority settings

### How It Works:
Windows uses priority classes to determine how much CPU time a process gets relative to others. The gaming tweak increases the priority of foreground applications (typically games) to ensure they get more CPU resources.

## CPU Mitigations

Located in: `Tweaks/Recursos\CPU Mitigations\`

These tools control hardware-level security mitigations for vulnerabilities like Spectre and Meltdown:

### Available Tools:
- **InSpectre.exe** - Utility to enable/disable CPU mitigations with a GUI interface

### Security vs Performance Trade-off:
- **Mitigations ON**: Maximum security against CPU vulnerabilities but potential performance impact
- **Mitigations OFF**: Better performance but increased vulnerability to certain CPU-based attacks
- Only disable mitigations if you understand the security risks and have other protections in place

## CPU Power Plans

Located in: `Tweaks\Recursos\CPU Power Plan\`

These files define custom power plans for different usage scenarios:

### Available Files:
- **QuickCPU.pow** - Exported power plan optimized for CPU performance
- **Aplicar.bat** / **Apply.bat** - Batch files to apply the custom power plan

### Features:
The QuickCPU power plan is configured to:
- Keep CPU cores at higher frequencies longer
- Reduce core parking aggressiveness
- Optimize for responsiveness over power saving
- Ideal for gaming, content creation, and other CPU-intensive tasks

## Mem Reduct RAM

Located in: `Tweaks\Recursos\Mem Reduct RAM\`

This is a memory optimization utility that helps reduce RAM usage:

### Available Files:
- **memreduct.exe** - Main application executable
- **memreduct.lng** - Language file
- **memreduct.sig** - Security signature
- **memreduct.ini** - Configuration file
- **portable.dat** - Indicates portable mode
- **memreduct-3.4-setup.exe** - Installer version

### Features:
MemReduce is a lightweight application that:
- Cleans unused memory from the system
- Can automatically optimize memory at set intervals
- Shows real-time memory usage statistics
- Works without installing drivers or services
- Particularly useful on systems with limited RAM

## Optimize SSD

Located in: `Tweaks\Recursos\Optimize SSD\`

These registry files optimize Windows for SSD storage devices:

### Available Files:
- **Optimizar SSD.reg** - Applies SSD optimizations
- **Revert Changes.reg** - Restores default settings

### Optimizations Applied:
- Disables Superfetch/Prefetch (less beneficial on SSDs)
- Disables defragmentation scheduling (not needed for SSDs)
- Enables TRIM command support
- Adjusts write caching settings
- Reduces unnecessary write operations to extend SSD lifespan

## RAM Compression

Located in: `Tweaks\Recursos\RAM Compression\`

These scripts control Windows memory compression feature:

### Available Files:
- **Disable Compression.cmd** - Disables memory compression
- **Revert Changes.bat** - Re-enables memory compression

### When to Use:
- **Disable**: On systems with plenty of RAM where compression overhead isn't needed
- **Enable**: On systems with limited RAM where compression helps prevent paging to disk
- Memory compression uses CPU to compress unused memory pages, trading CPU usage for reduced disk I/O

## Services Tweaks

Located in: `Tweaks\Recursos\Services\`

These registry files optimize Windows services for better performance:

### Available Files:
- **Optimize Services.reg** - Applies service optimizations
- **Revert Changes.reg** - Restores default service settings

### Services Typically Affected:
- Disables unnecessary background services
- Sets service startup types to Manual where appropriate
- Reduces background resource consumption
- Improves boot times and overall system responsiveness

## Telemetry Tweaks

Located in: `Tweaks\Recursos\Telemetry\`

These registry files reduce or disable Windows telemetry and data collection:

### Available Files:
- **Disable Telemetry.reg** - Applies telemetry reduction settings
- **Revert Changes.reg** - Restores default telemetry settings

### Data Collection Reduced:
- Diagnostic and usage data
- Telemetry reporting
- Personalized advertising
- Location tracking (where applicable)
- Voice and inking data
- Handwriting recognition improvements

### Privacy Note:
While these tweaks reduce telemetry, some data collection may still occur for essential Windows functionality. For maximum privacy, consider using the unattended installation which includes more comprehensive telemetry disabling.

## Apply Optimizations Script

Located at: `Tweaks\Apply Optimizations.bat`

This batch script applies a comprehensive set of recommended optimizations:

### What It Does:
1. Applies appearance tweaks (disables transparency, animations)
2. Applies CPU priority optimizations
3. Applies service optimizations
4. Applies SSD optimizations (if SSD detected)
5. Applies telemetry reductions
6. Applies visual effects optimizations for performance
7. Sets power plan to high performance

### Usage:
1. Right-click the file and select "Run as administrator"
2. The script will apply tweaks and show progress
3. A restart may be required for all changes to take effect
4. To revert changes, manually apply the corresponding "Revert Changes" registry files

### Safety Features:
- Creates a system restore point before making changes (if system protection is enabled)
- Logs changes made for review
- Checks for SSD presence before applying SSD-specific tweaks

## Recommendations by Use Case

### Gaming Systems:
1. Apply CPU Priority Games Priority.reg
2. Apply QuickCPU power plan
3. Disable transparency and visual effects
4. Optimize SSD (if applicable)
5. Consider disabling unnecessary services
6. Keep RAM compression enabled unless you have 16GB+ RAM

### Workstation/Productivity:
1. Apply Windows Priority (balanced) or slight performance tweak
2. Apply SSD optimizations
3. Keep visual effects if preferred (minor performance impact)
4. Apply telemetry reductions for privacy
5. Keep security mitigations enabled

### Low-End Systems (<8GB RAM):
1. Apply all appearance tweaks (disable transparency, animations)
2. Apply service optimizations
3. Apply telemetry reductions
4. Consider disabling RAM compression if experiencing high CPU usage
5. Keep page file managed by system
6. Use MemReduce to actively manage memory usage

### Privacy-Focused Systems:
1. Apply all telemetry tweaks
2. Disable Cortana and data collection features
3. Consider disabling Windows Update if not using Microsoft Store
4. Use local account instead of Microsoft account
5. Apply service optimizations to reduce background data transmission
6. Consider using the unattended installation for maximum privacy

## Important Notes

### Backup Recommendations:
- Always create a system restore point before applying tweaks
- Backup important data before making system changes
- Some tweaks may affect specific software compatibility

### Compatibility:
- Tweaks are tested on Windows 10 version 1809 and later
- Tweaks are tested on Windows 11 version 21H2 and later
- Enterprise editions may have additional restrictions via group policy

### Reverting Changes:
- Each tweak folder includes a "Revert Changes" file
- The Apply Optimizations.bat script is not directly reversible - use individual revert files
- System restore point created by the script can be used to revert all changes

### Monitoring Effects:
- Use Task Manager to monitor CPU, memory, and disk usage before and after
- Use Resource Monitor for detailed service and process analysis
- Benchmark gaming performance with tools like 3DMark or FPS counters in games

---

*For questions or suggestions, please open an issue in the repository.*
*Last updated: May 2026*