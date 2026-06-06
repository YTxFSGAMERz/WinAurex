# Security Policy

## Supported Versions

Currently, only the latest major release of the **WinAurex** framework is supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 5.x.x   | :white_check_mark: |
| < 5.0.0 | :x:                |

## Reporting a Vulnerability

Because this framework modifies the Windows Registry and interacts with core OS services, we take security vulnerabilities very seriously. 

A vulnerability in this project typically means:
* A script inadvertently degrades the security posture of the OS without explicit warning.
* A script is vulnerable to local privilege escalation or injection (though the framework requires administrative execution by design).
* The WPF Dashboard executes untrusted inputs in a dangerous manner.

**Do not report vulnerabilities via public GitHub Issues.**

If you discover a security vulnerability, please email the repository maintainers directly or use the GitHub Security Advisory feature (if enabled on the repository).

We will acknowledge receipt of your vulnerability report within 72 hours and strive to send you regular updates about our progress. If the issue is confirmed, we will issue a patch in an accelerated release.

## Scope
Please note that "disabling Windows Defender" or "disabling Windows Update" are explicitly provided as opt-in tools for advanced users. These are features of the framework (always accompanied by severe warnings), not vulnerabilities. A vulnerability is an *unintended* compromise of security.
