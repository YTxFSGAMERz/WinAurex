"""
WinAurex Windows Repair & Health Restoration Engine.
Executes native Windows repair utilities (SFC, DISM, Network Stack, Windows Update Reset).
"""

import os
import subprocess
import time
from typing import Dict, Any
from ..core.colors import (
    c_cyan, c_green, c_yellow, c_red, c_bold, c_gray,
    print_header, print_success, print_info, print_warning, print_error
)

def run_sfc_scan() -> Dict[str, Any]:
    """Runs System File Checker (sfc /scannow) to repair corrupt OS files."""
    print_info("Starting System File Checker (sfc /scannow)...")
    print(c_gray("  This process scans all protected system files and replaces corrupted files."))
    try:
        proc = subprocess.run(["sfc", "/scannow"], text=True)
        success = (proc.returncode in (0, 1))
        if proc.returncode == 0:
            print_success("SFC scan completed: Windows Resource Protection found no integrity violations.")
        elif proc.returncode == 1:
            print_success("SFC scan completed: Windows Resource Protection found corrupt files and repaired them.")
        else:
            print_warning(f"SFC scan completed with return code {proc.returncode}.")
        return {"success": success, "returncode": proc.returncode}
    except Exception as e:
        print_error(f"SFC execution failed: {e}")
        return {"success": False, "error": str(e)}

def run_dism_repair() -> Dict[str, Any]:
    """Runs DISM /Online /Cleanup-Image /RestoreHealth to repair Windows component store."""
    print_info("Starting DISM Component Store Repair (RestoreHealth)...")
    print(c_gray("  This checks the Windows component store against Windows Update for corrupt payloads."))
    try:
        proc = subprocess.run(["dism", "/online", "/cleanup-image", "/restorehealth"], text=True)
        if proc.returncode == 0:
            print_success("DISM repair completed successfully.")
        else:
            print_warning(f"DISM finished with code {proc.returncode}.")
        return {"success": proc.returncode == 0, "returncode": proc.returncode}
    except Exception as e:
        print_error(f"DISM execution failed: {e}")
        return {"success": False, "error": str(e)}

def repair_network_stack() -> Dict[str, Any]:
    """Resets Winsock, IPv4/IPv6 stacks, and flushes DNS."""
    print_info("Resetting network stack and Winsock catalog...")
    steps = [
        (["netsh", "winsock", "reset"], "Winsock Reset"),
        (["netsh", "int", "ip", "reset"], "TCP/IP Stack Reset"),
        (["ipconfig", "/release"], "DHCP Lease Released"),
        (["ipconfig", "/renew"], "DHCP Lease Renewed"),
        (["ipconfig", "/flushdns"], "DNS Cache Flushed")
    ]
    results = []
    for cmd, name in steps:
        try:
            p = subprocess.run(cmd, capture_output=True, text=True)
            results.append({"name": name, "success": p.returncode == 0})
            if p.returncode == 0:
                print_success(f"{name} completed.")
            else:
                print_warning(f"{name} warning/notice.")
        except Exception as e:
            results.append({"name": name, "success": False, "error": str(e)})

    return {"success": any(r["success"] for r in results), "steps": results}

def repair_windows_update() -> Dict[str, Any]:
    """Resets Windows Update client services and clears cached corrupted downloads."""
    print_info("Resetting Windows Update components...")
    services = ["wuauserv", "bits", "cryptsvc"]

    # 1. Stop services
    for s in services:
        subprocess.run(["net", "stop", s, "/y"], capture_output=True)

    # 2. Clear corrupted Download directory
    windir = os.environ.get("WINDIR", r"C:\Windows")
    dl_dir = os.path.join(windir, "SoftwareDistribution", "Download")
    cleared = False
    if os.path.isdir(dl_dir):
        try:
            for item in os.listdir(dl_dir):
                fp = os.path.join(dl_dir, item)
                try:
                    if os.path.isdir(fp):
                        import shutil
                        shutil.rmtree(fp, ignore_errors=True)
                    else:
                        os.remove(fp)
                except Exception:
                    pass
            cleared = True
            print_success("Windows Update Download cache cleared.")
        except Exception:
            pass

    # 3. Restart services
    for s in reversed(services):
        subprocess.run(["net", "start", s], capture_output=True)

    print_success("Windows Update services restarted.")
    return {"success": True, "download_cleared": cleared}
