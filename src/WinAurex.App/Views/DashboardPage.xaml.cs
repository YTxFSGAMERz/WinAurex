using Microsoft.UI.Xaml.Controls;
using WinAurex_App.ViewModels;

namespace WinAurex_App.Views
{
    public sealed partial class DashboardPage : Page
    {
        public DashboardViewModel ViewModel { get; }

        public DashboardPage()
        {
            ViewModel = App.GetService<DashboardViewModel>();
            InitializeComponent();
        }
    }
}
