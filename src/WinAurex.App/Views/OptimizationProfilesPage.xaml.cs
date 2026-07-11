using Microsoft.UI.Xaml.Controls;
using WinAurex_App.ViewModels;

namespace WinAurex_App.Views
{
    public sealed partial class OptimizationProfilesPage : Page
    {
        public OptimizationProfilesViewModel ViewModel { get; }

        public OptimizationProfilesPage()
        {
            this.InitializeComponent();
            ViewModel = App.GetService<OptimizationProfilesViewModel>();
        }
    }
}
