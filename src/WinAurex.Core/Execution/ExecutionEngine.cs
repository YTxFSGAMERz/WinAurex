using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts.Exceptions;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution
{
    public class ExecutionEngine : IExecutionEngine
    {
        private readonly ICapabilityRegistry _registry;

        public ExecutionEngine(ICapabilityRegistry registry)
        {
            _registry = registry;
        }

        public async Task<ExecutionJournal> ExecutePlanAsync(ExecutionPlan plan, PlanContext context)
        {
            var journal = new ExecutionJournal
            {
                ExecutionId = context.ExecutionId,
                StartedAt = DateTimeOffset.UtcNow
            };

            journal.Events.Add(new ExecutionStartedEntry { PlanName = plan.Name });

            bool isSuccess = true;

            var middlewares = new System.Collections.Generic.List<IExecutionMiddleware>
            {
                new Middleware.JournalMiddleware(),
                new Middleware.ValidationMiddleware(),
                new Middleware.RetryMiddleware(),
                new Middleware.ProviderExecutionMiddleware()
            };

            foreach (var operation in plan.Operations)
            {
                if (context.CancellationToken.IsCancellationRequested)
                {
                    journal.Events.Add(new OperationFailedEntry 
                    { 
                        OperationId = operation.Id, 
                        ErrorMessage = "Execution was canceled by the user." 
                    });
                    isSuccess = false;
                    break;
                }

                _registry.TryGetProvider(operation.Id.Provider, out var provider);
                
                var opContext = new OperationContext(context)
                {
                    Journal = journal,
                    Provider = provider!
                };

                // Build pipeline
                OperationDelegate pipeline = (op, ctx) => Task.CompletedTask;
                for (int i = middlewares.Count - 1; i >= 0; i--)
                {
                    var middleware = middlewares[i];
                    var next = pipeline;
                    pipeline = (op, ctx) => middleware.InvokeAsync(op, ctx, next);
                }

                // Execute pipeline
                await pipeline(operation, opContext);

                if (opContext.ExecutionResult == null || !opContext.ExecutionResult.IsSuccess)
                {
                    var policy = operation.PolicyOverride ?? plan.Policy;
                    if (!policy.ContinueOnFailure)
                    {
                        isSuccess = false;
                        break;
                    }
                }
            }

            journal.Events.Add(new ExecutionCompletedEntry { IsSuccess = isSuccess });
            return journal;
        }

        private void EmitProgress(ExecutionJournal journal, OperationId operationId, int completed, int total, string message)
        {
            journal.Events.Add(new OperationProgressEntry
            {
                OperationId = operationId,
                Message = message
            });
            // We could also fire a real-time event to the UI layer here via an IEventAggregator if wired up
        }
    }
}
