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

            int maxAttempts = GetMaxAttempts(policy);
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

                    var delay = ComputeRetryDelay(policy, attempt);
                    if (delay > TimeSpan.Zero)
                    {
                        await Task.Delay(delay, context.CancellationToken);
                    }
                }
            }

            context.ExecutionResult = ProviderResult.Failure(lastException?.Message ?? "Failed after retries");
        }

        /// <summary>
        /// Returns how many times the operation may run for the given policy.
        /// <see cref="RetryPolicy.None"/> runs once regardless of <see cref="ExecutionPolicy.MaxRetries"/>;
        /// a negative retry count is treated as zero retries.
        /// </summary>
        internal static int GetMaxAttempts(ExecutionPolicy policy)
        {
            if (policy.RetryPolicy == RetryPolicy.None)
            {
                return 1;
            }

            return Math.Max(1, policy.MaxRetries + 1);
        }

        /// <summary>
        /// Returns the delay to wait after <paramref name="failedAttempt"/> (1-based) has failed.
        /// <see cref="RetryPolicy.Fixed"/> uses a constant delay; <see cref="RetryPolicy.ExponentialBackoff"/>
        /// doubles the delay after every failed attempt, capped at <see cref="TimeSpan.MaxValue"/>.
        /// </summary>
        internal static TimeSpan ComputeRetryDelay(ExecutionPolicy policy, int failedAttempt)
        {
            if (policy.RetryPolicy == RetryPolicy.None || !policy.RetryDelay.HasValue || failedAttempt < 1)
            {
                return TimeSpan.Zero;
            }

            var baseDelay = policy.RetryDelay.Value;
            if (policy.RetryPolicy == RetryPolicy.Fixed)
            {
                return baseDelay;
            }

            // ExponentialBackoff: base * 2^(failedAttempt - 1)
            var ticks = (double)baseDelay.Ticks * Math.Pow(2, failedAttempt - 1);
            if (ticks >= TimeSpan.MaxValue.Ticks)
            {
                return TimeSpan.MaxValue;
            }

            return TimeSpan.FromTicks((long)ticks);
        }
    }
}
