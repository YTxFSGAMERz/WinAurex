using System;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution.Middleware;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class ValidationMiddlewareTests
    {
        [Fact]
        public async Task DryRun_ValidatesThroughAnalyzeAndStopsThePipeline()
        {
            var provider = new StubProvider();
            var context = CreateContext(provider, isDryRun: true);
            bool nextCalled = false;

            await new ValidationMiddleware().InvokeAsync(CreateOperation(), context, (op, ctx) =>
            {
                nextCalled = true;
                return Task.CompletedTask;
            });

            Assert.Equal(1, provider.AnalyzeCalls);
            Assert.Equal(0, provider.ExecutionCalls);
            Assert.False(nextCalled);
            Assert.True(context.ExecutionResult!.IsSuccess);
        }

        [Fact]
        public async Task DryRun_WithFailingAnalyze_ReportsTheProviderMessage()
        {
            var provider = new StubProvider { AnalyzeFailure = "Script file not found: tweak.ps1" };
            var context = CreateContext(provider, isDryRun: true);
            bool nextCalled = false;

            await new ValidationMiddleware().InvokeAsync(CreateOperation(), context, (op, ctx) =>
            {
                nextCalled = true;
                return Task.CompletedTask;
            });

            Assert.Equal(1, provider.AnalyzeCalls);
            Assert.Equal(0, provider.ExecutionCalls);
            Assert.False(nextCalled);
            Assert.False(context.ExecutionResult!.IsSuccess);
            Assert.Contains("Script file not found: tweak.ps1", context.ExecutionResult.ErrorMessage);
        }

        [Fact]
        public async Task NonDryRun_ForwardsToNextWithoutAnalyzing()
        {
            var provider = new StubProvider();
            var context = CreateContext(provider, isDryRun: false);
            bool nextCalled = false;

            await new ValidationMiddleware().InvokeAsync(CreateOperation(), context, (op, ctx) =>
            {
                nextCalled = true;
                return Task.CompletedTask;
            });

            Assert.Equal(0, provider.AnalyzeCalls);
            Assert.True(nextCalled);
            Assert.Null(context.ExecutionResult);
        }

        [Fact]
        public async Task MissingProvider_FailsValidation()
        {
            var context = CreateContext(provider: null!, isDryRun: false);

            await new ValidationMiddleware().InvokeAsync(CreateOperation(), context, (op, ctx) => Task.CompletedTask);

            Assert.False(context.ExecutionResult!.IsSuccess);
            Assert.Contains("Provider is missing.", context.ExecutionResult.ErrorMessage);
        }

        private static RegistryOperation CreateOperation() =>
            new(new OperationId("Registry.validation-test"))
            {
                Target = new RegistryTarget(RegistryHive.CurrentUser, @"Software\WinAurexTest", "Value"),
                Intent = new SetRegistryValueIntent(1, RegistryValueKind.DWord),
                Description = "validation test operation"
            };

        private static OperationContext CreateContext(ICapabilityProvider provider, bool isDryRun) =>
            new(new PlanContext(Guid.NewGuid(), isDryRun, default, "tester", false, "en-US", "C:\\", null!))
            {
                Journal = new ExecutionJournal { ExecutionId = Guid.NewGuid() },
                Provider = provider
            };

        public sealed class StubProvider : ICapabilityProvider
        {
            public StubProvider()
            {
                Metadata = new ProviderMetadata("Registry", "Registry Test Provider", "1.0", true, true, false, RiskLevel.Safe);
            }

            public ProviderMetadata Metadata { get; }

            public int AnalyzeCalls { get; private set; }
            public int ExecutionCalls { get; private set; }
            public string? AnalyzeFailure { get; set; }

            public Task<ProviderResult> AnalyzeAsync(RegistryOperation operation, PlanContext context)
            {
                AnalyzeCalls++;
                return Task.FromResult(AnalyzeFailure == null
                    ? ProviderResult.Success()
                    : ProviderResult.Failure(AnalyzeFailure));
            }

            public Task<ProviderResult> BackupAsync(RegistryOperation operation, PlanContext context)
            {
                ExecutionCalls++;
                return Task.FromResult(ProviderResult.Success());
            }

            public Task<ProviderResult> ExecuteAsync(RegistryOperation operation, PlanContext context)
            {
                ExecutionCalls++;
                return Task.FromResult(ProviderResult.Success());
            }

            public Task<ProviderResult> VerifyAsync(RegistryOperation operation, PlanContext context)
            {
                ExecutionCalls++;
                return Task.FromResult(ProviderResult.Success());
            }
        }
    }
}
