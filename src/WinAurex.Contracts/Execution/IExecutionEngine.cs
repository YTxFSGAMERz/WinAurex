using System.Threading.Tasks;
using WinAurex.Models.Execution;

namespace WinAurex.Contracts.Execution
{
    public interface IExecutionEngine
    {
        Task<ExecutionJournal> ExecutePlanAsync(ExecutionPlan plan, PlanContext context);
    }
}
