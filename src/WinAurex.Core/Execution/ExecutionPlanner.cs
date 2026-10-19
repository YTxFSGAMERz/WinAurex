using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution
{
    public class ExecutionPlanner
    {
        public PlanningResult CreatePlan(string name, string description, IEnumerable<ExecutionOperation> operations)
        {
            if (operations is null)
            {
                throw new ArgumentNullException(nameof(operations));
            }

            var conflicts = new List<string>();
            var warnings = new List<string>();
            var accepted = new List<ExecutionOperation>();
            var firstById = new Dictionary<string, ExecutionOperation>(StringComparer.Ordinal);

            var index = -1;
            foreach (var operation in operations)
            {
                index++;

                if (operation is null)
                {
                    warnings.Add($"Operation at index {index} is null and was removed from the plan.");
                    continue;
                }

                var id = operation.Id.Value ?? string.Empty;

                if (!firstById.TryGetValue(id, out var first))
                {
                    firstById[id] = operation;
                    accepted.Add(operation);
                    continue;
                }

                if (HasSamePayload(first, operation))
                {
                    warnings.Add($"Operation '{id}' at index {index} duplicates an earlier entry and was collapsed.");
                    continue;
                }

                // Same semantic id with a different payload: keep both so the UI can
                // show what was requested, but block the plan until it is resolved.
                conflicts.Add($"Operation id '{id}' is reused at index {index} with a different target or intent.");
                accepted.Add(operation);
            }

            if (accepted.Count == 0)
            {
                warnings.Add("Plan contains no operations.");
            }

            var plan = new ExecutionPlan
            {
                Id = Guid.NewGuid(),
                Name = name,
                Description = description,
                Operations = ImmutableList.CreateRange(accepted)
            };

            return new PlanningResult
            {
                Plan = plan,
                Conflicts = conflicts,
                Warnings = warnings
            };
        }

        private static bool HasSamePayload(ExecutionOperation left, ExecutionOperation right)
        {
            if (left.GetType() != right.GetType())
            {
                return false;
            }

            var type = left.GetType();
            var target = type.GetProperty("Target");
            var intent = type.GetProperty("Intent");

            return Equals(target?.GetValue(left), target?.GetValue(right))
                && Equals(intent?.GetValue(left), intent?.GetValue(right));
        }
    }
}
