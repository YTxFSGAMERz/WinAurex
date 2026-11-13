using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution.Middleware;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class JournalMiddlewareDryRunTests
    {
        [Fact]
        public async Task DryRunSuccess_RecordsValidationInsteadOfCompletion()
        {
            var journal = await InvokeAsync(isDryRun: true, result: ProviderResult.Success(), undoData: null);

            Assert.Empty(journal.Events.OfType<OperationCompletedEntry>());
            Assert.Empty(journal.Events.OfType<OperationFailedEntry>());
            Assert.Single(journal.Events.OfType<OperationStartedEntry>());

            var progress = journal.Events.OfType<OperationProgressEntry>().Last();
            Assert.Contains("Dry run validated", progress.Message);
        }

        [Fact]
        public async Task NormalRunStillRecordsCompletionWithUndoData()
        {
            var journal = await InvokeAsync(isDryRun: false, result: ProviderResult.Success(), undoData: "registry-undo");

            var completed = Assert.Single(journal.Events.OfType<OperationCompletedEntry>());
            Assert.Equal("Registry.dry-run-test", completed.OperationId.Value);
            Assert.Equal("registry-undo", completed.UndoData);
            Assert.DoesNotContain(journal.Events.OfType<OperationProgressEntry>(),
                entry => entry.Message.Contains("Dry run validated"));
        }

        [Fact]
        public async Task DryRunFailure_StillRecordsFailure()
        {
            var journal = await InvokeAsync(
                isDryRun: true,
                result: ProviderResult.Failure("validation failed"),
                undoData: null);

            var failed = Assert.Single(journal.Events.OfType<OperationFailedEntry>());
            Assert.Equal("validation failed", failed.ErrorMessage);
            Assert.Empty(journal.Events.OfType<OperationCompletedEntry>());
        }

        private static async Task<ExecutionJournal> InvokeAsync(
            bool isDryRun,
            ProviderResult result,
            string? undoData)
        {
            var journal = new ExecutionJournal { ExecutionId = Guid.NewGuid() };
            var context = new OperationContext(new PlanContext(
                Guid.NewGuid(),
                isDryRun,
                CancellationToken.None,
                "tester",
                isElevated: false,
                "en-US",
                AppContext.BaseDirectory,
                logger: null!))
            {
                Journal = journal
            };

            var operation = new RegistryOperation(new OperationId("Registry.dry-run-test"))
            {
                Description = "Disable telemetry",
                Target = new RegistryTarget(
                    RegistryHive.CurrentUser,
                    @"Software\WinAurexTest",
                    "DryRun"),
                Intent = new DeleteRegistryValueIntent()
            };

            var middleware = new JournalMiddleware();
            await middleware.InvokeAsync(operation, context, (_, ctx) =>
            {
                if (undoData != null)
                {
                    ctx.BackupResult = ProviderResult.Success(undoData);
                }

                ctx.ExecutionResult = result;
                return Task.CompletedTask;
            });

            return journal;
        }
    }
}
