import os
import shutil
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
from setuptools.command.sdist import sdist

DIRECTORIES_TO_INCLUDE = ["Core", "Tweaks", "Profiles", "Tools", "GUI"]
FILES_TO_INCLUDE = ["winaurex.cmd", "PC_Cleaner.bat", "Start.bat", "Launch_Dashboard.ps1"]


def sync_bundled_assets(target_dir):
    root_dir = os.path.dirname(os.path.abspath(__file__))
    for d in DIRECTORIES_TO_INCLUDE:
        src = os.path.join(root_dir, d)
        dst = os.path.join(target_dir, d)
        if os.path.exists(src):
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
    for f in FILES_TO_INCLUDE:
        src = os.path.join(root_dir, f)
        dst = os.path.join(target_dir, f)
        if os.path.exists(src):
            shutil.copy2(src, dst)


class CustomBuildPy(build_py):
    def run(self):
        pkg_dir = os.path.join(self.build_lib, "winaurex")
        os.makedirs(pkg_dir, exist_ok=True)
        sync_bundled_assets(pkg_dir)
        super().run()


class CustomSdist(sdist):
    def make_release_tree(self, base_dir, files):
        super().make_release_tree(base_dir, files)
        pkg_dir = os.path.join(base_dir, "winaurex")
        sync_bundled_assets(pkg_dir)


setup(
    packages=find_packages(),
    cmdclass={
        "build_py": CustomBuildPy,
        "sdist": CustomSdist,
    },
    package_data={
        "winaurex": ["**/*"],
    },
    include_package_data=True,
)
