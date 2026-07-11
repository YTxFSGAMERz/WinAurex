using System;

namespace WinAurex.Contracts.Execution
{
    public sealed record ProviderMetadata(
        string Id,
        string Name,
        string Version,
        bool SupportsRollback,
        bool SupportsDryRun,
        bool RequiresElevation,
        Models.RiskLevel MaxRiskLevel
    );
}
