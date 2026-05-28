# WPF Dashboard Architecture Guide

As of version 5.0.0, **Windows-Optimisations** utilizes a native WPF (Windows Presentation Foundation) dashboard powered entirely by PowerShell, removing the need for external compilers or heavy dependencies.

This document serves as a developer blueprint for the dashboard internals.

## Core Components

The dashboard relies on a strict separation of concerns:

1. **`GUI/Dashboard.xaml` (The View)**
   This file contains pure XML markup. It defines the layout, grids, buttons, colors, and visual logic (like `DropShadowEffect` hover animations). It contains **zero** execution logic.
2. **`Launch_Dashboard.ps1` (The Controller)**
   This script bootstraps the environment, loads the `PresentationFramework` assemblies, parses the XAML file, and maps the UI elements to PowerShell variables. It binds click events to the actual execution scripts located in the `Tweaks/` and `Core/` directories.

## The Event Binding Flow

If you are a developer looking to add a new button or tab to the dashboard, follow this flow:

### 1. Add the UI Element in XAML
Open `GUI/Dashboard.xaml`. Locate the appropriate Tab or Panel, and add your element. 
**Critical Rule:** You must assign it an `x:Name`. This is how PowerShell finds it.

```xml
<Button x:Name="BtnApplyMyNewTweak" Content="Apply My Tweak" Style="{StaticResource ActionButton}"/>
```

### 2. Map the Element in PowerShell
Open `Launch_Dashboard.ps1`. Find the "Map WPF Elements to PowerShell Variables" region.

```powershell
$BtnApplyMyNewTweak = $Window.FindName("BtnApplyMyNewTweak")
```

### 3. Bind the Logic
Further down in `Launch_Dashboard.ps1`, bind the click event to your execution script.

```powershell
$BtnApplyMyNewTweak.Add_Click({
    Write-Host "Running new tweak..."
    & "$PSScriptRoot\Tweaks\YourCategory\YourScript.ps1"
})
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
The `Launch_Dashboard.ps1` script is inherently extensible. If you need to build entirely new views, consider adding new `<TabItem>` elements within the main `<TabControl>`. Do not clutter the `Dashboard.xaml` with inline events (`Click="..."`) because PowerShell's `XamlReader` cannot resolve inline code-behind without dynamic compilation. All events **must** be wired via `$Element.Add_Click({})` in the PowerShell runspace.
