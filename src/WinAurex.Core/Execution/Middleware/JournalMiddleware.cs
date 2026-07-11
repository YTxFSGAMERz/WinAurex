using System;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution.Middleware
{
    public class JournalMiddleware : IExecutionMiddleware
    {
        public async Task InvokeAsync(ExecutionOperation operation, OperationContext context, OperationDelegate next)
        {
            context.Journal.Events.Add(new OperationStartedEntry { OperationId = operation.Id });
            EmitProgress(context, operation.Id, $"Starting {operation.Description}...");

            try
            {
                await next(operation, context);

                if (context.ExecutionResult != null && context.ExecutionResult.IsSuccess)
                {
                    context.Journal.Events.Add(new OperationCompletedEntry 
                    { 
                        OperationId = operation.Id, 
                        UndoData = context.BackupResult?.UndoData ?? string.Empty 
                    });
                    EmitProgress(context, operation.Id, $"Completed {operation.Description}");
                }
                else
                {
                    var error = context.ExecutionResult?.ErrorMessage ?? context.BackupResult?.ErrorMessage ?? "Unknown failure in pipeline";
                    context.Journal.Events.Add(new OperationFailedEntry 
                    { 
                        OperationId = operation.Id, 
                        ErrorMessage = error 
                    });
                }
            }
            catch (Exception ex)
            {
                context.Journal.Events.Add(new OperationFailedEntry 
                { 
                    OperationId = operation.Id, 
                    ErrorMessage = ex.Message 
                });
                throw; // Rethrow to let the retry loop or engine handle it if necessary
            }
        }

        private void EmitProgress(OperationContext context, OperationId operationId, string message)
        {
            context.Journal.Events.Add(new OperationProgressEntry
            {
                OperationId = operationId,
                Message = message
            });
        }
    }
}
