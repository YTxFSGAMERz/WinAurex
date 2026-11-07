"""
Automated Unit and Integration Tests for WinAurex Python Engine.
Verifies core Win32 system diagnostics, registry abstraction, cleaner safeguards,
and profile definitions.
"""

import os
import sys
import unittest

# Ensure project root is in sys.path
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from winaurex_py.core import colors, elevation, registry, rollback, system
from winaurex_py.cleaner.cleaner import is_path_safe, format_bytes, get_cleaner_targets
from winaurex_py.tweaks import get_appearance_status, get_active_power_scheme, get_privacy_status
from winaurex_py.profiles import PROFILES


class TestWinAurexCore(unittest.TestCase):
    def test_colors(self):
        colored = colors.c_green("OK")
        self.assertIn("OK", colored)
        self.assertIn(colors.GREEN, colored)
        self.assertIn(colors.RESET, colored)

    def test_elevation_check(self):
        admin = elevation.is_admin()
        self.assertIsInstance(admin, bool)

    def test_elevation_paths(self):
        main_script = elevation.get_main_script()
        self.assertTrue(os.path.isfile(main_script))
        self.assertTrue(main_script.endswith("main.py"))
        project_root = elevation.get_project_root()
        self.assertTrue(os.path.isdir(project_root))

    def test_system_memory(self):
        mem = system.get_memory_info()
        self.assertIn("total_gb", mem)
        self.assertIn("used_gb", mem)
        self.assertIn("percent_used", mem)
        self.assertGreater(mem["total_gb"], 0)
        self.assertGreater(mem["percent_used"], 0)

    def test_system_uptime(self):
        up = system.get_uptime()
        self.assertIn("formatted", up)
        self.assertIn("m", up["formatted"])

    def test_system_os_info(self):
        os_info = system.get_os_info()
        self.assertIn("product_name", os_info)
        self.assertIn("Windows", os_info["product_name"])
        self.assertIn("arch", os_info)

    def test_system_disks(self):
        disks = system.get_disks_info()
        self.assertIsInstance(disks, list)
        self.assertGreater(len(disks), 0)
        c_drive = [d for d in disks if "C:" in d["drive"]]
        self.assertTrue(len(c_drive) > 0)
        self.assertGreater(c_drive[0]["total_gb"], 10)

    def test_registry_read(self):
        val = registry.get_reg_value("HKLM", r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName")
        self.assertIsNotNone(val)
        self.assertIn("Windows", val[0])


class TestWinAurexCleanerSafeguards(unittest.TestCase):
    def test_safeguard_exclusions(self):
        # Must strictly reject user sensitive directories
        self.assertFalse(is_path_safe(r"C:\Users\Admin\Downloads\setup.exe"))
        self.assertFalse(is_path_safe(r"C:\Users\Admin\Downloads"))
        self.assertFalse(is_path_safe(r"C:\Users\Admin\Pictures\family.png"))
        self.assertFalse(is_path_safe(r"C:\Users\Admin\Photos\trip.jpg"))
        self.assertFalse(is_path_safe(r"C:\Users\Admin\Documents\report.docx"))
        self.assertFalse(is_path_safe(r"C:\Users\Admin\Desktop\work.pdf"))
        self.assertFalse(is_path_safe(r"C:\Virtual Machines\win11.vmdk"))
        self.assertFalse(is_path_safe(r"D:\VMs\ubuntu.vhdx"))
        self.assertFalse(is_path_safe(r"C:\Code\Project\.git\config"))

    def test_safeguard_allowed_junk(self):
        # Must allow temporary and cache paths
        self.assertTrue(is_path_safe(r"C:\Windows\Temp\installer.tmp"))
        self.assertTrue(is_path_safe(r"C:\Users\Admin\AppData\Local\Temp\junk.log"))
        self.assertTrue(is_path_safe(r"C:\Users\Admin\AppData\Local\D3DSCache\cache.bin"))

    def test_format_bytes(self):
        self.assertEqual(format_bytes(0), "0.00 MB")
        self.assertEqual(format_bytes(1024 * 1024 * 50), "50.00 MB")
        self.assertEqual(format_bytes(1024 * 1024 * 1024 * 5), "5.00 GB")

    def test_cleaner_targets_definitions(self):
        targets = get_cleaner_targets()
        self.assertIn("user_temp", targets)
        self.assertIn("system_temp", targets)
        self.assertIn("prefetch", targets)
        self.assertIn("shader_cache", targets)
        self.assertIn("browser_cache", targets)


class TestWinAurexProfilesAndTweaks(unittest.TestCase):
    def test_profiles_definitions(self):
        self.assertIn("max_performance", PROFILES)
        self.assertIn("debloat_privacy", PROFILES)
        self.assertIn("balanced", PROFILES)

    def test_power_status(self):
        plan = get_active_power_scheme()
        self.assertIn("name", plan)
        self.assertTrue(len(plan["name"]) > 0)

    def test_appearance_status(self):
        status = get_appearance_status()
        self.assertIn("dark_mode", status)
        self.assertIn("transparency", status)

    def test_privacy_status(self):
        status = get_privacy_status()
        self.assertIn("telemetry_disabled", status)


if __name__ == "__main__":
    unittest.main()
