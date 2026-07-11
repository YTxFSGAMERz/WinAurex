using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WinAurex.Models;

namespace WinAurex_App.Models
{
    public partial class OptimizationProfile : ObservableObject
    {
        [ObservableProperty]
        public partial string Name { get; set; } = string.Empty;

        [ObservableProperty]
        public partial string Description { get; set; } = string.Empty;

        [ObservableProperty]
        public partial string Icon { get; set; } = string.Empty;

        public ObservableCollection<SystemAction> Tweaks { get; set; } = new();

        [ObservableProperty]
        public partial bool IsExpanded { get; set; }

        [RelayCommand]
        private void ApplyProfile()
        {
            foreach (var tweak in Tweaks)
            {
                tweak.IsApplied = true;
            }
        }

        [RelayCommand]
        private void RevertProfile()
        {
            foreach (var tweak in Tweaks)
            {
                tweak.IsApplied = false;
            }
        }
    }
}
