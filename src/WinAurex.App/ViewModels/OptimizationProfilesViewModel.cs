using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using CommunityToolkit.Mvvm.ComponentModel;
using WinAurex.Contracts;
using WinAurex.Core.Profiles;
using WinAurex.Models;
using WinAurex_App.Models;

namespace WinAurex_App.ViewModels
{
    public partial class OptimizationProfilesViewModel : ObservableObject
    {
        private readonly ITweakLoader _tweakLoader;

        public ObservableCollection<OptimizationProfile> Profiles { get; } = new();

        private readonly IStateService _stateService;

        public OptimizationProfilesViewModel(ITweakLoader tweakLoader, IStateService stateService)
        {
            _tweakLoader = tweakLoader;
            _stateService = stateService;
            _ = LoadProfilesAsync();
        }

        private async Task LoadProfilesAsync()
        {
            var tweaksPath = Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "tweaks");
            if (!Directory.Exists(tweaksPath))
            {
                var repoRoot = Path.GetFullPath(Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "..\\..\\..\\..\\..\\..\\"));
                tweaksPath = Path.Combine(repoRoot, "tweaks");
            }

            var allActions = _tweakLoader.LoadTweaks(tweaksPath).ToList();

            foreach (var action in allActions)
            {
                action.IsApplied = await _stateService.IsActionAppliedAsync(action);
            }

            // Profile 1: Maximum Performance
            var perfTweaks = allActions.Where(t => 
                t.Category.ToLowerInvariant() == "telemetry" || 
                t.Category.ToLowerInvariant() == "privacy" || 
                t.Category.ToLowerInvariant() == "boot" || 
                t.Category.ToLowerInvariant() == "gaming").ToList();
                
            Profiles.Add(new OptimizationProfile
            {
                Name = "Maximum Performance",
                Description = "Disables unnecessary background services, telemetry, and visual effects to squeeze every drop of performance for gaming and heavy workloads.",
                Icon = "\xE9A1", // SpeedHigh icon
                Tweaks = new ObservableCollection<SystemAction>(perfTweaks)
            });

            // Profile 2: Privacy Focused
            var privacyTweaks = allActions.Where(t => 
                t.Category.ToLowerInvariant() == "privacy" || 
                t.Category.ToLowerInvariant() == "telemetry").ToList();

            Profiles.Add(new OptimizationProfile
            {
                Name = "Privacy Focused",
                Description = "Disables Windows telemetry, data collection, tracking services, and unwanted cloud synchronizations.",
                Icon = "\xE77A", // Shield icon
                Tweaks = new ObservableCollection<SystemAction>(privacyTweaks)
            });

            // Profile 3: Safe Defaults
            var safeTweaks = allActions.Where(t => t.RiskLevel == RiskLevel.Safe).ToList();

            Profiles.Add(new OptimizationProfile
            {
                Name = "Safe Defaults",
                Description = "Applies only the safest, universally recommended tweaks that won't break any core Windows features or apps.",
                Icon = "\xE73E", // CheckMark icon
                Tweaks = new ObservableCollection<SystemAction>(safeTweaks)
            });
        }
    }
}
