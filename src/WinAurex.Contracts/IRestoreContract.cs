using System.Threading;
using System.Threading.Tasks;
using WinAurex.Models;

namespace WinAurex.Contracts
{
    public interface IRestoreContract
    {
        Task<RestoreSnapshot> CreateSnapshotAsync(SystemAction action, CancellationToken cancellationToken = default);
        Task<bool> CanRollbackAsync(SystemAction action, CancellationToken cancellationToken = default);
        Task RollbackAsync(string actionId, CancellationToken cancellationToken = default);
        Task RollbackProfileAsync(string profileId, CancellationToken cancellationToken = default);
    }
}
