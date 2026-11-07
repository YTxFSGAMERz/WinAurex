"""
Windows File Explorer Productivity Tweaks.
Enables file extensions visibility, shows hidden files, sets default folder to This PC,
and restores the classic full Windows 10 right-click context menu on Windows 11.
"""

import subprocess
from typing import Dict, Any
from ..core.registry import set_reg_value, delete_reg_value, get_reg_value
from ..core.rollback import session_rollback

EXPLORER_ADVANCED = r"Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
WIN11_CLASSIC_CONTEXT_KEY = r"Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

def show_file_extensions(enabled: bool = True) -> Dict[str, Any]:
    """Shows or hides file extensions (.txt, .exe, .py)."""
    val = 0 if enabled else 1
    res = set_reg_value("HKCU", EXPLORER_ADVANCED, "HideFileExt", val)
    session_rollback.record_action(res)
    return {"success": res.get("success", False), "tweak": f"File Extensions {'Visible' if enabled else 'Hidden'}"}

def show_hidden_files(enabled: bool = True) -> Dict[str, Any]:
    """Shows or hides hidden files in Explorer."""
    val = 1 if enabled else 2
    res = set_reg_value("HKCU", EXPLORER_ADVANCED, "Hidden", val)
    session_rollback.record_action(res)
    return {"success": res.get("success", False), "tweak": f"Hidden Files {'Visible' if enabled else 'Hidden'}"}

def set_launch_to_this_pc() -> Dict[str, Any]:
    """Configures Explorer to open 'This PC' instead of 'Home/Quick Access'."""
    res = set_reg_value("HKCU", EXPLORER_ADVANCED, "LaunchTo", 1)
    session_rollback.record_action(res)
    return {"success": res.get("success", False), "tweak": "Open Explorer to 'This PC'"}

def set_classic_context_menu(enabled: bool = True) -> Dict[str, Any]:
    """
    Enables classic full Windows 10 right-click menu in Windows 11 (bypasses 'Show more options').
    Setting enabled=False restores the default modern Windows 11 compact context menu.
    """
    if enabled:
        # Set empty string to InprocServer32 default value
        res = set_reg_value("HKCU", WIN11_CLASSIC_CONTEXT_KEY, "", "")
        session_rollback.record_action(res)
        return {"success": res.get("success", False), "tweak": "Classic Windows 10 Context Menu Enabled"}
    else:
        res = delete_reg_value("HKCU", WIN11_CLASSIC_CONTEXT_KEY, "")
        session_rollback.record_action(res)
        return {"success": res.get("success", False), "tweak": "Modern Windows 11 Context Menu Restored"}

def restart_explorer() -> bool:
    """Restarts Windows Explorer (explorer.exe) cleanly to apply shell changes."""
    try:
        subprocess.run(["taskkill", "/f", "/im", "explorer.exe"], capture_output=True)
        subprocess.Popen(["explorer.exe"])
        return True
    except Exception:
        return False

def apply_all_explorer_tweaks() -> Dict[str, Any]:
    """Applies all recommended Explorer usability tweaks."""
    results = [
        show_file_extensions(True),
        show_hidden_files(True),
        set_launch_to_this_pc(),
        set_classic_context_menu(True)
    ]
    restart_explorer()
    success_count = sum(1 for r in results if r.get("success"))
    return {
        "applied_count": success_count,
        "total": len(results),
        "details": results
    }
