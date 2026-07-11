using System;
using System.Collections.Generic;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution
{
    public class ExecutionPlanner
    {
        public PlanningResult CreatePlan(string name, string description, IEnumerable<ExecutionOperation> operations)
        {
            var plan = new ExecutionPlan
            {
                Id = Guid.NewGuid(),
                Name = name,
                Description = description,
                Operations = System.Collections.Immutable.ImmutableList.CreateRange(operations)
            };

            var conflicts = new List<string>();
            var warnings = new List<string>();

            // Dummy conflict detection for now
            // We can add logic to detect e.g. duplicate IDs or contradicting states

            return new PlanningResult
            {
                Plan = plan,
                Conflicts = conflicts,
                Warnings = warnings
            };
        }
    }
}
