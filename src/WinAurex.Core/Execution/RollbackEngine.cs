using System;
using System.Linq;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution
{
    public interface IRollbackEngine
    {
        Task<bool> RollbackAsync(ExecutionPlan plan, ExecutionJournal journal, PlanContext context);
    }

    public class RollbackEngine : IRollbackEngine
    {
        private readonly ICapabilityRegistry _registry;

        public RollbackEngine(ICapabilityRegistry registry)
        {
            _registry = registry;
        }

        public async Task<bool> RollbackAsync(ExecutionPlan plan, ExecutionJournal journal, PlanContext context)
        {
            if (plan is null)
            {
                throw new ArgumentNullException(nameof(plan));
            }

            if (journal is null)
            {
                throw new ArgumentNullException(nameof(journal));
            }

            bool overallSuccess = true;

            var operationsById = plan.Operations
                .GroupBy(operation => operation.Id)
                .ToDictionary(group => group.Key, group => group.First());

            // Rollback happens in reverse order of completion.
            var completedOps = journal.Events
                .OfType<OperationCompletedEntry>()
                .OrderByDescending(entry => entry.Timestamp)
                .ToList();

            foreach (var completedOp in completedOps)
            {
                if (string.IsNullOrWhiteSpace(completedOp.UndoData))
                {
                    // Nothing was captured for this operation, so there is nothing to restore.
                    context.Logger?.LogInfo($"Nothing to revert for {completedOp.OperationId}: no undo data was captured.");
                    continue;
                }

                if (!operationsById.TryGetValue(completedOp.OperationId, out var operation))
                {
                    continue;
                }

                if (!_registry.TryGetProvider(operation.Id.Provider, out var provider) || provider is null)
                {
                    overallSuccess = false;
                    context.Logger?.LogWarning($"No provider found to revert {operation.Id}");
                    continue;
                }

                if (!provider.Metadata.SupportsRollback)
                {
                    // The provider declared that this operation cannot be reverted;
                    // reporting a failure here would blame the user for a known limit.
                    context.Logger?.LogInfo($"Skipping revert of {operation.Id}: {provider.Metadata.Id} does not support rollback.");
                    continue;
                }

                try
                {
                    dynamic dynamicProvider = provider;
                    ProviderResult result = await dynamicProvider.RevertAsync((dynamic)operation, completedOp.UndoData, context);
                    if (!result.IsSuccess)
                    {
                        overallSuccess = false;
                        context.Logger?.LogWarning($"Failed to revert {operation.Id}: {result.ErrorMessage}");
                    }
                }
                catch (Exception ex)
                {
                    overallSuccess = false;
                    context.Logger?.LogError($"Exception during revert of {operation.Id}", ex);
                }
            }

            return overallSuccess;
        }
    }
}
