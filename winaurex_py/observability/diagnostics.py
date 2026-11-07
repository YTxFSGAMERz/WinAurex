"""
WinAurex System Diagnostics & Observability Dashboard.
Renders real-time hardware, memory, disk, network, and optimization health in the terminal.
"""

from typing import Dict, Any
from ..core.colors import (
    c_cyan, c_green, c_yellow, c_red, c_bold, c_gray, c_magenta,
    print_header, print_info
)
from ..core.system import get_os_info, get_memory_info, get_uptime, get_disks_info
from ..core.registry import get_reg_value
from ..tweaks.power import get_active_power_scheme

def get_cpu_info() -> str:
    """Reads processor name from registry."""
    cpu = get_reg_value("HKLM", r"HARDWARE\DESCRIPTION\System\CentralProcessor\0", "ProcessorNameString")
    if cpu and cpu[0]:
        return str(cpu[0]).strip()
    return "Unknown Processor"

def render_progress_bar(percent: float, width: int = 24) -> str:
    """Creates a visual ASCII progress bar."""
    filled = int(width * (percent / 100))
    bar = "█" * filled + "░" * (width - filled)
    if percent > 85:
        return f"[{c_red(bar)}] {percent:.1f}%"
    elif percent > 65:
        return f"[{c_yellow(bar)}] {percent:.1f}%"
    else:
        return f"[{c_green(bar)}] {percent:.1f}%"

def show_system_diagnostics():
    """Prints the complete system observability dashboard."""
    print_header("WinAurex System Diagnostics & Health Dashboard")

    os_info = get_os_info()
    mem = get_memory_info()
    uptime = get_uptime()
    disks = get_disks_info()
    cpu_name = get_cpu_info()
    power_plan = get_active_power_scheme()

    # Query key tweak statuses
    hags = get_reg_value("HKLM", r"SYSTEM\CurrentControlSet\Control\GraphicsDrivers", "HwSchMode")
    game_mode = get_reg_value("HKCU", r"Software\Microsoft\GameBar", "AllowAutoGameMode")
    throttling = get_reg_value("HKLM", r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "NetworkThrottlingIndex")
    telemetry = get_reg_value("HKLM", r"SOFTWARE\Policies\Microsoft\Windows\DataCollection", "AllowTelemetry")

    print(f" {c_cyan('Operating System :')} {c_bold(os_info['product_name'])} ({os_info['version']} Build {os_info['build']} {os_info['arch']})")
    print(f" {c_cyan('Processor (CPU)  :')} {cpu_name}")
    print(f" {c_cyan('System Uptime    :')} {uptime['formatted']}")
    print(f" {c_cyan('Active Power Plan:')} {power_plan.get('name', 'Unknown')}")
    print()

    # RAM Status
    print(f" {c_cyan('Memory (RAM)     :')} {mem['used_gb']} GB / {mem['total_gb']} GB used {render_progress_bar(mem['percent_used'])}")

    # Disks Status
    print(f" {c_cyan('Storage Volumes  :')}")
    for d in disks:
        print(f"   Drive {c_bold(d['drive'])}: {d['used_gb']} GB used / {d['total_gb']} GB total {render_progress_bar(d['percent_used'])} ({c_green(str(d['free_gb']) + ' GB free')})")

    print()
    print(f" {c_magenta('--- Windows Optimization Matrix ---')}")

    hags_status = c_green("Enabled (HwSchMode=2)") if hags and hags[0] == 2 else c_gray("Disabled (Default)")
    game_status = c_green("Active") if game_mode and game_mode[0] == 1 else c_gray("Disabled")
    net_status = c_green("Unthrottled (100% Priority)") if throttling and throttling[0] == 0xFFFFFFFF else c_gray("Standard Windows Default")
    telem_status = c_green("Blocked (AllowTelemetry=0)") if telemetry and telemetry[0] == 0 else c_yellow("Active (Standard Telemetry)")

    print(f"   GPU Hardware Scheduling (HAGS) : {hags_status}")
    print(f"   Windows Game Mode               : {game_status}")
    print(f"   Network Throttling              : {net_status}")
    print(f"   Diagnostic Telemetry            : {telem_status}")
    print()
