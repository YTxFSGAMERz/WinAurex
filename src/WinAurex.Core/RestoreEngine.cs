using System;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts;
using WinAurex.Models;

namespace WinAurex.Core
{
    public class RestoreEngine : IRestoreContract
    {
        public Task<RestoreSnapshot> CreateSnapshotAsync(SystemAction action, CancellationToken cancellationToken = default)
        {
            // TODO: Create restore points, backup registry/files before applying a change.
            throw new NotImplementedException();
        }

        public Task<bool> CanRollbackAsync(SystemAction action, CancellationToken cancellationToken = default)
        {
            // TODO: Determine if a valid snapshot exists for this action.
            throw new NotImplementedException();
        }

        public Task RollbackAsync(string actionId, CancellationToken cancellationToken = default)
        {
            // TODO: Perform the rollback logic based on the stored snapshot.
            throw new NotImplementedException();
        }

        public Task RollbackProfileAsync(string profileId, CancellationToken cancellationToken = default)
        {
            // TODO: Roll back an entire group of actions associated with a profile.
            throw new NotImplementedException();
        }
    }
}
