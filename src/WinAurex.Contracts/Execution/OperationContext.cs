using System;
using WinAurex.Models.Execution;

namespace WinAurex.Contracts.Execution
{
    public record OperationContext : PlanContext
    {
        public ExecutionJournal Journal { get; init; } = null!;
        public ICapabilityProvider Provider { get; init; } = null!;
        public ProviderResult? BackupResult { get; set; }
        public ProviderResult? ExecutionResult { get; set; }
        public ProviderResult? VerificationResult { get; set; }

        public OperationContext(PlanContext baseContext) 
            : base(baseContext.ExecutionId, baseContext.IsDryRun, baseContext.CancellationToken, 
                   baseContext.CurrentUser, baseContext.IsElevated, baseContext.Culture, 
                   baseContext.WorkingDirectory, baseContext.Logger)
        {
            Variables = baseContext.Variables;
        }
    }
}
