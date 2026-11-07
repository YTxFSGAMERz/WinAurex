"""
Gaming & Low-Latency Tweaks for Windows.
Enables Windows Game Mode, Hardware-Accelerated GPU Scheduling (HAGS),
disables GameDVR background capture overhead, and disables mouse acceleration for pure 1:1 input.
"""

from typing import Dict, Any
from ..core.registry import set_reg_value, get_reg_value
import winreg
from ..core.rollback import session_rollback

def enable_game_mode() -> Dict[str, Any]:
    """Enables Windows Game Mode for thread priority allocation."""
    r1 = set_reg_value("HKCU", r"Software\Microsoft\GameBar", "AllowAutoGameMode", 1, winreg.REG_DWORD)
    r2 = set_reg_value("HKCU", r"Software\Microsoft\GameBar", "AutoGameModeEnabled", 1, winreg.REG_DWORD)
    session_rollback.record_action(r1)
    session_rollback.record_action(r2)
    return {"success": r1.get("success", False) and r2.get("success", False), "tweak": "Game Mode Enabled"}

def enable_hags() -> Dict[str, Any]:
    """
    Enables Hardware-Accelerated GPU Scheduling (HwSchMode = 2).
    Requires GPU driver support (NVIDIA GTX 1000+, AMD RX 5600+, Intel Arc).
    Requires system restart to take effect.
    """
    r = set_reg_value("HKLM", r"SYSTEM\CurrentControlSet\Control\GraphicsDrivers", "HwSchMode", 2, winreg.REG_DWORD)
    session_rollback.record_action(r)
    return {"success": r.get("success", False), "tweak": "Hardware-Accelerated GPU Scheduling (HAGS) Enabled"}

def disable_gamedvr() -> Dict[str, Any]:
    """Disables GameDVR background recording to reclaim GPU and CPU overhead."""
    r1 = set_reg_value("HKCU", r"System\GameConfigStore", "GameDVR_Enabled", 0, winreg.REG_DWORD)
    r2 = set_reg_value("HKLM", r"SOFTWARE\Policies\Microsoft\Windows\GameDVR", "AllowGameDVR", 0, winreg.REG_DWORD)
    session_rollback.record_action(r1)
    session_rollback.record_action(r2)
    return {"success": r1.get("success", False) and r2.get("success", False), "tweak": "GameDVR Background Recording Disabled"}

def set_raw_mouse_input() -> Dict[str, Any]:
    """Disables Windows mouse acceleration curve for precision 1:1 pointer tracking."""
    r1 = set_reg_value("HKCU", r"Control Panel\Mouse", "MouseSpeed", "0", winreg.REG_SZ)
    r2 = set_reg_value("HKCU", r"Control Panel\Mouse", "MouseThreshold1", "0", winreg.REG_SZ)
    r3 = set_reg_value("HKCU", r"Control Panel\Mouse", "MouseThreshold2", "0", winreg.REG_SZ)
    session_rollback.record_action(r1)
    session_rollback.record_action(r2)
    session_rollback.record_action(r3)
    return {
        "success": r1.get("success", False) and r2.get("success", False) and r3.get("success", False),
        "tweak": "Raw 1:1 Mouse Input Enabled (No Acceleration)"
    }

def apply_all_gaming_tweaks() -> Dict[str, Any]:
    """Applies the full gaming optimization suite."""
    results = []
    results.append(enable_game_mode())
    results.append(enable_hags())
    results.append(disable_gamedvr())
    results.append(set_raw_mouse_input())

    success_count = sum(1 for r in results if r.get("success"))
    return {
        "applied_count": success_count,
        "total": len(results),
        "details": results
    }
