using System.Threading.Tasks;
using WinAurex.Models.Execution;

namespace WinAurex.Contracts.Execution
{
    public interface ICapabilityProvider
    {
        ProviderMetadata Metadata { get; }
    }

    public interface ICapabilityProvider<in T> : ICapabilityProvider where T : ExecutionOperation
    {
        Task<ProviderResult> AnalyzeAsync(T operation, PlanContext context);
        Task<ProviderResult> BackupAsync(T operation, PlanContext context);
        Task<ProviderResult> ExecuteAsync(T operation, PlanContext context);
        Task<ProviderResult> VerifyAsync(T operation, PlanContext context);
        Task<ProviderResult> RevertAsync(T operation, string undoData, PlanContext context);
    }
}
