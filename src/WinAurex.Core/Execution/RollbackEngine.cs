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
            bool overallSuccess = true;

            // Rollback happens in reverse order of completion.
            // We find all successful operations that have UndoData.
            var completedOps = journal.Events
                .OfType<OperationCompletedEntry>()
                .OrderByDescending(e => e.Timestamp)
                .ToList();

            foreach (var completedOp in completedOps)
            {
                var operation = plan.Operations.FirstOrDefault(o => o.Id == completedOp.OperationId);
                if (operation == null) continue;

                if (_registry.TryGetProvider(operation.Id.Provider, out var provider) && provider != null)
                {
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
                else
                {
                    overallSuccess = false;
                    context.Logger?.LogWarning($"No provider found to revert {operation.Id}");
                }
            }

            return overallSuccess;
        }
    }
}
