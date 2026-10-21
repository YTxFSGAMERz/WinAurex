using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class ExecutionEngineContinueOnFailureTests
    {
        [Fact]
        public async Task ContinueOnFailure_RunsRemainingOperations_ButMarksPlanFailed()
        {
            var provider = new ScriptedRegistryProvider(failAction: "fail");
            var engine = new ExecutionEngine(new StubRegistry(provider));
            var plan = CreatePlan(
                new ExecutionPolicy { ContinueOnFailure = true },
                ExecutionPolicy.Default);

            var journal = await engine.ExecutePlanAsync(plan, CreateContext());

            Assert.Equal(2, provider.ExecutionCalls);

            var failedEntry = Assert.Single(journal.Events.OfType<OperationFailedEntry>());
            Assert.Equal("Registry.fail", failedEntry.OperationId.Value);

            var completedOperation = Assert.Single(journal.Events.OfType<OperationCompletedEntry>());
            Assert.Equal("Registry.ok", completedOperation.OperationId.Value);

            var completedPlan = Assert.IsType<ExecutionCompletedEntry>(journal.Events.Last());
            Assert.False(completedPlan.IsSuccess);
        }

        [Fact]
        public async Task SuccessfulPlan_IsStillMarkedSuccessful()
        {
            var provider = new ScriptedRegistryProvider(failAction: null);
            var engine = new ExecutionEngine(new StubRegistry(provider));
            var plan = CreatePlan(ExecutionPolicy.Default, ExecutionPolicy.Default);

            var journal = await engine.ExecutePlanAsync(plan, CreateContext());

            Assert.Equal(2, provider.ExecutionCalls);
            Assert.Empty(journal.Events.OfType<OperationFailedEntry>());
            Assert.Equal(2, journal.Events.OfType<OperationCompletedEntry>().Count());

            var completedPlan = Assert.IsType<ExecutionCompletedEntry>(journal.Events.Last());
            Assert.True(completedPlan.IsSuccess);
        }

        private static ExecutionPlan CreatePlan(params ExecutionPolicy[] policies)
        {
            var failOperation = CreateOperation("fail", policies[0]);
            var okOperation = CreateOperation("ok", policies[1]);

            return new ExecutionPlan
            {
                Name = "continue-on-failure-test",
                Operations = ImmutableList.Create<ExecutionOperation>(failOperation, okOperation)
            };
        }

        private static RegistryOperation CreateOperation(string action, ExecutionPolicy policy)
        {
            return new RegistryOperation(new OperationId($"Registry.{action}"))
            {
                Description = $"Test operation {action}",
                PolicyOverride = policy,
                Target = new RegistryTarget(
                    RegistryHive.CurrentUser,
                    @"Software\WinAurexTest",
                    "ContinueOnFailure"),
                Intent = new DeleteRegistryValueIntent()
            };
        }

        private static PlanContext CreateContext()
        {
            return new PlanContext(
                Guid.NewGuid(),
                isDryRun: false,
                CancellationToken.None,
                "tester",
                isElevated: false,
                "en-US",
                AppContext.BaseDirectory,
                logger: null!);
        }

        private sealed class StubRegistry : ICapabilityRegistry
        {
            private readonly ICapabilityProvider _provider;

            public StubRegistry(ICapabilityProvider provider) => _provider = provider;

            public void Register<TProvider>() where TProvider : class, ICapabilityProvider
            {
            }

            public ICapabilityProvider GetProvider(string capabilityId) => _provider;

            public bool TryGetProvider(string capabilityId, out ICapabilityProvider? provider)
            {
                provider = _provider;
                return true;
            }

            public IEnumerable<ProviderMetadata> GetAllProviders()
            {
                yield return _provider.Metadata;
            }
        }
    }

    // Public because ProviderExecutionMiddleware dispatches through dynamic.
    public sealed class ScriptedRegistryProvider : ICapabilityProvider<RegistryOperation>
    {
        private readonly string? _failAction;

        public ScriptedRegistryProvider(string? failAction) => _failAction = failAction;

        public int ExecutionCalls { get; private set; }

        public ProviderMetadata Metadata { get; } = new ProviderMetadata(
            Id: "Registry",
            Name: "Registry",
            Version: "1.0",
            SupportsRollback: true,
            SupportsDryRun: true,
            RequiresElevation: false,
            MaxRiskLevel: RiskLevel.Advanced);

        public Task<ProviderResult> AnalyzeAsync(RegistryOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success());

        public Task<ProviderResult> BackupAsync(RegistryOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success("undo"));

        public Task<ProviderResult> ExecuteAsync(RegistryOperation operation, PlanContext context)
        {
            ExecutionCalls++;

            if (operation.Id.Value == "Registry.fail")
            {
                if (_failAction == null)
                {
                    return Task.FromResult(ProviderResult.Success());
                }

                return Task.FromResult(ProviderResult.Failure("simulated failure"));
            }

            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> VerifyAsync(RegistryOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success());

        public Task<ProviderResult> RevertAsync(RegistryOperation operation, string undoData, PlanContext context)
            => Task.FromResult(ProviderResult.Success());
    }
}
