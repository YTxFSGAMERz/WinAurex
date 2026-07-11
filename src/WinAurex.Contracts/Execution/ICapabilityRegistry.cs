using System.Collections.Generic;

namespace WinAurex.Contracts.Execution
{
    public interface ICapabilityRegistry
    {
        void Register<TProvider>() where TProvider : class, ICapabilityProvider;
        ICapabilityProvider GetProvider(string capabilityId);
        bool TryGetProvider(string capabilityId, out ICapabilityProvider? provider);
        IEnumerable<ProviderMetadata> GetAllProviders();
    }
}
