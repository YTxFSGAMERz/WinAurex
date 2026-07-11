using System.Threading.Tasks;
using WinAurex.Models;
using WinAurex.Models.Execution;

namespace WinAurex.Contracts.Execution
{
    public interface ISystemStateAnalyzer
    {
        /// <summary>
        /// Analyzes the system state to determine if an action is currently applied.
        /// </summary>
        /// <param name="action">The action to analyze.</param>
        /// <returns>True if the action is applied, false otherwise.</returns>
        Task<bool> IsActionAppliedAsync(SystemAction action);
    }
}
