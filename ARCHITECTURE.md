# WinAurex Architecture & Design Constitution
**Architecture Version:** v1.0  
**Last Updated:** 2026-07-09  

This document serves as the absolute source of truth for the WinAurex architecture. It exists to protect the long-term extensibility of the codebase. Every new decision, feature, and pull request must be evaluated against this constitution. 

If you are about to introduce a new dependency or project, ask yourself: *"Does this make WinAurex easier to extend in two years?"* and *"Can this live inside an existing bounded context?"*

---

## Product Philosophy
> **WinAurex is an offline-first, modular Windows management platform that enables users to inspect, configure, automate, and restore Windows through transparent, composable, and safety-first operations.**

---

## 1. Quality Attributes & Non-Goals

### Quality Attributes
- **Maintainability:** ★★★★★
- **Transparency:** ★★★★★
- **Safety:** ★★★★★
- **Offline:** ★★★★★
- **Extensibility:** ★★★★★
- **Performance:** ★★★★☆

### Non-Goals
❌ Cloud-first  
❌ Mandatory internet  
❌ Background telemetry  
❌ Kernel drivers  
❌ Registry modifications without rollback  
❌ Hidden or opaque changes  

---

## 2. Project Structure & Dependency Rules (FROZEN)

The architecture is strictly restricted to these 9 projects. **Do NOT add new projects like `Utilities`, `Shared`, `Helpers`, or `Framework`.**

```text
WinAurex.App
    ↓
WinAurex.Services
    ↓
WinAurex.Infrastructure
    ↓
WinAurex.Core
    ↓
WinAurex.Models

WinAurex.Contracts
↑ (Referenced by everyone)
```
*Note: `Contracts` is a shared abstraction layer. Nothing may depend on implementation, only interfaces.*

**Architecture Tests:** We enforce these boundaries using CI architecture tests (e.g., `App cannot reference Infrastructure`).

---

## 3. Terminology

We do not use vague terms like "Action" or "Tweak" interchangeably. 
- **Capability**: A low-level Windows mechanism (e.g., Registry, ServiceControl).
- **Capability Provider**: A generic, strongly typed executor for a capability (e.g., `RegistryCapabilityProvider`).
- **Module**: A collection of operations (e.g., Privacy Module) that builds plans.
- **Execution Operation**: An atomic, polymorphic intent composed of capability-specific data (e.g., `RegistryOperation`).
- **Execution Plan**: A compiled, ordered list of operations with metadata.
- **Execution Journal**: An immutable timeline of events (`ExecutionStarted`, `OperationStarted`, etc.) representing an execution audit trail.
- **Restore/Undo Data**: State saved prior to an operation, used by the provider to rollback.

---

## 4. Architectural Decision Records (ADRs)

Any significant architectural change must be documented in `docs/architecture/adr/`.
An ADR explains **why** a decision was made (Context, Decision, Consequences), preserving history for future contributors.

---

## 5. Coding Principles

- **One class → One responsibility.**
- **No static service locators.**
- **Constructor injection only.**
- **No reflection unless strictly justified.**
- **Async all the way.**
- **CancellationToken everywhere.**

---

## 6. The Execution Engine & Pipeline

The `ExecutionEngine` does not directly execute features. It orchestrates a strict, unskippable pipeline using dynamically resolved providers via Dependency Injection.

`Validation (Conflict Detection) → Dry Run (Analyze) → Authorization → Safety (Backups) → Execution → Verification → Journaling (Immutable Events) → Event Publishing`

---

## 7. The Event Bus

The `IEventBus` decouples the system and prevents spaghetti dependencies. It remains intentionally tiny: `Publish`, `Subscribe`, `Unsubscribe`.

---

## 8. Modules & The Manifest System

Modules do not perform work. They *describe* work via lightweight C# registration and JSON manifests.

---

## 9. Design Principles
- **Dashboard is a Status Center:** Answers "How healthy is this machine?"
- **Intent (The Planner):** WinAurex generates an Execution Plan that the user must approve before execution begins.
- **Reusable Design System:** UI relies on composable macro-controls (e.g., `SettingCard`).
- **Offline First & Transparent Docs:** Documentation is bundled locally, linked directly via `ⓘ Learn More` buttons.
