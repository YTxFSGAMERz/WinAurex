using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Microsoft.Extensions.DependencyInjection;
using WinAurex.Contracts.Execution;

namespace WinAurex.Core.Execution
{
    public class CapabilityRegistry : ICapabilityRegistry
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ConcurrentDictionary<string, Lazy<ICapabilityProvider>> _providers = new();

        public CapabilityRegistry(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public void Register<TProvider>() where TProvider : class, ICapabilityProvider
        {
            // The probe instance only exists to read the metadata id. Execution goes
            // through the lazily resolved instance so providers keep their state.
            var tempProvider = ActivatorUtilities.CreateInstance<TProvider>(_serviceProvider);
            var metadata = tempProvider.Metadata;

            _providers[metadata.Id] = new Lazy<ICapabilityProvider>(
                () => (ICapabilityProvider)ActivatorUtilities.GetServiceOrCreateInstance(_serviceProvider, typeof(TProvider)),
                LazyThreadSafetyMode.ExecutionAndPublication);
        }

        public ICapabilityProvider GetProvider(string capabilityId)
        {
            if (TryGetProvider(capabilityId, out var provider))
            {
                return provider!;
            }
            throw new KeyNotFoundException($"Capability provider with ID '{capabilityId}' was not found.");
        }

        public bool TryGetProvider(string capabilityId, out ICapabilityProvider? provider)
        {
            if (_providers.TryGetValue(capabilityId, out var lazyProvider))
            {
                provider = lazyProvider.Value;
                return true;
            }
            provider = null;
            return false;
        }

        public IEnumerable<ProviderMetadata> GetAllProviders()
        {
            return _providers.Values.Select(lazyProvider => lazyProvider.Value.Metadata).ToList();
        }
    }
}
