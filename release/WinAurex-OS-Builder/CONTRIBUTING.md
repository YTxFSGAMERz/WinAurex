# Contributing to WinAurex OS Builder

Thank you for your interest in contributing to the WinAurex OS Builder project! This repository serves as the foundation for creating debloated Windows 11 images using native Microsoft tools.

## How to Contribute

1. **Fork the Repository**: Start by forking this repository to your own GitHub account.
2. **Clone**: Clone your fork to your local machine.
3. **Branch**: Create a new branch for your feature or bug fix.
4. **Make Changes**: 
   - Ensure your PowerShell code follows standard best practices.
   - Do **NOT** use external third-party executables for image compilation or registry injection. We strictly use native binaries like `DISM` and `oscdimg`.
   - If adding app packages to the removal list, ensure they are thoroughly tested and don't break core system functionality.
5. **Test**: Run your modified scripts on a test ISO and verify the resulting image boots and functions correctly.
6. **Submit a Pull Request**: Submit a detailed PR explaining what changes you made and why.

## Reporting Issues
If you encounter a bug or have a feature request, please open an issue in the issue tracker. Provide as much detail as possible, including Windows version, the specific script you ran, and any error logs generated.
