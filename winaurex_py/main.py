"""
WinAurex Python Engine - Main Master Orchestrator.
Connects all subsystems (Cleaner, Tweaks, Profiles, Repair, Observability, Rollback)
into a unified, high-performance terminal experience.
"""

import sys
import os
import argparse
import time

# Ensure project root is in sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from winaurex_py.core.colors import (
    c_cyan, c_green, c_yellow, c_red, c_bold, c_magenta, c_gray,
    print_header, print_success, print_info, print_warning, print_error
)
from winaurex_py.core.elevation import is_admin, require_admin
from winaurex_py.core.rollback import RollbackManager, session_rollback
from winaurex_py.cleaner.cleaner import run_cleaner_cli
from winaurex_py.observability.diagnostics import show_system_diagnostics
from winaurex_py.profiles.profiles import PROFILES, apply_profile
from winaurex_py.repair.repair import (
    run_sfc_scan, run_dism_repair, repair_network_stack, repair_windows_update
)
from winaurex_py.tweaks import (
    set_dark_mode, set_transparency,
    apply_privacy_shield,
    enable_game_mode, enable_hags, disable_gamedvr, set_raw_mouse_input, apply_all_gaming_tweaks,
    show_file_extensions, show_hidden_files, set_launch_to_this_pc, set_classic_context_menu, restart_explorer, apply_all_explorer_tweaks,
    optimize_network_throttling, optimize_system_responsiveness, flush_dns, apply_all_network_tweaks,
    enable_ultimate_performance,
    apply_all_debloat_tweaks
)

BANNER = f"""
{c_cyan("██╗    ██╗██╗███╗   ██╗ █████╗ ██╗   ██╗██████╗ ███████╗██╗  ██╗")}
{c_cyan("██║    ██║██║████╗  ██║██╔══██╗██║   ██║██╔══██╗██╔════╝╚██╗██╔╝")}
{c_cyan("██║ █╗ ██║██║██╔██╗ ██║███████║██║   ██║██████╔╝█████╗   ╚███╔╝ ")}
{c_magenta("██║███╗██║██║██║╚██╗██║██╔══██║██║   ██║██╔══██╗██╔══╝   ██╔██╗ ")}
{c_magenta("╚███╔███╔╝██║██║ ╚████║██║  ██║╚██████╔╝██║  ██║███████╗██╔╝ ██╗")}
{c_magenta(" ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝")}
{c_cyan("           >>> Pure Python Ultra-Performance Windows Engine <<<")}
{c_gray("                   Version 6.0.0 | Native Win32 API")}
"""

def print_banner():
    print(BANNER)
    admin_tag = c_green("[Administrator: YES]") if is_admin() else c_yellow("[Administrator: NO - Standard User]")
    print(f"  System Status: {admin_tag}\n")

def menu_tweaks():
    """Interactive submenu for individual tweaks."""
    while True:
        print_header("WinAurex Tweaks Subsystem")
        print(f" {c_cyan('[1]')} Toggle Dark Mode")
        print(f" {c_cyan('[2]')} Toggle Transparency Effects")
        print(f" {c_cyan('[3]')} Apply Anti-Telemetry Privacy Shield")
        print(f" {c_cyan('[4]')} Apply Gaming Suite (Game Mode, HAGS, Raw Mouse)")
        print(f" {c_cyan('[5]')} Apply File Explorer Productivity Tweaks")
        print(f" {c_cyan('[6]')} Enable Classic Windows 10 Right-Click Menu")
        print(f" {c_cyan('[7]')} Optimize Network Latency & Flush DNS")
        print(f" {c_cyan('[8]')} Enable Ultimate Performance Power Plan")
        print(f" {c_cyan('[9]')} Run Debloat Suite (Disable Sponsored Apps & DiagTrack)")
        print(f" {c_cyan('[0]')} Back to Main Menu")
        print()

        try:
            choice = input(f" {c_cyan('Select tweak [0-9]: ')}").strip()
        except (KeyboardInterrupt, EOFError):
            break

        if choice == "0":
            break
        elif choice == "1":
            res = set_dark_mode(True)
            print_success("Dark mode applied!")
        elif choice == "2":
            res = set_transparency(False)
            print_success("Transparency disabled for reduced GPU overhead.")
        elif choice == "3":
            res = apply_privacy_shield()
            print_success(f"Privacy shield applied ({res['success_count']} rules set).")
        elif choice == "4":
            res = apply_all_gaming_tweaks()
            print_success("Gaming latency optimizations applied!")
        elif choice == "5":
            res = apply_all_explorer_tweaks()
            print_success("File Explorer tweaks applied and Explorer restarted.")
        elif choice == "6":
            res = set_classic_context_menu(True)
            restart_explorer()
            print_success("Classic Windows 10 context menu enabled!")
        elif choice == "7":
            res = apply_all_network_tweaks()
            print_success("Network optimizations applied and DNS cache flushed.")
        elif choice == "8":
            res = enable_ultimate_performance()
            print_success(f"Power plan activated: {res.get('scheme', 'High Performance')}")
        elif choice == "9":
            res = apply_all_debloat_tweaks()
            print_success("Debloat rules and telemetry services disabled.")
        else:
            print_warning("Invalid selection.")
        
        session_rollback.save_manifest("Tweaks Menu Action")
        input(f"\n {c_gray('Press Enter to continue...')}")

