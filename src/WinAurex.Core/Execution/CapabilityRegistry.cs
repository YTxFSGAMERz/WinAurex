using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Extensions.DependencyInjection;
using WinAurex.Contracts.Execution;

namespace WinAurex.Core.Execution
{
    public class CapabilityRegistry : ICapabilityRegistry
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ConcurrentDictionary<string, Type> _providerTypes = new();

        public CapabilityRegistry(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public void Register<TProvider>() where TProvider : class, ICapabilityProvider
        {
            var tempProvider = ActivatorUtilities.CreateInstance<TProvider>(_serviceProvider);
            var metadata = tempProvider.Metadata;
            _providerTypes[metadata.Id] = typeof(TProvider);
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
            if (_providerTypes.TryGetValue(capabilityId, out var type))
            {
                provider = (ICapabilityProvider)ActivatorUtilities.GetServiceOrCreateInstance(_serviceProvider, type);
                return true;
            }
            provider = null;
            return false;
        }

        public IEnumerable<ProviderMetadata> GetAllProviders()
        {
            return _providerTypes.Values.Select(type => 
            {
                var provider = (ICapabilityProvider)ActivatorUtilities.GetServiceOrCreateInstance(_serviceProvider, type);
                return provider.Metadata;
            }).ToList();
        }
    }
}
