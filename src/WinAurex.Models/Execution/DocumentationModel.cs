using System;
using System.Collections.Generic;

namespace WinAurex.Models.Execution.Documentation
{
    /// <summary>
    /// An intermediate model representing the execution plan documentation before rendering into markdown or UI elements.
    /// </summary>
    public class DocumentationModel
    {
        public string PlanName { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public string Author { get; init; } = string.Empty;
        public string Version { get; init; } = string.Empty;
        public RiskLevel RiskLevel { get; init; }
        public bool RequiresRestart { get; init; }
        public bool RequiresElevation { get; init; }

        public List<OperationDocumentation> Operations { get; init; } = new();
    }

    public class OperationDocumentation
    {
        public string OperationId { get; init; } = string.Empty;
        public string ProviderName { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public bool SupportsRollback { get; init; }
        
        public Dictionary<string, string> Parameters { get; init; } = new();
    }
}