def menu_repair():
    """Interactive submenu for Windows repair tools."""
    while True:
        print_header("WinAurex Windows Repair & Health Subsystem")
        print(f" {c_cyan('[1]')} Run System File Checker (sfc /scannow)")
        print(f" {c_cyan('[2]')} Run DISM Component Store RestoreHealth")
        print(f" {c_cyan('[3]')} Reset Network Stack & Winsock")
        print(f" {c_cyan('[4]')} Reset Windows Update Components")
        print(f" {c_cyan('[5]')} Run Complete System Repair (All Above)")
        print(f" {c_cyan('[0]')} Back to Main Menu")
        print()

        try:
            choice = input(f" {c_cyan('Select repair tool [0-5]: ')}").strip()
        except (KeyboardInterrupt, EOFError):
            break

        if choice == "0":
            break
        elif choice == "1":
            run_sfc_scan()
        elif choice == "2":
            run_dism_repair()
        elif choice == "3":
            repair_network_stack()
        elif choice == "4":
            repair_windows_update()
        elif choice == "5":
            print_info("Executing full Windows system health restoration sequence...")
            repair_network_stack()
            repair_windows_update()
            run_dism_repair()
            run_sfc_scan()
            print_success("Complete restoration sequence completed.")
        else:
            print_warning("Invalid selection.")

        input(f"\n {c_gray('Press Enter to continue...')}")

def menu_rollback():
    """Interactive rollback manager."""
    print_header("WinAurex Rollback & Restore Manager")
    manifests = RollbackManager.list_manifests()
    if not manifests:
        print_info("No rollback manifests found. Your settings have not been modified yet.")
        input(f"\n {c_gray('Press Enter to return...')}")
        return

    print(f" Found {len(manifests)} backup manifest(s):\n")
    for idx, m in enumerate(manifests, 1):
        ts = m.get("timestamp", "Unknown")
        desc = m.get("description", "Session")
        count = m.get("actions_count", 0)
        print(f" {c_cyan(f'[{idx}]')} {ts} - {desc} ({count} actions)")

    print(f" {c_cyan('[0]')} Cancel / Back")
    print()

    try:
        choice = input(f" {c_cyan('Select backup to restore [0-' + str(len(manifests)) + ']: ')}").strip()
        if choice == "0" or not choice:
            return
        idx = int(choice) - 1
        if 0 <= idx < len(manifests):
            target = manifests[idx]
            print_info(f"Restoring backup from {target['timestamp']}...")
            res = RollbackManager.apply_rollback(target["filepath"])
            if res["success"]:
                print_success(f"Rollback completed: {res['restored_count']} settings restored to their prior state.")
            else:
                print_error(f"Rollback encountered errors: {res['errors']}")
        else:
            print_warning("Invalid choice.")
    except Exception as e:
        print_error(f"Rollback failed: {e}")

    input(f"\n {c_gray('Press Enter to continue...')}")

