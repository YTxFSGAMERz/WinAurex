using System.Collections.Generic;

namespace WinAurex.Models.Execution.Operations
{
    public record ScriptTarget(string FilePath, IReadOnlyList<string> Arguments) : OperationTarget;

    public abstract record ScriptIntent : OperationIntent;
    
    public record PowerShellIntent(bool RequireElevation = false, bool BypassExecutionPolicy = true) : ScriptIntent;
    
    public record BatchIntent(bool RequireElevation = false) : ScriptIntent;

    public class PowerShellOperation : ExecutionOperation<ScriptTarget, PowerShellIntent>
    {
        public PowerShellOperation(OperationId id) : base(id) { }
    }

    public class BatchOperation : ExecutionOperation<ScriptTarget, BatchIntent>
    {
        public BatchOperation(OperationId id) : base(id) { }
    }
}
