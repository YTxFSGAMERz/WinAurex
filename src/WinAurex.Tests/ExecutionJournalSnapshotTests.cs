using System;
using System.Text.Json;
using WinAurex.Models.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public class ExecutionJournalSnapshotTests
    {
        [Fact]
        public void Journal_Deserializes_Correctly_WithPolymorphism()
        {
            // Arrange
            // We simulate a raw JSON string that represents what a serialized journal looks like.
            string json = """
            {
                "SchemaVersion": 1,
                "ExecutionId": "550e8400-e29b-41d4-a716-446655440000",
                "StartedAt": "2026-07-09T12:00:00Z",
                "Events": [
                    {
                        "$type": "ExecutionStarted",
                        "PlanName": "Test Plan",
                        "Timestamp": "2026-07-09T12:00:00Z"
                    },
                    {
                        "$type": "OperationCompleted",
                        "OperationId": "Registry.DisableTelemetry",
                        "UndoData": "SomeUndoString",
                        "Timestamp": "2026-07-09T12:00:05Z"
                    }
                ]
            }
            """;

            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

            // Act
            var journal = JsonSerializer.Deserialize<ExecutionJournal>(json, options);

            // Assert
            Assert.NotNull(journal);
            Assert.Equal(1, journal.SchemaVersion);
            Assert.Equal(Guid.Parse("550e8400-e29b-41d4-a716-446655440000"), journal.ExecutionId);
            Assert.Equal(2, journal.Events.Count);
            
            // Verify Polymorphism worked by testing the object graph directly (as requested by user)
            var startedEntry = Assert.IsType<ExecutionStartedEntry>(journal.Events[0]);
            Assert.Equal("Test Plan", startedEntry.PlanName);

            var completedEntry = Assert.IsType<OperationCompletedEntry>(journal.Events[1]);
            Assert.Equal("Registry.DisableTelemetry", completedEntry.OperationId.Value);
            Assert.Equal("SomeUndoString", completedEntry.UndoData);
        }
    }
}
