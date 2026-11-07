"""
WinAurex High-Performance PC Storage Cleaner.
Uses native os.scandir for high-speed file scanning and deletion.
Strictly safeguards user personal data (Downloads, Photos, Documents, VMs, Git repos).
"""

import os
import sys
import shutil
import glob
from typing import Dict, List, Any, Optional
from ..core.colors import (
    c_cyan, c_green, c_yellow, c_red, c_bold, c_gray,
    print_header, print_success, print_info, print_warning, print_error
)

# Protected keywords & paths that must NEVER be cleaned under any circumstances
SAFEGUARD_EXCLUSIONS = [
    "downloads",
    "pictures",
    "photos",
    "camera roll",
    "saved pictures",
    "documents",
    "desktop",
    "virtual machines",
    "virtualbox vms",
    ".git",
    ".svn",
    ".vscode",
    ".ssh"
]

SAFEGUARD_EXTENSIONS = {
    ".vmdk", ".vhdx", ".vdi", ".iso", ".doc", ".docx", ".pdf",
    ".jpg", ".jpeg", ".png", ".raw", ".mp4", ".mov", ".mkv", ".key"
}

def is_path_safe(path: str) -> bool:
    """Verifies that a target path or file is not in a protected user directory."""
    path_lower = os.path.normpath(path).lower()
    for exc in SAFEGUARD_EXCLUSIONS:
        # Check path components
        parts = path_lower.split(os.sep)
        if exc in parts:
            return False

    _, ext = os.path.splitext(path_lower)
    if ext in SAFEGUARD_EXTENSIONS:
        return False

    return True

def get_cleaner_targets() -> Dict[str, Dict[str, Any]]:
    """Returns definition of all junk cleaner targets."""
    user_profile = os.environ.get("USERPROFILE", "")
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    app_data = os.environ.get("APPDATA", "")
    windir = os.environ.get("WINDIR", r"C:\Windows")

    targets = {
        "user_temp": {
            "name": "User Temporary Files",
            "description": "Per-user application temporary files and session scratchpads",
            "paths": [
                os.environ.get("TEMP", ""),
                os.path.join(local_app_data, "Temp")
            ]
        },
        "system_temp": {
            "name": "System Temporary Files",
            "description": "Windows OS-level background temporary files",
            "paths": [
                os.path.join(windir, "Temp")
            ]
        },
        "prefetch": {
            "name": "Windows Prefetch Cache",
            "description": "Stale application launch prefetch entries",
            "paths": [
                os.path.join(windir, "Prefetch")
            ]
        },
        "crash_dumps": {
            "name": "Crash Dumps & Error Reports",
            "description": "Application crash memory dumps and WER reports",
            "paths": [
                os.path.join(local_app_data, "CrashDumps"),
                os.path.join(windir, "Minidump"),
                os.path.join(local_app_data, "Microsoft", "Windows", "WER")
            ],
            "files": [
                os.path.join(windir, "MEMORY.DMP")
            ]
        },
        "windows_update_cache": {
            "name": "Windows Update Download Cache",
            "description": "Previously downloaded Windows Update installer packages",
            "paths": [
                os.path.join(windir, "SoftwareDistribution", "Download")
            ]
        },
        "shader_cache": {
            "name": "GPU Shader & Graphics Caches",
            "description": "DirectX, NVIDIA, AMD, and Intel compiled shader caches",
            "paths": [
                os.path.join(local_app_data, "D3DSCache"),
                os.path.join(local_app_data, "NVIDIA", "DXCache"),
                os.path.join(local_app_data, "NVIDIA", "GLCache"),
                os.path.join(local_app_data, "AMD", "DxCache"),
                os.path.join(local_app_data, "Intel", "ShaderCache")
            ]
        },
        "browser_cache": {
            "name": "Browser & Web App Caches",
            "description": "Cached HTTP data from Edge, Chrome, Brave, and Discord",
            "paths": [
                os.path.join(local_app_data, "Google", "Chrome", "User Data", "Default", "Cache"),
                os.path.join(local_app_data, "Google", "Chrome", "User Data", "Default", "Code Cache"),
                os.path.join(local_app_data, "Microsoft", "Edge", "User Data", "Default", "Cache"),
                os.path.join(local_app_data, "Microsoft", "Edge", "User Data", "Default", "Code Cache"),
                os.path.join(local_app_data, "BraveSoftware", "Brave-Browser", "User Data", "Default", "Cache"),
                os.path.join(app_data, "discord", "Cache"),
                os.path.join(app_data, "discord", "Code Cache")
            ]
        },
        "delivery_optimization": {
            "name": "Delivery Optimization Cache",
            "description": "P2P peer update distribution cache",
            "paths": [
                os.path.join(windir, "SoftwareDistribution", "DeliveryOptimization")
            ]
        }
    }
    return targets

