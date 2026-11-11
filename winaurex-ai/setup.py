from setuptools import setup, find_packages

setup(
    name="winaurex-ai",
    version="1.0.0",
    description="Trained Neural & Heuristic Windows Optimization Engine",
    author="Farhan Ahmad",
    packages=find_packages(),
    install_requires=[
        "psutil>=5.9.0",
        "numpy>=1.20.0"
    ],
    entry_points={
        "console_scripts": [
            "winaurex-ai=winaurex_ai.scanner:run_live_scan",
        ],
    },
    python_requires=">=3.8",
)
