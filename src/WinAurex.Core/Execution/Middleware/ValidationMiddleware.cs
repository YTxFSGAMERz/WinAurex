using System;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution.Middleware
{
    public class ValidationMiddleware : IExecutionMiddleware
    {
        public async Task InvokeAsync(ExecutionOperation operation, OperationContext context, OperationDelegate next)
        {
            if (context.Provider == null)
            {
                context.ExecutionResult = ProviderResult.Failure("Provider is missing.");
                return;
            }

            // In the future, this is where we check things like IsElevated
            // if operation requires elevation and context.IsElevated == false

            if (context.IsDryRun)
            {
                context.Journal.Events.Add(new OperationProgressEntry
                {
                    OperationId = operation.Id,
                    Message = $"Dry run: validating {operation.Description}"
                });

                try
                {
                    dynamic dynamicProvider = context.Provider;
                    ProviderResult analysis = await dynamicProvider.AnalyzeAsync((dynamic)operation, context);
                    context.ExecutionResult = analysis.IsSuccess
                        ? ProviderResult.Success()
                        : ProviderResult.Failure($"Dry run validation failed: {analysis.ErrorMessage}");
                }
                catch (Exception ex)
                {
                    context.ExecutionResult = ProviderResult.Failure($"Dry run validation failed: {ex.Message}");
                }

                return; // Stop pipeline if dry run
            }

            await next(operation, context);
        }
    }
}
