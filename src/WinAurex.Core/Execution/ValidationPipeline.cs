using System.Collections.Generic;
using System.Threading.Tasks;
using WinAurex.Models.Execution;
using WinAurex.Contracts.Execution;

namespace WinAurex.Core.Execution
{
    public interface IValidationPipeline
    {
        Task<ValidationResult> ValidateAsync(ExecutionPlan plan, PlanContext context);
    }

    public class ValidationResult
    {
        public bool IsValid => Errors.Count == 0;
        public List<string> Errors { get; } = new();
        public List<string> Warnings { get; } = new();
    }

    public class ValidationPipeline : IValidationPipeline
    {
        // Future: could inject IEnumerable<IValidationRule>
        public Task<ValidationResult> ValidateAsync(ExecutionPlan plan, PlanContext context)
        {
            var result = new ValidationResult();

            if (plan.Operations.Count == 0)
            {
                result.Errors.Add("Execution plan contains no operations.");
            }

            if (plan.RequiresElevation && !context.IsElevated)
            {
                result.Errors.Add("Plan requires elevated privileges, but the context is not elevated.");
            }

            return Task.FromResult(result);
        }
    }
}
