using System;
using System.Collections.Generic;

using CommunityToolkit.Mvvm.ComponentModel;

namespace WinAurex.Models
{
    public partial class SystemAction : ObservableObject
    {
        public string Id { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public RiskLevel RiskLevel { get; set; } = RiskLevel.Safe;
        public bool RequiresAdmin { get; set; } = true;
        public RestoreMethod RestoreMethod { get; set; } = RestoreMethod.RegistryRevert;
        
        // Tells the dispatcher which handler to use (e.g., "BatchScript", "NativeCSharp")
        public string HandlerType { get; set; } = "NativeCSharp";
        
        // Metadata for the handler (e.g., the path to the script or the registry key)
        public Dictionary<string, string> HandlerMetadata { get; set; } = new Dictionary<string, string>();
        
        public List<string> Dependencies { get; set; } = new List<string>();

        public WinAurex.Models.Execution.DetectionRule? Detection { get; set; }

        [ObservableProperty]
        public partial List<ActionExecutionMethod> AvailableMethods { get; set; } = new();

        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(ExecutionPlan))]
        [NotifyPropertyChangedFor(nameof(RollbackPlan))]
        public partial ActionExecutionMethod? SelectedMethod { get; set; }

        public WinAurex.Models.Execution.ExecutionPlan? ExecutionPlan => SelectedMethod?.ExecutionPlan;
        public WinAurex.Models.Execution.ExecutionPlan? RollbackPlan => SelectedMethod?.RollbackPlan;

        [ObservableProperty]
        public partial bool IsExecuting { get; set; }

        [ObservableProperty]
        public partial bool IsApplied { get; set; }
    }

    public partial class ActionExecutionMethod : ObservableObject
    {
        [ObservableProperty]
        public partial string Name { get; set; } = string.Empty;

        public WinAurex.Models.Execution.ExecutionPlan ExecutionPlan { get; set; } = new();
        public WinAurex.Models.Execution.ExecutionPlan? RollbackPlan { get; set; }
    }
}
