using System;
using System.Linq;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Documentation;

namespace WinAurex.Core.Execution
{
    public class PlanDocumenter
    {
        public DocumentationModel GenerateDocumentationModel(ExecutionPlan plan)
        {
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
                var docOp = new OperationDocumentation
                {
                    OperationId = op.Id.Value,
                    Description = op.Description,
                    ProviderName = op.GetType().Name.Replace("Operation", ""),
                    // Basic inference, capabilities would typically be read from provider metadata
                    SupportsRollback = true 
                };

                // Reflection could extract property values here to populate `Parameters` safely
                // For now we keep it empty or static.
                
                model.Operations.Add(docOp);
            }

            return model;
        }
    }
}
