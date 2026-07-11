using System.Linq;
using Microsoft.UI.Xaml.Controls;
using WinAurex.Contracts;

namespace WinAurex_App.Views
{
    public sealed partial class AppShell : Page
    {
        private readonly INavigationService _navigationService;
        private readonly INavigationHistory _navigationHistory;

        public AppShell()
        {
            InitializeComponent();
            
            _navigationService = App.GetService<INavigationService>();
            _navigationHistory = App.GetService<INavigationHistory>();
            
            if (_navigationService is Services.NavigationService navImpl)
            {
                navImpl.Initialize(ContentFrame);
            }

            _navigationHistory.HistoryChanged += (s, e) => UpdateBreadcrumbs();
            
            RootNavigationView.SelectedItem = RootNavigationView.MenuItems[0];
        }

        private void UpdateBreadcrumbs()
        {
            AppBreadcrumbBar.ItemsSource = _navigationHistory.Breadcrumbs.Select(b => char.ToUpper(b.Id[0]) + b.Id.Substring(1)).ToList();
        }

        private void RootNavigationView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
        {
            if (args.IsSettingsSelected)
            {
                _navigationService.NavigateTo(Routes.Settings);
                return;
            }

            if (args.SelectedItem is NavigationViewItem item)
            {
                var tag = item.Tag?.ToString();
                if (tag == "dashboard")
                {
                    _navigationService.NavigateTo(Routes.Dashboard);
                }
                else if (tag == "profiles")
                {
                    _navigationService.NavigateTo(Routes.Profiles);
                }
            }
        }
    }
}
