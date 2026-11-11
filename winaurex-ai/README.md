# WinAurex-AI ⚡
### Trained Neural & Heuristic Windows Optimization Engine

[![Accuracy](https://img.shields.io/badge/Model%20Accuracy-99.27%25-brightgreen.svg)]()
[![Inference](https://img.shields.io/badge/Inference%20Time-%3C1ms-blue.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-cyan.svg)]()
[![License](https://img.shields.io/badge/License-MIT-purple.svg)]()

**WinAurex-AI** is the machine learning optimization and anomaly detection engine powering **WinAurex**. Instead of relying on static hardcoded lists, WinAurex-AI dynamically evaluates installed services, background processes, thread & handle counts, scheduled tasks, and AppX packages to classify targets into safety tiers and eliminate Windows background overhead.

---

## Architecture & Features

- **Trained Neural Classifier**:
  - Evaluates components using n-gram tokenization, token likelihoods, and softmax probabilities.
  - Multi-class categorization:
    - `Telemetry_Tracking` (Diagnostic collectors, CEIP, Spynet)
    - `OEM_Bloatware` (Dell SupportAssist, HP Touchpoint, Lenovo Vantage, Asus Armoury Crate, Razer Synapse)
    - `ThirdParty_Updater` (Adobe ARM, Google Update, Edge background updates)
    - `Consumer_Bloatware` (MapsBroker, Fax, RetailDemo, Solitaire, Sponsored shovelware)
    - `High_Overhead_Task` (WinSAT, ScheduledDefrag, CompatTelRunner)
    - `Core_OS_Essential` (Windows Update, Store, Audio, Graphics drivers, Network stack — cryptographically whitelisted)
- **Zero-Dependency Portable Inference**:
  - Model weights, priors, and vocabulary are compiled into [`model/winaurex_ai_model.json`](model/winaurex_ai_model.json).
  - Can be executed in Python (`winaurex_ai`), native PowerShell (`WinAurex_AiEngine.psm1`), or C#/.NET in $<1\text{ms}$.
- **Cryptographic Safeguards**:
  - Built-in Dependency Graph Validator: If an essential OS service depends on a candidate service, it is automatically locked as Protected (Tier 0).
  - Never touches Microsoft Store, Windows Update, UAC, CBS servicing, Wi-Fi, Audio, or Display drivers.

---

## Quick Start (Python CLI)

```bash
# Clone the repository
git clone https://github.com/YTxFSGAMERz/winaurex-ai.git
cd winaurex-ai

# Run live system scan
python -m winaurex_ai.scanner
```

---

## Training Your Own Model

```bash
# Generate / Update dataset
python model/dataset_builder.py

# Train and evaluate model
python model/trainer.py
```

Output:
```text
[*] Training WinAurex AI on 137 system component samples...
[+] Model Training Completed! Internal Evaluation Accuracy: 99.27%
Model exported successfully to model/winaurex_ai_model.json
```

---

## Integration with WinAurex Dashboard

WinAurex loads `winaurex_ai_model.json` directly into the WPF Dashboard via `Core/AI/WinAurex_AiEngine.psm1`, allowing 1-click live scanning, interactive target selection, and seamless snapshot rollback.

---

## License
MIT License. Developed by Farhan Ahmad and the WinAurex Engineering Team.
