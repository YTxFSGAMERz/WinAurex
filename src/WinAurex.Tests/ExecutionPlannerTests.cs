using System;
using System.Collections.Generic;
using System.Linq;
using WinAurex.Core.Execution;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class ExecutionPlannerTests
    {
        private const string TelemetryId = "Registry.DisableTelemetry";

        [Fact]
        public void IdenticalDuplicates_CollapseToASingleOperation()
        {
            var planner = new ExecutionPlanner();
            var operations = new[]
            {
                CreateTelemetryOperation(0),
                CreateTelemetryOperation(0)
            };

            var result = planner.CreatePlan("dedupe", "duplicate registry writes", operations);

            Assert.NotNull(result.Plan);
            Assert.Single(result.Plan!.Operations);
            Assert.Empty(result.Conflicts);
            Assert.True(result.IsSuccessful);
            Assert.Contains(result.Warnings, warning => warning.Contains(TelemetryId));
        }

        [Fact]
        public void SameIdWithDifferentPayload_IsReportedAsConflict()
        {
            var planner = new ExecutionPlanner();
            var operations = new[]
            {
                CreateTelemetryOperation(0),
                CreateTelemetryOperation(1)
            };

            var result = planner.CreatePlan("conflict", "contradicting values", operations);

            Assert.NotNull(result.Plan);
            Assert.Equal(2, result.Plan!.Operations.Count);
            var conflict = Assert.Single(result.Conflicts);
            Assert.Contains(TelemetryId, conflict);
            Assert.False(result.IsSuccessful);
        }

        [Fact]
        public void NullEntries_AreFilteredAndWarningIsRecorded()
        {
            var planner = new ExecutionPlanner();
            var operations = new ExecutionOperation[]
            {
                null!,
                CreateTelemetryOperation(0)
            };

            var result = planner.CreatePlan("hygiene", "one null entry", operations);

            Assert.NotNull(result.Plan);
            Assert.Single(result.Plan!.Operations);
            Assert.Empty(result.Conflicts);
            Assert.Contains(result.Warnings, warning => warning.Contains("null"));
        }

        [Fact]
        public void EmptyOperationSet_ProducesWarningWithoutConflicts()
        {
            var planner = new ExecutionPlanner();

            var result = planner.CreatePlan("empty", "no operations at all", Enumerable.Empty<ExecutionOperation>());

            Assert.NotNull(result.Plan);
            Assert.Empty(result.Plan!.Operations);
            Assert.Empty(result.Conflicts);
            Assert.Contains(result.Warnings, warning => warning.Contains("no operations", StringComparison.OrdinalIgnoreCase));
            Assert.True(result.IsSuccessful);
        }

        [Fact]
        public void NullOperationSequence_IsRejected()
        {
            var planner = new ExecutionPlanner();

            Assert.Throws<ArgumentNullException>(() => planner.CreatePlan("null", "null sequence", null!));
        }

        private static RegistryOperation CreateTelemetryOperation(int value)
        {
            return new RegistryOperation(new OperationId(TelemetryId))
            {
                Description = "Toggle the telemetry value",
                Target = new RegistryTarget(RegistryHive.CurrentUser, @"Software\WinAurex", "Telemetry"),
                Intent = new SetRegistryValueIntent(value, RegistryValueKind.DWord)
            };
        }
    }
}
