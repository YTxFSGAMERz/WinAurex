using System;
using System.Collections.Generic;
using System.IO;
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
        private Dictionary<string, bool> _cache = new();

        public StateService(ISystemStateAnalyzer stateAnalyzer)
        {
            _stateAnalyzer = stateAnalyzer;
            var appDataPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WinAurex");
            Directory.CreateDirectory(appDataPath);
            _cacheFilePath = Path.Combine(appDataPath, "applied_tweaks.json");
            
            LoadCache();
        }

        private void LoadCache()
        {
            if (File.Exists(_cacheFilePath))
            {
                try
                {
                    var json = File.ReadAllText(_cacheFilePath);
                    var cached = JsonSerializer.Deserialize<Dictionary<string, bool>>(json);
                    if (cached != null)
                    {
                        _cache = cached;
                    }
                }
                catch
                {
                    // If cache is corrupted, just start fresh
                    _cache = new Dictionary<string, bool>();
                }
            }
        }

        private void SaveCache()
        {
            try
            {
                var json = JsonSerializer.Serialize(_cache);
                File.WriteAllText(_cacheFilePath, json);
            }
            catch
            {
                // Best effort save
            }
        }

        public async Task<bool> IsActionAppliedAsync(SystemAction action)
        {
            // First, see if we have a definitive OS state
            if (action.Detection != null || action.ExecutionPlan != null)
            {
                // Check system state based on detection rules or execution plan
                var systemState = await _stateAnalyzer.IsActionAppliedAsync(action);
                if (systemState)
                {
                    return true;
                }
            }

            // Fallback to our local cache
            if (_cache.TryGetValue(action.Id, out bool isApplied))
            {
                return isApplied;
            }

            return false;
        }

        public Task SetActionStateAsync(SystemAction action, bool isApplied)
        {
            _cache[action.Id] = isApplied;
            SaveCache();
            action.IsApplied = isApplied;
            return Task.CompletedTask;
        }
    }
}
