
name: "💡 Architecture Expansion Proposal"
description: "Propose an optimization module or architectural expansion"
title: "[PROP] - "
labels:
  - enhancement
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        ## WinAurex Architecture Expansion Proposal
        Suggest a useful technical improvement or new feature.

  - type: dropdown
    id: module_class
    attributes:
      label: Module Class
      description: Select the type of proposed change.
      options:
        - Performance Optimization
        - Security Enhancement
        - GUI Dashboard
        - System Architecture
        - Other
    validations:
      required: true

  - type: textarea
    id: concept
    attributes:
      label: "🧠 1. Concept Specification"
      description: Describe your proposed feature.
      placeholder: Explain the feature and how it works.
    validations:
      required: true

  - type: checkboxes
    id: impact
    attributes:
      label: "📊 2. Expected Impact"
      description: Select all expected improvements.
      options:
        - label: Latency Reduction (DPC/ISR timing)
        - label: Context Switching / Scheduler Throughput
        - label: RAM Footprint Optimization
        - label: Rollback Reliability Enhancement
        - label: GUI Dashboard Features
        - label: Cybersecurity / Telemetry Hardening

  - type: textarea
    id: technical_schema
    attributes:
      label: "🔧 3. Technical Schema & Scripts"
      description: Suggest registry entries, PowerShell APIs, or logic files.
      render: powershell
      placeholder: |
        # Add prototype script or registry changes here

  - type: textarea
    id: rollback
    attributes:
      label: "🛡️ 4. Rollback Compatibility"
      description: Explain how to restore the original Windows settings.
      render: powershell
      placeholder: |
        # Add rollback or restore code here
    validations:
      required: true
