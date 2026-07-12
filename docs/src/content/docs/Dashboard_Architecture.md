---
title: "WPF Dashboard Architecture — PowerShell GUI Framework"
description: "Technical guide to the WinAurex WPF XAML dashboard. PowerShell-driven GUI architecture, tab system, and extensibility patterns."
---

# WPF Dashboard Architecture Guide

As of version 5.0.0, **WinAurex** utilizes a native WPF (Windows Presentation Foundation) dashboard powered by a compiled C# .NET architecture, removing the limitations of raw PowerShell GUI parsing while maintaining a highly modular structure.

This document serves as a developer blueprint for the dashboard internals.

## Core Components

The dashboard is built as a strictly layered C# .NET application located in the `src/` directory:

1. **`src/WinAurex.App/` (WPF UI Layer & ViewModels)**
   This layer contains the XAML views and MVVM ViewModels. It handles all visual logic, bindings, and user interactions.
2. **`src/WinAurex.Services/` (Business Logic & Orchestration)**
   This layer orchestrates the application logic, bridging the UI and the underlying system modifications.
3. **`src/WinAurex.Infrastructure/` (Capability Providers)**
   This layer contains the execution engines for Registry modifications, Services, and PowerShell scripts (calling into the `Tweaks/` and `Core/` directories).

## The Event Binding Flow

If you are a developer looking to add a new button or tab to the dashboard, follow this flow:

### 1. Add the UI Element in XAML
Open the appropriate view in `src/WinAurex.App/Views/`. Locate the appropriate Tab or Panel, and add your element. 
**Critical Rule:** Bind your controls using standard MVVM data bindings.

```xml
<Button Command="{Binding ApplyMyNewTweakCommand}" Content="Apply My Tweak" Style="{StaticResource ActionButton}"/>
```

### 2. Create the Command in ViewModel
Open the corresponding ViewModel in `src/WinAurex.App/ViewModels/` and define an `ICommand` or `RelayCommand`.

```csharp
public ICommand ApplyMyNewTweakCommand { get; }
```

### 3. Bind the Logic via Infrastructure
Wire your command to execute a script via the `WinAurex.Infrastructure` capability providers.

```csharp
ApplyMyNewTweakCommand = new RelayCommand(async () => {
    await _powerShellService.ExecuteScriptAsync(@"Tweaks\YourCategory\YourScript.ps1");
});
```

## Performance & Telemetry (Observability)
The dashboard features an "Observability" tab that streams live system telemetry.
We achieve this without freezing the UI thread by using efficient `.NET` classes rather than slow WMI calls:
* **CPU:** `[System.Diagnostics.PerformanceCounter]`
* **RAM:** `GlobalMemoryStatusEx` via inline C# P/Invoke.
* **Uptime:** `[Environment]::TickCount64`

These metrics are updated via a `System.Windows.Threading.DispatcherTimer` set to a 1000ms tick interval.

## Why XAML over WinForms?
WinForms is legacy, blocking, and difficult to style dynamically. WPF allows us to use sophisticated layout grids (`Grid.RowDefinitions`, `Grid.ColumnDefinitions`) and hardware-accelerated rendering effects (like DropShadows and Border radiuses) that look native to Windows 11 without requiring any extra dependencies.

## Extending the Dashboard
The .NET architecture is inherently extensible. If you need to build entirely new views, add new UserControls to `WinAurex.App/Views/` and wire them up using Dependency Injection in `App.xaml.cs`. Use standard MVVM patterns, leveraging the interfaces defined in `WinAurex.Contracts` to maintain loose coupling across the architecture.

