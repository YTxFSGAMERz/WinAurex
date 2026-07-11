using CommunityToolkit.Mvvm.ComponentModel;
using WinAurex.Contracts;

namespace WinAurex_App.ViewModels
{
    public partial class SettingsViewModel : ObservableObject
    {
        private readonly IAppearanceManager _appearanceManager;

        public SettingsViewModel(IAppearanceManager appearanceManager)
        {
            _appearanceManager = appearanceManager;
        }

        public void SetTheme(AppTheme theme)
        {
            _appearanceManager.SetTheme(theme);
        }
    }
}
