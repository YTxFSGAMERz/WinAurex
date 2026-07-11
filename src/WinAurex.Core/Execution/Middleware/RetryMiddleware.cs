using System;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts.Exceptions;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution.Middleware
{
    public class RetryMiddleware : IExecutionMiddleware
    {
        public async Task InvokeAsync(ExecutionOperation operation, OperationContext context, OperationDelegate next)
        {
            var policy = operation.PolicyOverride ?? new ExecutionPolicy(); // In reality, fetch from engine plan context if needed
            
            int maxAttempts = policy.MaxRetries + 1;
            Exception? lastException = null;

            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                try
                {
                    // Reset results before retrying
                    context.BackupResult = null;
                    context.ExecutionResult = null;
                    context.VerificationResult = null;

                    using var timeoutCts = policy.Timeout.HasValue 
                        ? new CancellationTokenSource(policy.Timeout.Value) 
                        : new CancellationTokenSource();
                        
                    using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(context.CancellationToken, timeoutCts.Token);
                    var attemptContext = context with { CancellationToken = linkedCts.Token };

                    await next(operation, attemptContext);

                    if (attemptContext.ExecutionResult != null && attemptContext.ExecutionResult.IsSuccess)
                    {
                        // Copy results back if context was duplicated (record cloning)
                        context.BackupResult = attemptContext.BackupResult;
                        context.ExecutionResult = attemptContext.ExecutionResult;
                        context.VerificationResult = attemptContext.VerificationResult;
                        return; // Success
                    }
                    
                    lastException = new ProviderException(attemptContext.ExecutionResult?.ErrorMessage ?? "Unknown failure");
                }
                catch (OperationCanceledException) when (policy.Timeout.HasValue && !context.CancellationToken.IsCancellationRequested)
                {
                    lastException = new ProviderException($"Operation timed out after {policy.Timeout.Value.TotalSeconds} seconds.");
                }
                catch (Exception ex)
                {
                    lastException = ex is WinAurexException ? ex : new ProviderException($"Unexpected error: {ex.Message}", ex);
                }

                if (attempt < maxAttempts)
                {
                    context.Journal.Events.Add(new OperationProgressEntry
                    {
                        OperationId = operation.Id,
                        Message = $"Attempt {attempt} failed. Retrying..."
                    });

                    if (policy.RetryDelay.HasValue)
                    {
                        await Task.Delay(policy.RetryDelay.Value, context.CancellationToken);
                    }
                }
            }

            context.ExecutionResult = ProviderResult.Failure(lastException?.Message ?? "Failed after retries");
        }
    }
}
