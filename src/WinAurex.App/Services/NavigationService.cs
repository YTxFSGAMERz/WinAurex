using System;
using System.Collections.Generic;
using Microsoft.UI.Xaml.Controls;
using WinAurex.Contracts;

namespace WinAurex_App.Services
{
    public class NavigationService : INavigationService, INavigationHistory
    {
        private Frame? _frame;
        private readonly List<NavigationRoute> _breadcrumbs = new();

        public IReadOnlyList<NavigationRoute> Breadcrumbs => _breadcrumbs.AsReadOnly();
        public event EventHandler<IReadOnlyList<NavigationRoute>>? HistoryChanged;

        public void Initialize(Frame frame)
        {
            _frame = frame;
        }

        public bool NavigateTo(NavigationRoute route, object? parameter = null)
        {
            if (_frame == null) return false;

            Type pageType = route.Id switch
            {
                "dashboard" => typeof(Views.DashboardPage),
                "settings" => typeof(Views.SettingsPage),
                "profiles" => typeof(Views.OptimizationProfilesPage),
                _ => throw new ArgumentException($"Unknown route: {route.Id}")
            };

            if (_breadcrumbs.Count > 0 && _breadcrumbs[_breadcrumbs.Count - 1].Id == route.Id)
            {
                return true;
            }

            if (route.Id == "dashboard" || route.Id == "settings" || route.Id == "profiles")
            {
                _breadcrumbs.Clear();
                if (_frame != null)
                {
                    _frame.BackStack.Clear();
                }
            }

            var success = _frame.Navigate(pageType, parameter);
            if (success)
            {
                _breadcrumbs.Add(route);
                HistoryChanged?.Invoke(this, _breadcrumbs.AsReadOnly());
            }
            return success;
        }

        public bool GoBack()
        {
            if (_frame != null && _frame.CanGoBack)
            {
                _frame.GoBack();
                if (_breadcrumbs.Count > 0)
                {
                    _breadcrumbs.RemoveAt(_breadcrumbs.Count - 1);
                    HistoryChanged?.Invoke(this, _breadcrumbs.AsReadOnly());
                }
                return true;
            }
            return false;
        }
    }
}
