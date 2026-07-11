using System.Collections.Generic;

namespace WinAurex.Models.Execution.Operations
{
    public record RegFileTarget(string FilePath) : OperationTarget;

    public record RegFileIntent(bool RequireElevation = true) : OperationIntent;

    public class RegFileOperation : ExecutionOperation<RegFileTarget, RegFileIntent>
    {
        public RegFileOperation(OperationId id) : base(id) { }
    }
}
