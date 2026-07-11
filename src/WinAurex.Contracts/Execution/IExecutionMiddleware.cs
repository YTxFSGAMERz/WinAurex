using System.Threading.Tasks;
using WinAurex.Models.Execution;

namespace WinAurex.Contracts.Execution
{
    public delegate Task OperationDelegate(ExecutionOperation operation, OperationContext context);

    public interface IExecutionMiddleware
    {
        Task InvokeAsync(ExecutionOperation operation, OperationContext context, OperationDelegate next);
    }
}
