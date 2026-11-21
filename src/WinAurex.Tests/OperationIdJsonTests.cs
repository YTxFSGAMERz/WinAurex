using System;
using System.Text.Json;
using WinAurex.Models.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public class OperationIdJsonTests
    {
        [Fact]
        public void ValidOperationId_RoundTrips()
        {
            var original = new OperationId("Registry.Telemetry.Disable");

            var json = JsonSerializer.Serialize(original);
            var restored = JsonSerializer.Deserialize<OperationId>(json);

            Assert.Equal("\"Registry.Telemetry.Disable\"", json);
            Assert.Equal(original.Value, restored.Value);
            Assert.Equal(original.Provider, restored.Provider);
            Assert.Equal(original.Action, restored.Action);
        }

        [Theory]
        [InlineData("\"\"")]
        [InlineData("\"   \"")]
        [InlineData("null")]
        [InlineData("123")]
        [InlineData("{}")]
        [InlineData("[]")]
        public void InvalidOperationId_ThrowsJsonException(string json)
        {
            Assert.Throws<JsonException>(() => JsonSerializer.Deserialize<OperationId>(json));
        }

        [Fact]
        public void JournalWithEmptyOperationId_ThrowsJsonException()
        {
            const string json = """
            {
                "SchemaVersion": 1,
                "ExecutionId": "550e8400-e29b-41d4-a716-446655440000",
                "Events": [
                    {
                        "$type": "OperationStarted",
                        "OperationId": ""
                    }
                ]
            }
            """;

            Assert.Throws<JsonException>(() => JsonSerializer.Deserialize<ExecutionJournal>(json));
        }
    }
}
