using CommunityToolkit.Mvvm.ComponentModel;
using WinAurex.Models;

namespace WinAurex_App.State
{
    public partial class AppState : ObservableObject
    {
        [ObservableProperty]
        public partial string CurrentProfile { get; set; } = "Balanced (Default)";

        [ObservableProperty]
        public partial SystemAction SelectedAction { get; set; }
    }
}
