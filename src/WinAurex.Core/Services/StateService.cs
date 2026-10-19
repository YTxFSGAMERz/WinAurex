using System;
using System.Collections.Concurrent;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using WinAurex.Contracts;
using WinAurex.Contracts.Execution;
using WinAurex.Models;

namespace WinAurex.Core.Services
{
    public class StateService : IStateService
    {
        private readonly ISystemStateAnalyzer _stateAnalyzer;
        private readonly string _cacheFilePath;
        private readonly ConcurrentDictionary<string, bool> _cache = new();

        public StateService(ISystemStateAnalyzer stateAnalyzer)
            : this(
                stateAnalyzer,
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WinAurex"))
        {
        }

        public StateService(ISystemStateAnalyzer stateAnalyzer, string basePath)
        {
            _stateAnalyzer = stateAnalyzer ?? throw new ArgumentNullException(nameof(stateAnalyzer));

            if (string.IsNullOrWhiteSpace(basePath))
            {
                throw new ArgumentException("A cache root path is required.", nameof(basePath));
            }

            Directory.CreateDirectory(basePath);
            _cacheFilePath = Path.Combine(basePath, "applied_tweaks.json");

            LoadCache();
        }

        private void LoadCache()
        {
            if (!File.Exists(_cacheFilePath))
            {
                return;
            }

            try
            {
                var json = File.ReadAllText(_cacheFilePath);
                var cached = JsonSerializer.Deserialize<Dictionary<string, bool>>(json);
                if (cached == null)
                {
                    return;
                }

                _cache.Clear();
                foreach (var pair in cached)
                {
                    _cache[pair.Key] = pair.Value;
                }
            }
            catch (JsonException)
            {
                // Corrupt cache: start fresh instead of failing the service.
                _cache.Clear();
            }
            catch (IOException)
            {
                _cache.Clear();
            }
            catch (UnauthorizedAccessException)
            {
                _cache.Clear();
            }
        }

        private void SaveCache()
        {
            var tempPath = _cacheFilePath + ".tmp";

            try
            {
                var snapshot = _cache.ToDictionary(pair => pair.Key, pair => pair.Value);
                var json = JsonSerializer.Serialize(snapshot);

                // Write to a sibling temp file first so a crash cannot truncate
                // the previous cache, then promote it in one step.
                File.WriteAllText(tempPath, json);
                File.Move(tempPath, _cacheFilePath, overwrite: true);
            }
            catch (IOException)
            {
                TryDelete(tempPath);
            }
            catch (UnauthorizedAccessException)
            {
                TryDelete(tempPath);
            }
            catch (NotSupportedException)
            {
                TryDelete(tempPath);
            }
        }

        public async Task<bool> IsActionAppliedAsync(SystemAction action)
        {
            if (action is null)
            {
                throw new ArgumentNullException(nameof(action));
            }

            // First, see if we have a definitive OS state
            if (action.Detection != null || action.ExecutionPlan != null)
            {
                var systemState = await _stateAnalyzer.IsActionAppliedAsync(action).ConfigureAwait(false);
                if (systemState)
                {
                    return true;
                }
            }

            // Fallback to the local cache
            return _cache.TryGetValue(action.Id, out var isApplied) && isApplied;
        }

        public Task SetActionStateAsync(SystemAction action, bool isApplied)
        {
            if (action is null)
            {
                throw new ArgumentNullException(nameof(action));
            }

            _cache[action.Id] = isApplied;
            SaveCache();
            action.IsApplied = isApplied;
            return Task.CompletedTask;
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
