using System;
using System.Linq;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public class CapabilityRegistryTests
    {
        [Fact]
        public void LookupsReturnTheSameProviderInstance()
        {
            CountingProvider.Reset();
            var registry = new CapabilityRegistry(new EmptyServiceProvider());

            registry.Register<CountingProvider>();
            Assert.Equal(1, CountingProvider.ConstructionCount);

            Assert.True(registry.TryGetProvider("Counting", out var first));
            Assert.True(registry.TryGetProvider("Counting", out var second));

            Assert.Same(first, second);
            Assert.Equal(2, CountingProvider.ConstructionCount);

            var metadata = Assert.Single(registry.GetAllProviders());
            Assert.Equal("Counting", metadata.Id);
            Assert.Equal(2, CountingProvider.ConstructionCount);
        }

        [Fact]
        public void ConcurrentLookupsCreateOnlyOneExecutionInstance()
        {
            CountingProvider.Reset();
            var registry = new CapabilityRegistry(new EmptyServiceProvider());
            registry.Register<CountingProvider>();

            var results = new ICapabilityProvider[32];
            Parallel.For(0, results.Length, index =>
            {
                Assert.True(registry.TryGetProvider("Counting", out var provider));
                results[index] = provider!;
            });

            Assert.All(results, provider => Assert.Same(results[0], provider));
            Assert.Equal(2, CountingProvider.ConstructionCount);
        }

        [Fact]
        public void UnknownProviderReturnsFalse()
        {
            var registry = new CapabilityRegistry(new EmptyServiceProvider());

            Assert.False(registry.TryGetProvider("Missing", out var provider));
            Assert.Null(provider);
            Assert.Throws<System.Collections.Generic.KeyNotFoundException>(() => registry.GetProvider("Missing"));
        }

        private sealed class EmptyServiceProvider : IServiceProvider
        {
            public object? GetService(Type serviceType) => null;
        }
    }

    public sealed class CountingProvider : ICapabilityProvider
    {
        private static int _constructionCount;

        public CountingProvider()
        {
            System.Threading.Interlocked.Increment(ref _constructionCount);
        }

        public static int ConstructionCount => System.Threading.Volatile.Read(ref _constructionCount);

        public static void Reset() => System.Threading.Volatile.Write(ref _constructionCount, 0);

        public ProviderMetadata Metadata { get; } = new ProviderMetadata(
            Id: "Counting",
            Name: "Counting provider",
            Version: "1.0",
            SupportsRollback: false,
            SupportsDryRun: false,
            RequiresElevation: false,
            MaxRiskLevel: WinAurex.Models.RiskLevel.Safe);
    }
}
