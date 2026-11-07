"""
WinAurex Tweaks Subsystem.
Modular Windows configuration, debloating, and optimization.
"""

from .appearance import set_dark_mode, set_transparency, get_appearance_status
from .privacy import apply_privacy_shield, get_privacy_status
from .gaming import enable_game_mode, enable_hags, disable_gamedvr, set_raw_mouse_input, apply_all_gaming_tweaks
from .explorer import show_file_extensions, show_hidden_files, set_launch_to_this_pc, set_classic_context_menu, restart_explorer, apply_all_explorer_tweaks
from .network import optimize_network_throttling, optimize_system_responsiveness, flush_dns, reset_network_stack, apply_all_network_tweaks
from .power import get_active_power_scheme, enable_ultimate_performance, disable_sleep_timeouts
from .debloat import apply_all_debloat_tweaks, disable_telemetry_services

__all__ = [
    "set_dark_mode", "set_transparency", "get_appearance_status",
    "apply_privacy_shield", "get_privacy_status",
    "enable_game_mode", "enable_hags", "disable_gamedvr", "set_raw_mouse_input", "apply_all_gaming_tweaks",
    "show_file_extensions", "show_hidden_files", "set_launch_to_this_pc", "set_classic_context_menu", "restart_explorer", "apply_all_explorer_tweaks",
    "optimize_network_throttling", "optimize_system_responsiveness", "flush_dns", "reset_network_stack", "apply_all_network_tweaks",
    "get_active_power_scheme", "enable_ultimate_performance", "disable_sleep_timeouts",
    "apply_all_debloat_tweaks", "disable_telemetry_services"
]
