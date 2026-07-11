using System;
using System.Collections.Generic;
using System.Collections.Immutable;

namespace WinAurex.Models.Execution
{
    public class ExecutionPlan
    {
        public Guid Id { get; init; } = Guid.NewGuid();
        public string Name { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public string Author { get; init; } = string.Empty;
        public string Version { get; init; } = "1.0.0";
        public RiskLevel RiskLevel { get; init; } = RiskLevel.Safe;
        public TimeSpan EstimatedDuration { get; init; } = TimeSpan.Zero;
        public bool RequiresRestart { get; init; }
        public bool RequiresElevation { get; init; }
        public List<string> Tags { get; init; } = new();

        /// <summary>
        /// The global policy for the plan (timeouts, retries, verification).
        /// </summary>
        public ExecutionPolicy Policy { get; init; } = ExecutionPolicy.Default;

        /// <summary>
        /// The sequential list of operations to execute.
        /// </summary>
        public ImmutableList<ExecutionOperation> Operations { get; init; } = ImmutableList<ExecutionOperation>.Empty;
    }

    public class PlanningResult
    {
        public ExecutionPlan? Plan { get; init; }
        public bool IsSuccessful => Conflicts.Count == 0;

        public IReadOnlyList<string> Warnings { get; init; } = Array.Empty<string>();
        public IReadOnlyList<string> Conflicts { get; init; } = Array.Empty<string>();
    }
}