def interactive_menu():
    """Main interactive terminal loop."""
    while True:
        print_banner()
        print(f" {c_cyan('[1]')} {c_bold('Storage Deep Cleaner')} (Detect & Purge Junk Safely)")
        print(f" {c_cyan('[2]')} {c_bold('Master Optimization Profiles')} (Max Performance, Debloat, Balanced)")
        print(f" {c_cyan('[3]')} {c_bold('System Tweaks Menu')} (Appearance, Privacy, Gaming, Network, Power)")
        print(f" {c_cyan('[4]')} {c_bold('Windows System Repair')} (SFC, DISM, Network Stack, Windows Update)")
        print(f" {c_cyan('[5]')} {c_bold('System Observability Dashboard')} (Hardware, RAM, Disks, Health)")
        print(f" {c_cyan('[6]')} {c_bold('Rollback & Undo Manager')} (Restore Previous Windows Settings)")
        if not is_admin():
            print(f" {c_yellow('[7]')} {c_yellow('Elevate to Administrator (UAC Prompt)')}")
        print(f" {c_cyan('[0]')} Exit")
        print()

        try:
            choice = input(f" {c_cyan('Enter your choice [0-' + ('7' if not is_admin() else '6') + ']: ')}").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nExiting WinAurex.")
            break

        if choice == "0":
            print(f"\n {c_green('Thank you for using WinAurex. Have a fast, clean day!')}")
            break
        elif choice == "1":
            run_cleaner_cli()
            input(f"\n {c_gray('Press Enter to return to main menu...')}")
        elif choice == "2":
            print_header("Master Profiles")
            for k, v in PROFILES.items():
                print(f" {c_cyan(f'[{k}]')}: {v['name']}")
                print(f"    {c_gray(v['description'])}\n")
            p_choice = input(f" {c_cyan('Enter profile name (or press Enter to cancel): ')}").strip()
            if p_choice in PROFILES:
                apply_profile(p_choice)
            elif p_choice:
                print_warning(f"Unknown profile: {p_choice}")
            input(f"\n {c_gray('Press Enter to return to main menu...')}")
        elif choice == "3":
            menu_tweaks()
        elif choice == "4":
            menu_repair()
        elif choice == "5":
            show_system_diagnostics()
            input(f"\n {c_gray('Press Enter to return to main menu...')}")
        elif choice == "6":
            menu_rollback()
        elif choice == "7" and not is_admin():
            if not require_admin():
                input(f"\n {c_gray('Press Enter to continue as standard user...')}")
        else:
            print_warning("Invalid selection.")
            time.sleep(1)

def main():
    parser = argparse.ArgumentParser(
        description="WinAurex Python Engine - Pure Python Windows Optimization & Maintenance Suite",
        prog="winaurex_py"
    )
    parser.add_argument("--clean", "-c", action="store_true", help="Launch Storage Deep Cleaner")
    parser.add_argument("--force", "-f", action="store_true", help="Run cleaner non-interactively")
    parser.add_argument("--profile", "-p", choices=list(PROFILES.keys()), help="Apply an optimization profile")
    parser.add_argument("--info", "-i", "--diagnostics", action="store_true", help="Show system observability dashboard")
    parser.add_argument("--repair", choices=["sfc", "dism", "network", "update", "all"], help="Run repair utility")
    parser.add_argument("--elevate", action="store_true", help="Elevate to Administrator if not already elevated")
    parser.add_argument("--rollback", nargs="?", const="latest", help="Rollback modifications from manifest")

    args = parser.parse_args()

    # Elevate if explicitly requested or if running standalone
    if args.elevate and not is_admin():
        require_admin()

    # CLI flag routing
    if args.clean:
        run_cleaner_cli(force=args.force)
    elif args.profile:
        apply_profile(args.profile)
    elif args.info:
        show_system_diagnostics()
    elif args.repair:
        if args.repair == "sfc":
            run_sfc_scan()
        elif args.repair == "dism":
            run_dism_repair()
        elif args.repair == "network":
            repair_network_stack()
        elif args.repair == "update":
            repair_windows_update()
        elif args.repair == "all":
            repair_network_stack()
            repair_windows_update()
            run_dism_repair()
            run_sfc_scan()
    elif args.rollback:
        manifests = RollbackManager.list_manifests()
        if not manifests:
            print_warning("No rollback manifests found.")
        elif args.rollback == "latest":
            target = manifests[0]
            print_info(f"Rolling back latest manifest: {target['filename']}")
            res = RollbackManager.apply_rollback(target["filepath"])
            print_success(f"Rollback result: {res}")
        else:
            res = RollbackManager.apply_rollback(args.rollback)
            print_success(f"Rollback result: {res}")
    else:
        # Default: Launch rich interactive terminal experience
        interactive_menu()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nOperation cancelled. Exiting WinAurex.")
        sys.exit(0)
    except Exception as e:
        import traceback
        print(f"\n[-] Fatal error encountered: {e}")
        traceback.print_exc()
        try:
            input("\nPress Enter to exit...")
        except Exception:
            pass
        sys.exit(1)
