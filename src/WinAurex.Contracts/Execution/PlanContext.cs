using System;
using System.Collections.Generic;
using System.Threading;

namespace WinAurex.Contracts.Execution
{
    public record PlanContext
    {
        public Guid ExecutionId { get; init; }
        public bool IsDryRun { get; init; }
        public CancellationToken CancellationToken { get; init; }
        public string CurrentUser { get; init; }
        public bool IsElevated { get; init; }
        public string Culture { get; init; }
        public string WorkingDirectory { get; init; }
        public Dictionary<string, object> Variables { get; init; } = new();
        public ILogContract Logger { get; init; }

        public PlanContext(
            Guid executionId,
            bool isDryRun,
            CancellationToken cancellationToken,
            string currentUser,
            bool isElevated,
            string culture,
            string workingDirectory,
            ILogContract logger)
        {
            ExecutionId = executionId;
            IsDryRun = isDryRun;
            CancellationToken = cancellationToken;
            CurrentUser = currentUser;
            IsElevated = isElevated;
            Culture = culture;
            WorkingDirectory = workingDirectory;
            Logger = logger;
        }
    }
}
