# WinAurex Execution Engine

The Execution Engine is the core orchestration platform of WinAurex. It is completely decoupled from high-level features (e.g., "Privacy", "Gaming"). Its sole responsibility is to take a declarative **Execution Plan** and safely enforce it on the host system.

---

## 1. Core Philosophy

> **The engine executes plans, not features.**

Modules (Privacy, Gaming) are responsible for *building* execution plans. The engine's job is simply to validate, execute, verify, journal, and roll back those plans without knowing or caring what higher-level feature they came from.

## 2. The Execution Lifecycle

The pipeline follows a strict, unskippable chronological flow:

1. **Planning (Module Layer)**: Modules declare what they want to do. The `ExecutionPlanner` merges these into a `PlanningResult` (handling conflicts, duplicates, dependencies).
2. **Dry Run (Analyze)**: The engine asks Capability Providers what *would* happen, checking preconditions.
3. **Authorization**: The engine guarantees necessary privileges (e.g., Administrator rights).
4. **Safety (Backup)**: Before mutating state, the provider creates `UndoData`.
5. **Execution**: The provider applies the atomic operation.
6. **Verification**: The provider confirms the actual system state matches the `ExpectedState`.
7. **Journaling**: The engine records the event as an immutable entry in a JSON journal.
8. **Event Publishing**: The result is broadcast over the `IEventBus` to update the UI.

## 3. Operations & Identity

An **Execution Operation** is an atomic, polymorphic unit of intent. It uses semantic identity (`OperationId`) rather than random GUIDs, allowing for deterministic search, history, and conflict resolution.

*Example Identifiers:*
- `Registry.Telemetry.Disable`
- `Service.DiagTrack.Stop`

## 4. Execution Context

Providers execute operations within a shared `ExecutionContext`. This provides context for the current run, including:
- `ExecutionId`
- `CancellationToken`
- `IsDryRun`
- `Logger`

## 5. Providers & Discovery

A **Capability Provider** is a strongly typed executor for a specific domain (e.g., `RegistryCapabilityProvider`). 
Providers are discovered automatically via Dependency Injection. The Engine queries providers for their metadata (`SupportsRollback`, `SupportsDryRun`) before handing them an operation.

## 6. The Execution Journal

Journals are immutable timelines stored as JSON. They do not just record "success" or "failure"; they record every event chronologically:
- `ExecutionStarted`
- `OperationStarted`
- `OperationCompleted` (with `UndoData`)
- `ExecutionCompleted`

Journals are stored chronologically in `%LocalAppData%\WinAurex\Journals\YYYY\MM\`.

## 7. Rollback

Because every operation is atomic and generates `UndoData`, rollback is deterministic. The `RollbackEngine` simply reads a past `ExecutionJournal` and replays the events backwards, calling `RevertAsync` on the respective providers.