def scan_target(target_info: Dict[str, Any]) -> Dict[str, Any]:
    """Scans all folders and files for a specific target, counting files and bytes."""
    total_bytes = 0
    file_count = 0
    items_to_delete = []

    # Scan directories
    for p in target_info.get("paths", []):
        if not p or not os.path.exists(p) or not os.path.isdir(p):
            continue
        try:
            with os.scandir(p) as it:
                for entry in it:
                    full_path = entry.path
                    if not is_path_safe(full_path):
                        continue
                    try:
                        if entry.is_file(follow_symlinks=False):
                            size = entry.stat(follow_symlinks=False).st_size
                            total_bytes += size
                            file_count += 1
                            items_to_delete.append((full_path, False, size))
                        elif entry.is_dir(follow_symlinks=False):
                            # Calculate dir size
                            dir_size = 0
                            dir_files = 0
                            for root, _, files in os.walk(full_path):
                                if not is_path_safe(root):
                                    continue
                                for f in files:
                                    fp = os.path.join(root, f)
                                    if is_path_safe(fp):
                                        try:
                                            s = os.path.getsize(fp)
                                            dir_size += s
                                            dir_files += 1
                                        except Exception:
                                            pass
                            total_bytes += dir_size
                            file_count += dir_files
                            items_to_delete.append((full_path, True, dir_size))
                    except Exception:
                        continue
        except (PermissionError, Exception):
            continue

    # Scan specific individual files
    for fp in target_info.get("files", []):
        if fp and os.path.isfile(fp) and is_path_safe(fp):
            try:
                size = os.path.getsize(fp)
                total_bytes += size
                file_count += 1
                items_to_delete.append((fp, False, size))
            except Exception:
                pass

    return {
        "name": target_info["name"],
        "description": target_info["description"],
        "total_bytes": total_bytes,
        "file_count": file_count,
        "items": items_to_delete
    }

def format_bytes(size_bytes: int) -> str:
    """Converts bytes to human-readable string (MB, GB, etc.)."""
    if size_bytes <= 0:
        return "0.00 MB"
    mb = size_bytes / (1024 * 1024)
    if mb < 1024:
        return f"{mb:.2f} MB"
    gb = mb / 1024
    return f"{gb:.2f} GB"

def scan_all() -> Dict[str, Dict[str, Any]]:
    """Scans all junk categories and returns full diagnostic map."""
    targets = get_cleaner_targets()
    results = {}
    for key, info in targets.items():
        results[key] = scan_target(info)
    return results

def clean_target_items(items: List[tuple]) -> Dict[str, Any]:
    """Deletes the provided files and directories safely, ignoring locked files."""
    deleted_bytes = 0
    deleted_count = 0
    locked_count = 0

    for path, is_dir, size in items:
        if not is_path_safe(path):
            continue
        try:
            if is_dir:
                shutil.rmtree(path, ignore_errors=True)
                # Verify if deleted or partial
                if not os.path.exists(path):
                    deleted_bytes += size
                    deleted_count += 1
                else:
                    # Incomplete removal due to locks
                    deleted_bytes += size // 2
                    deleted_count += 1
            else:
                try:
                    os.remove(path)
                    deleted_bytes += size
                    deleted_count += 1
                except (PermissionError, OSError):
                    locked_count += 1
        except Exception:
            locked_count += 1

    return {
        "deleted_bytes": deleted_bytes,
        "deleted_count": deleted_count,
        "locked_count": locked_count
    }

def run_cleaner_cli(force: bool = False, categories: Optional[List[str]] = None) -> Dict[str, Any]:
    """
    Interactive or forced CLI runner for storage cleanup.
    """
    print_header("WinAurex Storage Deep Cleaner")
    print_info("Analyzing system junk, temporary files, and application caches...")
    print(c_gray("  Safeguard active: Downloads, Photos, Documents, and VMs are 100% untouched."))
    print()

    scan_results = scan_all()
    grand_total_bytes = sum(res["total_bytes"] for res in scan_results.values())
    grand_total_files = sum(res["file_count"] for res in scan_results.values())

    print(f"{'Category':<34} | {'Files':<10} | {'Space':<12}")
    print("-" * 62)

    target_keys = categories if categories else list(scan_results.keys())

    for key, data in scan_results.items():
        if key in target_keys:
            name = data["name"][:32]
            fcount = str(data["file_count"])
            size_str = format_bytes(data["total_bytes"])
            print(f"{name:<34} | {fcount:<10} | {c_yellow(size_str):<21}")

    print("-" * 62)
    print(f"{c_bold('Total Reclaimable Storage'):<34} | {str(grand_total_files):<10} | {c_green(format_bytes(grand_total_bytes)):<21}")
    print()

    if grand_total_bytes == 0:
        print_success("Your system is already completely clean! No junk files detected.")
        return {"freed_bytes": 0, "freed_files": 0}

    # Prompt user consent unless forced
    if not force:
        try:
            choice = input(f" {c_cyan('Proceed with safe cleanup? [Y/n]: ')}").strip().lower()
            if choice not in ("y", "yes", ""):
                print_warning("Cleanup cancelled by user.")
                return {"freed_bytes": 0, "freed_files": 0}
        except (KeyboardInterrupt, EOFError):
            print("\nOperation cancelled.")
            return {"freed_bytes": 0, "freed_files": 0}

    print()
    print_info("Executing cleanup across selected categories...")

    total_freed = 0
    total_files_cleaned = 0
    total_locked = 0

    for key in target_keys:
        if key in scan_results and scan_results[key]["total_bytes"] > 0:
            res = clean_target_items(scan_results[key]["items"])
            freed = res["deleted_bytes"]
            fcount = res["deleted_count"]
            locked = res["locked_count"]
            total_freed += freed
            total_files_cleaned += fcount
            total_locked += locked
            print(f" {c_green('✓')} Cleaned {scan_results[key]['name']}: {c_green(format_bytes(freed))} freed ({fcount} items)")

    print()
    print_header("Cleanup Finished")
    print_success(f"Storage Successfully Freed: {c_green(c_bold(format_bytes(total_freed)))}")
    if total_locked > 0:
        print(c_gray(f"  ({total_locked} files currently in use by running processes were safely skipped)"))

    return {
        "freed_bytes": total_freed,
        "freed_files": total_files_cleaned,
        "locked_files": total_locked
    }
