"""
System Diagnostics & Query Module for WinAurex Python Engine.
Gathers hardware, memory, disk, and OS metrics natively using ctypes and winreg.
Zero external pip dependencies required.
"""

import os
import sys
import ctypes
import shutil
import platform
import subprocess
from typing import Dict, Any, List, Optional
from .registry import get_reg_value

class MEMORYSTATUSEX(ctypes.Structure):
    _fields_ = [
        ("dwLength", ctypes.c_ulong),
        ("dwMemoryLoad", ctypes.c_ulong),
        ("ullTotalPhys", ctypes.c_ulonglong),
        ("ullAvailPhys", ctypes.c_ulonglong),
        ("ullTotalPageFile", ctypes.c_ulonglong),
        ("ullAvailPageFile", ctypes.c_ulonglong),
        ("ullTotalVirtual", ctypes.c_ulonglong),
        ("ullAvailVirtual", ctypes.c_ulonglong),
        ("sullAvailExtendedVirtual", ctypes.c_ulonglong),
    ]

def get_memory_info() -> Dict[str, Any]:
    """Returns physical and virtual memory metrics."""
    stat = MEMORYSTATUSEX()
    stat.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
    ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))

    total_gb = stat.ullTotalPhys / (1024 ** 3)
    avail_gb = stat.ullAvailPhys / (1024 ** 3)
    used_gb = total_gb - avail_gb
    percent_used = stat.dwMemoryLoad

    return {
        "total_gb": round(total_gb, 2),
        "available_gb": round(avail_gb, 2),
        "used_gb": round(used_gb, 2),
        "percent_used": percent_used
    }

def get_uptime() -> Dict[str, Any]:
    """Returns system uptime calculated from GetTickCount64."""
    try:
        millis = ctypes.windll.kernel32.GetTickCount64()
        seconds = int(millis / 1000)
        days = seconds // 86400
        hours = (seconds % 86400) // 3600
        minutes = (seconds % 3600) // 60
        secs = seconds % 60
        formatted = f"{days}d {hours}h {minutes}m {secs}s" if days > 0 else f"{hours}h {minutes}m {secs}s"
        return {
            "total_seconds": seconds,
            "days": days,
            "hours": hours,
            "minutes": minutes,
            "seconds": secs,
            "formatted": formatted
        }
    except Exception:
        return {"formatted": "Unknown"}

def get_os_info() -> Dict[str, Any]:
    """Reads official Windows OS details from registry."""
    reg_path = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    prod_name = get_reg_value("HKLM", reg_path, "ProductName")
    build = get_reg_value("HKLM", reg_path, "CurrentBuild")
    display_ver = get_reg_value("HKLM", reg_path, "DisplayVersion")
    ubr = get_reg_value("HKLM", reg_path, "UBR")

    name = prod_name[0] if prod_name else platform.system()
    build_str = f"{build[0]}.{ubr[0]}" if build and ubr else str(build[0] if build else platform.version())
    version = display_ver[0] if display_ver else platform.release()

    # Detect Windows 11 vs 10 by build number (>= 22000 is Windows 11)
    if build and int(build[0]) >= 22000 and "10" in name:
        name = name.replace("Windows 10", "Windows 11")

    return {
        "product_name": name,
        "version": version,
        "build": build_str,
        "arch": platform.machine()
    }

def get_disks_info() -> List[Dict[str, Any]]:
    """Returns free/used capacity for all accessible fixed drives."""
    drives = []
    # Suppress Windows "No disk in drive" modal dialogs
    try:
        ctypes.windll.kernel32.SetErrorMode(0x0001 | 0x8000)
    except Exception:
        pass

    # Query drive letters
    buffer = ctypes.create_unicode_buffer(512)
    ctypes.windll.kernel32.GetLogicalDriveStringsW(512, buffer)
    drive_strings = buffer.value.split("\x00")

    for drive in drive_strings:
        if not drive:
            continue
        try:
            # DRIVE_FIXED = 3
            drive_type = ctypes.windll.kernel32.GetDriveTypeW(drive)
            if drive_type == 3: # Fixed disk (HDD / SSD)
                usage = shutil.disk_usage(drive)
                total_gb = usage.total / (1024 ** 3)
                free_gb = usage.free / (1024 ** 3)
                used_gb = usage.used / (1024 ** 3)
                percent = (usage.used / usage.total) * 100 if usage.total > 0 else 0
                drives.append({
                    "drive": drive.rstrip("\\"),
                    "total_gb": round(total_gb, 1),
                    "free_gb": round(free_gb, 1),
                    "used_gb": round(used_gb, 1),
                    "percent_used": round(percent, 1)
                })
        except Exception:
            continue

    return drives

def run_cmd(command: Any, timeout: int = 120, silent: bool = False) -> subprocess.CompletedProcess:
    """Executes a system command cleanly with Windows encoding handling."""
    if isinstance(command, str):
        shell = True
    else:
        shell = False

    return subprocess.run(
        command,
        shell=shell,
        stdout=subprocess.PIPE if silent else None,
        stderr=subprocess.PIPE if silent else None,
        text=True,
        timeout=timeout
    )
