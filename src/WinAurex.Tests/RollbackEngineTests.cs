using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class RollbackEngineTests
    {
        [Fact]
        public async Task EntriesWithoutUndoData_OrNonRollbackProviders_AreSkipped()
        {
            var operation = CreateRegistryOperation();
            var provider = new StubProvider("Registry", supportsRollback: false);
            var registry = new StubRegistry(provider);
            var engine = new RollbackEngine(registry);
            var journal = CreateJournal(
                (operation.Id, string.Empty),
                (operation.Id, "captured-state"));

            var result = await engine.RollbackAsync(CreatePlan(operation), journal, CreateContext());

            Assert.True(result);
            Assert.Equal(0, provider.RevertCalls);
        }

        [Fact]
        public async Task RollbackableEntry_IsRevertedWithTheCapturedUndoData()
        {
            var operation = CreateRegistryOperation();
            var provider = new StubProvider("Registry", supportsRollback: true);
            var registry = new StubRegistry(provider);
            var engine = new RollbackEngine(registry);
            var journal = CreateJournal((operation.Id, "captured-state"));

            var result = await engine.RollbackAsync(CreatePlan(operation), journal, CreateContext());

            Assert.True(result);
            Assert.Equal(1, provider.RevertCalls);
            Assert.Equal("captured-state", provider.LastUndoData);
        }

        [Fact]
        public async Task FailingRevert_ReportsFailure()
        {
            var operation = CreateRegistryOperation();
            var provider = new StubProvider("Registry", supportsRollback: true, succeed: false);
            var engine = new RollbackEngine(new StubRegistry(provider));
            var journal = CreateJournal((operation.Id, "captured-state"));

            var result = await engine.RollbackAsync(CreatePlan(operation), journal, CreateContext());

            Assert.False(result);
            Assert.Equal(1, provider.RevertCalls);
        }

        [Fact]
        public async Task UndoDataWithoutProvider_ReportsFailure()
        {
            var operation = CreateRegistryOperation();
            var engine = new RollbackEngine(new StubRegistry());
            var journal = CreateJournal((operation.Id, "captured-state"));

            var result = await engine.RollbackAsync(CreatePlan(operation), journal, CreateContext());

            Assert.False(result);
        }

        [Fact]
        public async Task EmptyJournal_ReportsSuccess()
        {
            var operation = CreateRegistryOperation();
            var engine = new RollbackEngine(new StubRegistry());

            var result = await engine.RollbackAsync(CreatePlan(operation), CreateJournal(), CreateContext());

            Assert.True(result);
        }

        [Fact]
        public async Task NullArguments_AreRejected()
        {
            var engine = new RollbackEngine(new StubRegistry());

            await Assert.ThrowsAsync<ArgumentNullException>(() => engine.RollbackAsync(null!, CreateJournal(), CreateContext()));
            await Assert.ThrowsAsync<ArgumentNullException>(() => engine.RollbackAsync(CreatePlan(CreateRegistryOperation()), null!, CreateContext()));
        }

        private static RegistryOperation CreateRegistryOperation() =>
            new(new OperationId("Registry.test-revert"))
            {
                Target = new RegistryTarget(RegistryHive.CurrentUser, @"Software\WinAurexTest", "Value"),
                Intent = new SetRegistryValueIntent(1, RegistryValueKind.DWord)
            };

        private static ExecutionPlan CreatePlan(params ExecutionOperation[] operations) =>
            new() { Operations = ImmutableList.Create(operations) };

        private static ExecutionJournal CreateJournal(params (OperationId Id, string UndoData)[] entries)
        {
            var journal = new ExecutionJournal { ExecutionId = Guid.NewGuid() };
            foreach (var entry in entries)
            {
                journal.Events.Add(new OperationCompletedEntry
                {
                    OperationId = entry.Id,
                    UndoData = entry.UndoData
                });
            }

            return journal;
        }

        private static PlanContext CreateContext() =>
            new(Guid.NewGuid(), false, default, "tester", false, "en-US", "C:\\", null!);

        public sealed class StubRegistry : ICapabilityRegistry
        {
            private readonly Dictionary<string, ICapabilityProvider> _providers = new(StringComparer.OrdinalIgnoreCase);

            public StubRegistry(params ICapabilityProvider[] providers)
            {
                foreach (var provider in providers)
                {
                    _providers[provider.Metadata.Id] = provider;
                }
            }

            public void Register<TProvider>() where TProvider : class, ICapabilityProvider
            {
            }

            public ICapabilityProvider GetProvider(string capabilityId) => _providers[capabilityId];

            public bool TryGetProvider(string capabilityId, out ICapabilityProvider? provider) =>
                _providers.TryGetValue(capabilityId, out provider);

            public IEnumerable<ProviderMetadata> GetAllProviders() => _providers.Values.Select(p => p.Metadata);
        }

        public sealed class StubProvider : ICapabilityProvider
        {
            private readonly bool _succeed;

            public StubProvider(string id, bool supportsRollback, bool succeed = true)
            {
                Metadata = new ProviderMetadata(id, id, "1.0", supportsRollback, true, false, RiskLevel.Safe);
                _succeed = succeed;
            }

            public ProviderMetadata Metadata { get; }

            public int RevertCalls { get; private set; }

            public string? LastUndoData { get; private set; }

            public Task<ProviderResult> RevertAsync(RegistryOperation operation, string undoData, PlanContext context)
            {
                RevertCalls++;
                LastUndoData = undoData;
                return Task.FromResult(_succeed
                    ? ProviderResult.Success()
                    : ProviderResult.Failure("revert failed"));
            }
        }
    }
}
