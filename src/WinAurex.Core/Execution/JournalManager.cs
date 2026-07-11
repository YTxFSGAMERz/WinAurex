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
        private readonly string _basePath;

        public JournalManager()
        {
            _basePath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "WinAurex",
                "Journals");
        }

        public string GetJournalDirectory() => _basePath;

        public async Task SaveJournalAsync(ExecutionJournal journal)
        {
            var year = journal.StartedAt.Year.ToString("0000");
            var month = journal.StartedAt.Month.ToString("00");
            var dir = Path.Combine(_basePath, year, month);
            Directory.CreateDirectory(dir);

            var path = Path.Combine(dir, $"{journal.ExecutionId}.json");
            var options = new JsonSerializerOptions { WriteIndented = true };
            
            using var fs = File.Create(path);
            await JsonSerializer.SerializeAsync(fs, journal, options);
        }

        public async Task<ExecutionJournal?> LoadJournalAsync(Guid executionId)
        {
            if (!Directory.Exists(_basePath)) return null;

            foreach (var yearDir in Directory.GetDirectories(_basePath))
            {
                foreach (var monthDir in Directory.GetDirectories(yearDir))
                {
                    var file = Path.Combine(monthDir, $"{executionId}.json");
                    if (File.Exists(file))
                    {
                        using var fs = File.OpenRead(file);
                        return await JsonSerializer.DeserializeAsync<ExecutionJournal>(fs);
                    }
                }
            }
            return null;
        }
    }
}
