using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using WinAurex.Models.Execution;

namespace WinAurex.Core.Execution
{
    public interface IJournalManager
    {
        Task SaveJournalAsync(ExecutionJournal journal);
        Task<ExecutionJournal?> LoadJournalAsync(Guid executionId);
        string GetJournalDirectory();
    }

    public class JournalManager : IJournalManager
    {
        /// <summary>Schema version this build understands on both read and write.</summary>
        public const int CurrentSchemaVersion = 1;

        private static readonly JsonSerializerOptions SerializerOptions = new()
        {
            WriteIndented = true
        };

        private readonly string _basePath;

        public JournalManager()
            : this(Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "WinAurex",
                "Journals"))
        {
        }

        public JournalManager(string basePath)
        {
            if (string.IsNullOrWhiteSpace(basePath))
            {
                throw new ArgumentException("A journal root path is required.", nameof(basePath));
            }

            _basePath = Path.GetFullPath(basePath);
        }

        public string GetJournalDirectory() => _basePath;

        public async Task SaveJournalAsync(ExecutionJournal journal)
        {
            if (journal is null)
            {
                throw new ArgumentNullException(nameof(journal));
            }

            if (journal.ExecutionId == Guid.Empty)
            {
                throw new ArgumentException("Journal must carry a non-empty execution id.", nameof(journal));
            }

            var dir = GetPartitionDirectory(journal.StartedAt);
            Directory.CreateDirectory(dir);

            var target = Path.Combine(dir, $"{journal.ExecutionId}.json");
            var temp = target + ".tmp";

            try
            {
                // Write the full document to a sibling temp file first so the
                // destination is never truncated, then promote it with the
                // atomic replace that File.Move performs on a single volume.
                using (var fs = new FileStream(temp, FileMode.Create, FileAccess.Write, FileShare.None))
                {
                    await JsonSerializer.SerializeAsync(fs, journal, SerializerOptions).ConfigureAwait(false);
                    await fs.FlushAsync().ConfigureAwait(false);
                }

                File.Move(temp, target, overwrite: true);
            }
            catch
            {
                TryDelete(temp);
                throw;
            }
        }

        public async Task<ExecutionJournal?> LoadJournalAsync(Guid executionId)
        {
            if (executionId == Guid.Empty || !Directory.Exists(_basePath))
            {
                return null;
            }

            foreach (var yearDir in Directory.GetDirectories(_basePath))
            {
                foreach (var monthDir in Directory.GetDirectories(yearDir))
                {
                    var file = Path.Combine(monthDir, $"{executionId}.json");
                    if (!File.Exists(file))
                    {
                        continue;
                    }

                    var journal = await TryReadJournalAsync(file, executionId).ConfigureAwait(false);
                    if (journal is not null)
                    {
                        return journal;
                    }
                }
            }

            return null;
        }

        private string GetPartitionDirectory(DateTimeOffset startedAt) =>
            Path.Combine(
                _basePath,
                startedAt.Year.ToString("0000"),
                startedAt.Month.ToString("00"));

        private static async Task<ExecutionJournal?> TryReadJournalAsync(string file, Guid expectedExecutionId)
        {
            try
            {
                using var fs = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.Read);
                var journal = await JsonSerializer.DeserializeAsync<ExecutionJournal>(fs).ConfigureAwait(false);

                if (journal is null || journal.SchemaVersion != CurrentSchemaVersion)
                {
                    return null;
                }

                // Guard against a file that was copied or renamed into the wrong slot.
                if (journal.ExecutionId != expectedExecutionId)
                {
                    return null;
                }

                return journal;
            }
            catch (JsonException)
            {
                // Truncated or hand-edited file: a clean miss, not a crash.
                return null;
            }
            catch (IOException)
            {
                return null;
            }
            catch (UnauthorizedAccessException)
            {
                return null;
            }
        }

        private static void TryDelete(string path)
        {
            try
            {
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }
            catch (IOException)
            {
            }
            catch (UnauthorizedAccessException)
            {
            }
        }
    }
}
