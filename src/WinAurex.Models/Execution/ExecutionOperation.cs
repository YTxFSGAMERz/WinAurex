using System;

namespace WinAurex.Models.Execution
{
    public abstract class ExecutionOperation
    {
        public OperationId Id { get; init; }
        public string Description { get; init; } = string.Empty;

        /// <summary>
        /// Any rollback data captured during the Backup phase. Used if the operation needs to be reverted.
        /// </summary>
        public string? RollbackData { get; init; }

        /// <summary>
        /// Optional operation-specific execution policy that overrides the plan's global policy.
        /// </summary>
        public ExecutionPolicy? PolicyOverride { get; init; }

        protected ExecutionOperation(OperationId id)
        {
            Id = id;
        }
    }

    public abstract class ExecutionOperation<TTarget, TIntent> : ExecutionOperation 
        where TTarget : OperationTarget 
        where TIntent : OperationIntent
    {
        public TTarget Target { get; init; } = null!;
        public TIntent Intent { get; init; } = null!;

        protected ExecutionOperation(OperationId id) : base(id) { }
    }
}
