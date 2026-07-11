using System;

namespace WinAurex.Models.Execution
{
    /// <summary>
    /// Represents the current progress of an execution plan, calculated entirely by the execution engine.
    /// </summary>
    public sealed record ExecutionProgress
    {
        public OperationId? CurrentOperation { get; init; }
        public int CompletedOperations { get; init; }
        public int TotalOperations { get; init; }
        
        /// <summary>
        /// Percentage completion (0 to 100).
        /// </summary>
        public int Percentage => TotalOperations == 0 ? 0 : (int)Math.Round((double)CompletedOperations / TotalOperations * 100);
        
        public string Message { get; init; } = string.Empty;
    }
}
