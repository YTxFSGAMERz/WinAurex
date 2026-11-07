"""
Preset Performance & Optimization Profiles for WinAurex Python Engine.
Groups individual tweaks into battle-tested presets with automatic rollback backups.
"""

from typing import Dict, Any
from ..core.colors import (
    c_cyan, c_green, c_yellow, c_red, c_bold, c_magenta,
    print_header, print_success, print_info, print_warning
)
from ..core.rollback import session_rollback
from ..tweaks import (
    set_dark_mode,
    apply_privacy_shield,
    apply_all_gaming_tweaks,
    apply_all_explorer_tweaks,
    apply_all_network_tweaks,
    enable_ultimate_performance,
    apply_all_debloat_tweaks
)

PROFILES = {
    "max_performance": {
        "name": "Maximum Performance & Gaming",
        "description": "Unlocks Ultimate Performance power scheme, low-latency network stack, Game Mode, and raw 1:1 mouse input."
    },
    "debloat_privacy": {
        "name": "Privacy Shield & Deep Debloat",
        "description": "Stops telemetry services, blocks advertising IDs, disables sponsored app auto-installs and Bing search."
    },
    "balanced": {
        "name": "Productivity & Developer Balanced",
        "description": "Enables file extensions, classic context menu, Dark mode, DNS flush, and UI optimizations."
    }
}

def apply_profile(profile_key: str) -> Dict[str, Any]:
    """Applies a specified profile preset and generates a rollback manifest."""
    key = profile_key.lower().strip()
    if key not in PROFILES:
        print_warning(f"Unknown profile: '{profile_key}'. Available: {list(PROFILES.keys())}")
        return {"success": False, "error": "Unknown profile"}

    info = PROFILES[key]
    print_header(f"Applying Profile: {info['name']}")
    print_info(info["description"])
    print()

    results = []

    if key == "max_performance":
        print_info("Configuring high performance power scheme...")
        p1 = enable_ultimate_performance()
        results.append(p1)

        print_info("Enabling gaming and low-latency optimizations...")
        p2 = apply_all_gaming_tweaks()
        results.append(p2)

        print_info("Optimizing network responsiveness and flushing DNS...")
        p3 = apply_all_network_tweaks()
        results.append(p3)

    elif key == "debloat_privacy":
        print_info("Applying anti-telemetry privacy shield...")
        p1 = apply_privacy_shield()
        results.append(p1)

        print_info("Disabling sponsored consumer features and telemetry services...")
        p2 = apply_all_debloat_tweaks()
        results.append(p2)

        print_info("Configuring Explorer usability and classic context menu...")
        p3 = apply_all_explorer_tweaks()
        results.append(p3)

    elif key == "balanced":
        print_info("Configuring File Explorer developer settings...")
        p1 = apply_all_explorer_tweaks()
        results.append(p1)

        print_info("Enabling Dark theme...")
        p2 = set_dark_mode(True)
        results.append(p2)

        print_info("Optimizing network and flushing DNS...")
        p3 = apply_all_network_tweaks()
        results.append(p3)

    # Save session rollback manifest
    manifest_path = session_rollback.save_manifest(description=f"Profile: {info['name']}")
    if manifest_path:
        print_success(f"Rollback manifest created: {manifest_path}")

    print_success(f"Profile '{info['name']}' applied successfully!")
    return {
        "success": True,
        "profile": key,
        "manifest": manifest_path,
        "results": results
    }
