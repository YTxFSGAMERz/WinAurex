using System;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Documentation;

namespace WinAurex.Core.Execution
{
    public class PlanDocumenter
    {
        private readonly ICapabilityRegistry _registry;

        public PlanDocumenter(ICapabilityRegistry registry)
        {
            _registry = registry ?? throw new ArgumentNullException(nameof(registry));
        }

        public DocumentationModel GenerateDocumentationModel(ExecutionPlan plan)
        {
            if (plan is null)
            {
                throw new ArgumentNullException(nameof(plan));
            }

            var model = new DocumentationModel
            {
                PlanName = plan.Name,
                Description = plan.Description,
                Author = plan.Author,
                Version = plan.Version,
                RiskLevel = plan.RiskLevel,
                RequiresElevation = plan.RequiresElevation,
                RequiresRestart = plan.RequiresRestart,
            };

            foreach (var op in plan.Operations)
            {
                // A provider that is not registered cannot be assumed to support rollback.
                bool supportsRollback = false;
                if (_registry.TryGetProvider(op.Id.Provider, out var provider) && provider is not null)
                {
                    supportsRollback = provider.Metadata.SupportsRollback;
                }

                var docOp = new OperationDocumentation
                {
                    OperationId = op.Id.Value,
                    Description = op.Description,
                    ProviderName = op.GetType().Name.Replace("Operation", ""),
                    SupportsRollback = supportsRollback
                };

                // Reflection could extract property values here to populate `Parameters` safely
                // For now we keep it empty or static.

                model.Operations.Add(docOp);
            }

            return model;
        }
    }
}
