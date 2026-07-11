using System.Collections.ObjectModel;
using System.IO;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WinAurex.Contracts;
using WinAurex.Core.Profiles;
using WinAurex_App.State;
using WinAurex.Models;

namespace WinAurex_App.ViewModels
{
    public partial class TweakGroup : ObservableObject
    {
        public string Category { get; set; } = string.Empty;
        public string CategoryIcon { get; set; } = "\xE713";
        public ObservableCollection<SystemAction> Tweaks { get; set; } = new();

        [ObservableProperty]
        public partial bool IsExpanded { get; set; }

        [RelayCommand]
        private void ApplyAll()
        {
            foreach (var tweak in Tweaks)
            {
                tweak.IsApplied = true;
            }
        }

        [RelayCommand]
        private void RevertAll()
        {
            foreach (var tweak in Tweaks)
            {
                tweak.IsApplied = false;
            }
        }
    }

    public partial class DashboardViewModel : ObservableObject
    {
        private readonly ISystemStatusProvider _statusProvider;
        private readonly AppState _appState;
        private readonly ITweakLoader _tweakLoader;

        [ObservableProperty]
        public partial string WindowsVersion { get; set; }

        [ObservableProperty]
        public partial string HealthStatus { get; set; }

        public ObservableCollection<TweakGroup> GroupedActions { get; } = new();
        public ObservableCollection<TweakGroup> FilteredGroups { get; } = new();

        [ObservableProperty]
        public partial int TotalTweaksCount { get; set; }

        [ObservableProperty]
        public partial int ActiveTweaksCount { get; set; }



        private string _searchQuery = string.Empty;
        public string SearchQuery
        {
            get => _searchQuery;
            set
            {
                if (SetProperty(ref _searchQuery, value))
                {
                    FilterTweaks();
                }
            }
        }

        private readonly IStateService _stateService;

        public DashboardViewModel(ISystemStatusProvider statusProvider, AppState appState, ITweakLoader tweakLoader, IStateService stateService)
        {
            _statusProvider = statusProvider;
            _appState = appState;
            _tweakLoader = tweakLoader;
            _stateService = stateService;

            WindowsVersion = _statusProvider.GetWindowsVersion();
            HealthStatus = _statusProvider.GetHealthStatus();

            _ = LoadTweaksAsync();
        }

        private async Task LoadTweaksAsync()
        {
            var tweaksPath = Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "tweaks");
            if (!Directory.Exists(tweaksPath))
            {
                var repoRoot = Path.GetFullPath(Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "..\\..\\..\\..\\..\\..\\"));
                tweaksPath = Path.Combine(repoRoot, "tweaks");
            }

            var actions = _tweakLoader.LoadTweaks(tweaksPath).ToList();
            
            // Load state for all actions
            foreach (var action in actions)
            {
                action.IsApplied = await _stateService.IsActionAppliedAsync(action);
            }

            var groups = actions
                .GroupBy(a => a.Category)
                .OrderBy(g => g.Key)
                .Select(g => new TweakGroup 
                { 
                    Category = string.IsNullOrWhiteSpace(g.Key) ? "Uncategorized" : g.Key, 
                    CategoryIcon = GetIconForCategory(g.Key),
                    Tweaks = new ObservableCollection<SystemAction>(g.OrderBy(a => a.DisplayName)),
                    IsExpanded = false
                });

            int total = 0;
            foreach (var group in groups)
            {
                total += group.Tweaks.Count;
                foreach (var tweak in group.Tweaks)
                {
                    tweak.PropertyChanged += (s, e) => 
                    {
                        if (e.PropertyName == nameof(SystemAction.IsApplied))
                        {
                            UpdateActiveCount();
                        }
                    };
                }
                GroupedActions.Add(group);
                FilteredGroups.Add(group);
            }
            TotalTweaksCount = total;
            UpdateActiveCount();
        }

        private void UpdateActiveCount()
        {
            int active = 0;
            foreach (var group in GroupedActions)
            {
                active += group.Tweaks.Count(t => t.IsApplied);
            }
            ActiveTweaksCount = active;
        }



        private string GetIconForCategory(string category)
        {
            if (string.IsNullOrWhiteSpace(category)) return "\xE713"; // Settings

            return category.ToLowerInvariant() switch
            {
                "apps" => "\xE71D",
                "audio" => "\xE767",
                "background" => "\xE7B5",
                "boot" => "\xE7E8",
                "browser" => "\xE774",
                "camera" => "\xE722",
                "clipboard" => "\xE77F",
                "context_menu" => "\xE712",
                "cortana" => "\xE90F",
                "date_time" => "\xE783",
                "desktop" => "\xE7FB",
                "explorer" => "\xE7B8",
                "gaming" => "\xE7FC",
                "keyboard" => "\xE765",
                "mouse" => "\xE962",
                "network" => "\xE774",
                "power" => "\xE7E8",
                "privacy" => "\xE77A",
                "security" => "\xE77A",
                "services" => "\xE9A1",
                "start" => "\xE712",
                "taskbar" => "\xE9A1",
                "telemetry" => "\xE77A",
                "theme" => "\xE771",
                "uwp" => "\xE71D",
                "windows_update" => "\xE7A6",
                _ => "\xE713"
            };
        }

        private void FilterTweaks()
        {
            FilteredGroups.Clear();

            if (string.IsNullOrWhiteSpace(SearchQuery))
            {
                foreach (var group in GroupedActions)
                {
                    group.IsExpanded = false;
                    FilteredGroups.Add(group);
                }
                return;
            }

            var lowerQuery = SearchQuery.ToLowerInvariant();

            foreach (var group in GroupedActions)
            {
                var categoryMatches = group.Category.ToLowerInvariant().Contains(lowerQuery);
                var filteredTweaks = group.Tweaks.Where(t => 
                    categoryMatches ||
                    t.DisplayName.ToLowerInvariant().Contains(lowerQuery) || 
                    t.Description.ToLowerInvariant().Contains(lowerQuery)).ToList();

                if (filteredTweaks.Any())
                {
                    FilteredGroups.Add(new TweakGroup
                    {
                        Category = group.Category,
                        CategoryIcon = group.CategoryIcon,
                        Tweaks = new ObservableCollection<SystemAction>(filteredTweaks),
                        IsExpanded = true
                    });
                }
            }
        }
    }
}
