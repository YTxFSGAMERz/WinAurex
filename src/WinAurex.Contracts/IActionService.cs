using System.Threading;
using System.Threading.Tasks;
using WinAurex.Models;

namespace WinAurex.Contracts
{
    public interface IActionService
    {
        Task<ActionExecutionResult> ApplyAsync(SystemAction action, CancellationToken cancellationToken = default);
        Task<ActionExecutionResult> PreviewAsync(SystemAction action, CancellationToken cancellationToken = default);
        Task<ActionExecutionResult> RollbackAsync(SystemAction action, CancellationToken cancellationToken = default);
    }
}
