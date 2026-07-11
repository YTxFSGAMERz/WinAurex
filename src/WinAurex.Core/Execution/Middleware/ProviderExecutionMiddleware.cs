using System;
using System.Diagnostics;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution.Middleware
{
    public class ProviderExecutionMiddleware : IExecutionMiddleware
    {
        public async Task InvokeAsync(ExecutionOperation operation, OperationContext context, OperationDelegate next)
        {
            dynamic dynamicProvider = context.Provider;
            var policy = operation.PolicyOverride ?? new ExecutionPolicy(); // Should probably be passed from engine

            // 1. Backup
            context.Journal.Events.Add(new OperationProgressEntry { OperationId = operation.Id, Message = "Backing up state..." });
            var backupTimer = Stopwatch.StartNew();
            ProviderResult backupResult = await dynamicProvider.BackupAsync((dynamic)operation, context);
            backupTimer.Stop();
            
            context.BackupResult = backupResult;

            if (!backupResult.IsSuccess)
            {
                context.ExecutionResult = ProviderResult.Failure($"Backup failed: {backupResult.ErrorMessage}");
                return;
            }

            // 2. Execution
            context.Journal.Events.Add(new OperationProgressEntry { OperationId = operation.Id, Message = "Executing..." });
            var execTimer = Stopwatch.StartNew();
            ProviderResult execResult = await dynamicProvider.ExecuteAsync((dynamic)operation, context);
            execTimer.Stop();

            context.ExecutionResult = execResult;

            if (!execResult.IsSuccess)
            {
                return; // Stop pipeline on failure
            }

            // 3. Verification
            if (policy.VerificationMode != VerificationMode.None)
            {
                context.Journal.Events.Add(new OperationProgressEntry { OperationId = operation.Id, Message = "Verifying..." });
                var verifyTimer = Stopwatch.StartNew();
                ProviderResult verifyResult = await dynamicProvider.VerifyAsync((dynamic)operation, context);
                verifyTimer.Stop();

                context.VerificationResult = verifyResult;

                if (!verifyResult.IsSuccess)
                {
                    context.ExecutionResult = ProviderResult.Failure($"Verification failed: {verifyResult.ErrorMessage}");
                    return;
                }
            }

            await next(operation, context);
        }
    }
}
