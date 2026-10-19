using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public class JournalPersistenceTests
    {
        [Fact]
        public async Task ExecutePlanAsync_SavesTheFinishedJournal_ExactlyOnce()
        {
            var manager = new RecordingJournalManager();
            var engine = new ExecutionEngine(new SingleProviderRegistry(new TestCapabilityProvider()), manager);

            var journal = await engine.ExecutePlanAsync(BuildPlan("TestExecutor.Step"), CreateContext());

            var saved = Assert.Single(manager.SavedJournals);
            Assert.Same(journal, saved);
            Assert.Contains(saved.Events, entry => entry is OperationCompletedEntry);

            var completed = Assert.IsType<ExecutionCompletedEntry>(saved.Events[^1]);
            Assert.True(completed.IsSuccess);
        }

        [Fact]
        public async Task ExecutePlanAsync_WhenTheJournalCannotBeWritten_StillReturnsTheCompletedRun()
        {
            var engine = new ExecutionEngine(
                new SingleProviderRegistry(new TestCapabilityProvider()),
                new ThrowingJournalManager());

            var journal = await engine.ExecutePlanAsync(BuildPlan("TestExecutor.Step"), CreateContext());

            var completed = Assert.Single(journal.Events.OfType<ExecutionCompletedEntry>());
            Assert.True(completed.IsSuccess);
        }

        [Fact]
        public async Task ExecutePlanAsync_RejectsMissingArguments()
        {
            var engine = new ExecutionEngine(new SingleProviderRegistry(new TestCapabilityProvider()), new RecordingJournalManager());

            await Assert.ThrowsAsync<ArgumentNullException>(() => engine.ExecutePlanAsync(null!, CreateContext()));
            await Assert.ThrowsAsync<ArgumentNullException>(() => engine.ExecutePlanAsync(BuildPlan("TestExecutor.Step"), null!));
        }

        [Fact]
        public void Constructor_RejectsMissingDependencies()
        {
            Assert.Throws<ArgumentNullException>(() => new ExecutionEngine(null!, new RecordingJournalManager()));
            Assert.Throws<ArgumentNullException>(() => new ExecutionEngine(new SingleProviderRegistry(new TestCapabilityProvider()), null!));
        }

        private static ExecutionPlan BuildPlan(string operationId)
        {
            return new ExecutionPlan
            {
                Name = "Journal persistence plan",
                Operations = ImmutableList.Create<ExecutionOperation>(
                    new TestOperation(new OperationId(operationId)))
            };
        }

        private static PlanContext CreateContext()
        {
            return new PlanContext(
                Guid.NewGuid(),
                false,
                CancellationToken.None,
                "tester",
                true,
                "en-US",
                Path.GetTempPath(),
                null!);
        }
    }

    public sealed record TestTarget(string Name) : OperationTarget;

    public sealed record TestIntent(string Value) : OperationIntent;

    public sealed class TestOperation : ExecutionOperation<TestTarget, TestIntent>
    {
        public TestOperation(OperationId id) : base(id) { }
    }

    public sealed class TestCapabilityProvider : ICapabilityProvider<TestOperation>
    {
        public ProviderMetadata Metadata { get; } = new ProviderMetadata(
            "TestExecutor",
            "Test Executor",
            "1.0.0",
            SupportsRollback: true,
            SupportsDryRun: true,
            RequiresElevation: false,
            MaxRiskLevel: RiskLevel.Safe);

        public Task<ProviderResult> AnalyzeAsync(TestOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success());

        public Task<ProviderResult> BackupAsync(TestOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success("undo"));

        public Task<ProviderResult> ExecuteAsync(TestOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success());

        public Task<ProviderResult> VerifyAsync(TestOperation operation, PlanContext context)
            => Task.FromResult(ProviderResult.Success());

        public Task<ProviderResult> RevertAsync(TestOperation operation, string undoData, PlanContext context)
            => Task.FromResult(ProviderResult.Success());
    }

    public sealed class SingleProviderRegistry : ICapabilityRegistry
    {
        private readonly ICapabilityProvider _provider;

        public SingleProviderRegistry(ICapabilityProvider provider)
        {
            _provider = provider;
        }

        public void Register<TProvider>() where TProvider : class, ICapabilityProvider
        {
        }

        public ICapabilityProvider GetProvider(string capabilityId) => _provider;

        public bool TryGetProvider(string capabilityId, out ICapabilityProvider? provider)
        {
            provider = _provider;
            return true;
        }

        public IEnumerable<ProviderMetadata> GetAllProviders() => new[] { _provider.Metadata };
    }

    public sealed class RecordingJournalManager : IJournalManager
    {
        public List<ExecutionJournal> SavedJournals { get; } = new List<ExecutionJournal>();

        public Task SaveJournalAsync(ExecutionJournal journal)
        {
            SavedJournals.Add(journal);
            return Task.CompletedTask;
        }

        public Task<ExecutionJournal?> LoadJournalAsync(Guid executionId)
            => Task.FromResult<ExecutionJournal?>(null);

        public string GetJournalDirectory() => string.Empty;
    }

    public sealed class ThrowingJournalManager : IJournalManager
    {
        public Task SaveJournalAsync(ExecutionJournal journal)
            => Task.FromException(new IOException("The simulated journal volume is unavailable."));

        public Task<ExecutionJournal?> LoadJournalAsync(Guid executionId)
            => Task.FromResult<ExecutionJournal?>(null);

        public string GetJournalDirectory() => string.Empty;
    }
}
