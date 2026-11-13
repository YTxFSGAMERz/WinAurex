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
        public int Percentage
        {
            get
            {
                if (TotalOperations <= 0 || CompletedOperations <= 0)
                {
                    return 0;
                }

                var percentage = (int)Math.Round((double)CompletedOperations / TotalOperations * 100);
                return Math.Clamp(percentage, 0, 100);
            }
        }
        
        public string Message { get; init; } = string.Empty;
    }
}
