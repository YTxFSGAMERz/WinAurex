using System.Threading;
using System.Threading.Tasks;
using WinAurex.Models;

namespace WinAurex.Contracts
{
    public interface IActionHandler
    {
        string HandlerType { get; }
        Task<ActionExecutionResult> ExecuteAsync(SystemAction action, CancellationToken cancellationToken = default);
        Task<ActionExecutionResult> RollbackAsync(SystemAction action, CancellationToken cancellationToken = default);
    }
}
