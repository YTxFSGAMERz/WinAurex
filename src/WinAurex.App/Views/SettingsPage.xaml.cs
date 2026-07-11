using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using WinAurex_App.ViewModels;
using WinAurex.Contracts;

namespace WinAurex_App.Views
{
    public sealed partial class SettingsPage : Page
    {
        public SettingsViewModel ViewModel { get; }

        public SettingsPage()
        {
            ViewModel = App.GetService<SettingsViewModel>();
            InitializeComponent();
        }

        private void ToggleTheme_Click(object sender, RoutedEventArgs e)
        {
            ViewModel.SetTheme(AppTheme.Dark);
        }
    }
}
