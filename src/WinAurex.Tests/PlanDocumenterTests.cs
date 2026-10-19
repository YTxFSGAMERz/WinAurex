using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class PlanDocumenterTests
    {
        [Fact]
        public void OperationWithoutRollbackSupport_IsDocumentedAsNotRevertible()
        {
            var registry = new StubRegistry(new StubProvider("Registry", supportsRollback: false));
            var documenter = new PlanDocumenter(registry);

            var model = documenter.GenerateDocumentationModel(CreatePlan(CreateRegistryOperation("Registry.no-revert")));

            var operation = Assert.Single(model.Operations);
            Assert.False(operation.SupportsRollback);
        }

        [Fact]
        public void RollbackableOperation_IsDocumentedAsRevertible()
        {
            var registry = new StubRegistry(new StubProvider("Registry", supportsRollback: true));
            var documenter = new PlanDocumenter(registry);

            var model = documenter.GenerateDocumentationModel(CreatePlan(CreateRegistryOperation("Registry.revert")));

            var operation = Assert.Single(model.Operations);
            Assert.True(operation.SupportsRollback);
        }

        [Fact]
        public void UnknownProvider_IsNeverDocumentedAsRevertible()
        {
            var documenter = new PlanDocumenter(new StubRegistry());

            var model = documenter.GenerateDocumentationModel(CreatePlan(CreateRegistryOperation("Ghost.op")));

            var operation = Assert.Single(model.Operations);
            Assert.False(operation.SupportsRollback);
        }

        [Fact]
        public void PlanAndOperationMetadata_AreCopied()
        {
            var registry = new StubRegistry(new StubProvider("Registry", supportsRollback: true));
            var documenter = new PlanDocumenter(registry);
            var operation = CreateRegistryOperation("Registry.metadata", description: "sets a value");

            var plan = new ExecutionPlan
            {
                Name = "Test Plan",
                Description = "plan description",
                Author = "tester",
                Version = "2.1.0",
                RiskLevel = RiskLevel.Advanced,
                RequiresElevation = true,
                RequiresRestart = true,
                Operations = ImmutableList.Create<ExecutionOperation>(operation)
            };

            var model = documenter.GenerateDocumentationModel(plan);

            Assert.Equal("Test Plan", model.PlanName);
            Assert.Equal("plan description", model.Description);
            Assert.Equal("tester", model.Author);
            Assert.Equal("2.1.0", model.Version);
            Assert.Equal(RiskLevel.Advanced, model.RiskLevel);
            Assert.True(model.RequiresElevation);
            Assert.True(model.RequiresRestart);

            var documented = Assert.Single(model.Operations);
            Assert.Equal("Registry.metadata", documented.OperationId);
            Assert.Equal("Registry", documented.ProviderName);
            Assert.Equal("sets a value", documented.Description);
            Assert.True(documented.SupportsRollback);
        }

        [Fact]
        public void NullArguments_AreRejected()
        {
            Assert.Throws<ArgumentNullException>(() => new PlanDocumenter(null!));
            Assert.Throws<ArgumentNullException>(() => new PlanDocumenter(new StubRegistry()).GenerateDocumentationModel(null!));
        }

        private static RegistryOperation CreateRegistryOperation(string id, string description = "") =>
            new(new OperationId(id))
            {
                Target = new RegistryTarget(RegistryHive.CurrentUser, @"Software\WinAurexTest", "Value"),
                Intent = new SetRegistryValueIntent(1, RegistryValueKind.DWord),
                Description = description
            };

        private static ExecutionPlan CreatePlan(params ExecutionOperation[] operations) =>
            new() { Operations = ImmutableList.Create(operations) };

        private sealed class StubRegistry : ICapabilityRegistry
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

        private sealed class StubProvider : ICapabilityProvider
        {
            public StubProvider(string id, bool supportsRollback)
            {
                Metadata = new ProviderMetadata(id, id, "1.0", supportsRollback, true, false, RiskLevel.Safe);
            }

            public ProviderMetadata Metadata { get; }
        }
    }
}
