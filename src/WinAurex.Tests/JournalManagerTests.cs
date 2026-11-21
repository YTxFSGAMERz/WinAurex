using System;
using System.IO;
using System.Threading.Tasks;
using WinAurex.Core.Execution;
using WinAurex.Models.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public sealed class JournalManagerTests : IDisposable
    {
        private readonly string _root;

        public JournalManagerTests()
        {
            _root = Path.Combine(Path.GetTempPath(), "WinAurexTests", Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
        }

        public void Dispose()
        {
            try
            {
                if (Directory.Exists(_root))
                {
                    Directory.Delete(_root, recursive: true);
                }
            }
            catch (IOException)
            {
            }
        }

        [Fact]
        public async Task SaveThenLoad_RoundTripsJournalUnderYearMonthPartition()
        {
            var manager = new JournalManager(_root);
            var id = Guid.NewGuid();
            var startedAt = new DateTimeOffset(2026, 3, 7, 9, 30, 0, TimeSpan.Zero);

            await manager.SaveJournalAsync(CreateJournal(id, startedAt));

            var expectedFile = Path.Combine(_root, "2026", "03", $"{id}.json");
            Assert.True(File.Exists(expectedFile));

            var loaded = await manager.LoadJournalAsync(id);

            Assert.NotNull(loaded);
            Assert.Equal(id, loaded!.ExecutionId);
            Assert.Equal(JournalManager.CurrentSchemaVersion, loaded.SchemaVersion);
            Assert.Equal(2, loaded.Events.Count);
            Assert.IsType<ExecutionStartedEntry>(loaded.Events[0]);
            var completed = Assert.IsType<OperationCompletedEntry>(loaded.Events[1]);
            Assert.Equal("Registry.DisableTelemetry", completed.OperationId.Value);
            Assert.Equal("snapshot-before", completed.UndoData);
        }

        [Fact]
        public async Task SaveTwice_OverwritesInPlace_AndLeavesNoTempFile()
        {
            var manager = new JournalManager(_root);
            var id = Guid.NewGuid();
            var startedAt = new DateTimeOffset(2026, 5, 2, 8, 0, 0, TimeSpan.Zero);

            await manager.SaveJournalAsync(CreateJournal(id, startedAt));

            var second = CreateJournal(id, startedAt);
            second.Events.Add(new OperationFailedEntry
            {
                OperationId = new OperationId("Service.StopSpooler"),
                ErrorMessage = "access denied"
            });
            await manager.SaveJournalAsync(second);

            var loaded = await manager.LoadJournalAsync(id);
            Assert.NotNull(loaded);
            Assert.Equal(3, loaded!.Events.Count);

            var tempFiles = Directory.GetFiles(Path.Combine(_root, "2026", "05"), "*.tmp");
            Assert.Empty(tempFiles);
        }

        [Fact]
        public async Task Load_TruncatedFile_ReturnsNullWithoutThrowing()
        {
            var manager = new JournalManager(_root);
            var id = Guid.NewGuid();
            var dir = Path.Combine(_root, "2026", "01");
            Directory.CreateDirectory(dir);
            await File.WriteAllTextAsync(Path.Combine(dir, $"{id}.json"), "{\"SchemaVersion\":1,\"ExecutionId\":\"");

            var loaded = await manager.LoadJournalAsync(id);

            Assert.Null(loaded);
        }

        [Fact]
        public async Task Load_UnsupportedSchemaVersion_IsRejected()
        {
            var manager = new JournalManager(_root);
            var id = Guid.NewGuid();
            var dir = Path.Combine(_root, "2026", "02");
            Directory.CreateDirectory(dir);
            var json = $$"""
            {
                "SchemaVersion": 99,
                "ExecutionId": "{{id}}",
                "StartedAt": "2026-02-11T10:00:00+00:00",
                "Events": []
            }
            """;
            await File.WriteAllTextAsync(Path.Combine(dir, $"{id}.json"), json);

            var loaded = await manager.LoadJournalAsync(id);

            Assert.Null(loaded);
        }

        [Fact]
        public async Task Load_FileWithMismatchedExecutionId_ReturnsNull()
        {
            var manager = new JournalManager(_root);
            var savedId = Guid.NewGuid();
            var requestedId = Guid.NewGuid();
            var startedAt = new DateTimeOffset(2026, 6, 1, 0, 0, 0, TimeSpan.Zero);

            await manager.SaveJournalAsync(CreateJournal(savedId, startedAt));
            var dir = Path.Combine(_root, "2026", "06");
            File.Copy(
                Path.Combine(dir, $"{savedId}.json"),
                Path.Combine(dir, $"{requestedId}.json"));

            Assert.Null(await manager.LoadJournalAsync(requestedId));
        }

        private static ExecutionJournal CreateJournal(Guid id, DateTimeOffset startedAt)
        {
            return new ExecutionJournal
            {
                ExecutionId = id,
                StartedAt = startedAt,
                Events =
                {
                    new ExecutionStartedEntry
                    {
                        PlanName = "Journal manager test plan",
                        Timestamp = startedAt
                    },
                    new OperationCompletedEntry
                    {
                        OperationId = new OperationId("Registry.DisableTelemetry"),
                        UndoData = "snapshot-before",
                        Timestamp = startedAt.AddSeconds(4)
                    }
                }
            };
        }
    }
}
