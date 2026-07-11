using System.Threading.Tasks;
using WinAurex.Models;

namespace WinAurex.Contracts
{
    public interface IStateService
    {
        /// <summary>
        /// Checks if a SystemAction is currently applied on the system.
        /// </summary>
        Task<bool> IsActionAppliedAsync(SystemAction action);

        /// <summary>
        /// Saves the fact that an action was applied or reverted to the local cache.
        /// </summary>
        Task SetActionStateAsync(SystemAction action, bool isApplied);
    }
}
