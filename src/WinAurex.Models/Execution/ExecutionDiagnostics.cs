using System;
using System.Collections.Generic;

namespace WinAurex.Models.Execution
{
    /// <summary>
    /// Represents a bundled diagnostic report of an execution run that a user can export for support.
    /// </summary>
    public sealed record ExecutionDiagnostics
    {
        public Guid ExecutionId { get; init; }
        public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.UtcNow;
        
        // Environment Details
        public string EngineVersion { get; init; } = string.Empty;
        public string WindowsVersion { get; init; } = string.Empty;
        public string EnvironmentDetails { get; init; } = string.Empty;

        // Metrics
        public TimeSpan TotalExecutionTime { get; init; }
        public int TotalOperations { get; init; }
        public int SuccessfulOperations { get; init; }
        
        // Provider Info
        public Dictionary<string, string> ProviderVersions { get; init; } = new();

        // Issues
        public List<string> Warnings { get; init; } = new();
        public List<string> Errors { get; init; } = new();
    }
}
