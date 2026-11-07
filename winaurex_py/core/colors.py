"""
Terminal Colors & Cyber Styling for WinAurex Python Engine
Enables Virtual Terminal Processing in Windows Console for native ANSI colors.
"""

import os
import sys
import ctypes

# Enable ANSI escape sequences on Windows cmd/PowerShell
def init_colors():
    if sys.platform == "win32":
        try:
            kernel32 = ctypes.windll.kernel32
            # STD_OUTPUT_HANDLE = -11
            handle = kernel32.GetStdHandle(-11)
            mode = ctypes.c_ulong()
            kernel32.GetConsoleMode(handle, ctypes.byref(mode))
            # ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
            kernel32.SetConsoleMode(handle, mode.value | 0x0004)
        except Exception:
            pass

init_colors()

# ANSI Color Codes
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
MAGENTA = "\033[95m"
WHITE = "\033[97m"
GRAY = "\033[90m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

def c_cyan(text: str) -> str: return f"{CYAN}{text}{RESET}"
def c_green(text: str) -> str: return f"{GREEN}{text}{RESET}"
def c_yellow(text: str) -> str: return f"{YELLOW}{text}{RESET}"
def c_red(text: str) -> str: return f"{RED}{text}{RESET}"
def c_magenta(text: str) -> str: return f"{MAGENTA}{text}{RESET}"
def c_gray(text: str) -> str: return f"{GRAY}{text}{RESET}"
def c_bold(text: str) -> str: return f"{BOLD}{text}{RESET}"

def print_header(title: str):
    line = "=" * 74
    print(c_cyan(line))
    print(c_cyan(f"   {title.center(68)}   "))
    print(c_cyan(line))

def print_success(msg: str):
    print(f" {c_green('[+]')} {msg}")

def print_info(msg: str):
    print(f" {c_cyan('[*]')} {msg}")

def print_warning(msg: str):
    print(f" {c_yellow('[!]')} {msg}")

def print_error(msg: str):
    print(f" {c_red('[-]')} {msg}")
