using System;
using System.Collections.Generic;

namespace WinAurex.Models.Execution
{
    public class ExecutionJournal
    {
        public int SchemaVersion { get; init; } = 1;
        public Guid ExecutionId { get; init; }
        public DateTimeOffset StartedAt { get; init; } = DateTimeOffset.UtcNow;
        public List<JournalEntry> Events { get; init; } = new();
    }

    [System.Text.Json.Serialization.JsonPolymorphic(TypeDiscriminatorPropertyName = "$type")]
    [System.Text.Json.Serialization.JsonDerivedType(typeof(ExecutionStartedEntry), typeDiscriminator: "ExecutionStarted")]
    [System.Text.Json.Serialization.JsonDerivedType(typeof(ExecutionCompletedEntry), typeDiscriminator: "ExecutionCompleted")]
    [System.Text.Json.Serialization.JsonDerivedType(typeof(OperationStartedEntry), typeDiscriminator: "OperationStarted")]
    [System.Text.Json.Serialization.JsonDerivedType(typeof(OperationProgressEntry), typeDiscriminator: "OperationProgress")]
    [System.Text.Json.Serialization.JsonDerivedType(typeof(OperationCompletedEntry), typeDiscriminator: "OperationCompleted")]
    [System.Text.Json.Serialization.JsonDerivedType(typeof(OperationFailedEntry), typeDiscriminator: "OperationFailed")]
    public abstract class JournalEntry
    {
        public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.UtcNow;
    }

    public class ExecutionStartedEntry : JournalEntry 
    { 
        public string PlanName { get; init; } = string.Empty;
    }

    public class ExecutionCompletedEntry : JournalEntry 
    { 
        public bool IsSuccess { get; init; }
    }

    public class OperationStartedEntry : JournalEntry
    {
        public OperationId OperationId { get; init; }
    }

    public class OperationProgressEntry : JournalEntry
    {
        public OperationId OperationId { get; init; }
        public string Message { get; init; } = string.Empty;
    }

    public class OperationCompletedEntry : JournalEntry
    {
        public OperationId OperationId { get; init; }
        public string UndoData { get; init; } = string.Empty;
    }

    public class OperationFailedEntry : JournalEntry
    {
        public OperationId OperationId { get; init; }
        public string ErrorMessage { get; init; } = string.Empty;
    }
}
