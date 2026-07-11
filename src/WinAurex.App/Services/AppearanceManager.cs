using System;
using Microsoft.UI.Xaml;
using WinAurex.Contracts;

namespace WinAurex_App.Services
{
    public class AppearanceManager : IAppearanceManager
    {
        public AppTheme CurrentTheme { get; private set; } = AppTheme.Default;
        public BackdropType CurrentBackdrop { get; private set; } = BackdropType.Mica;

        public void SetTheme(AppTheme theme)
        {
            CurrentTheme = theme;
            
            if (App.Current is App app && app.MainWindow?.Content is FrameworkElement rootElement)
            {
                rootElement.RequestedTheme = theme switch
                {
                    AppTheme.Light => ElementTheme.Light,
                    AppTheme.Dark => ElementTheme.Dark,
                    _ => ElementTheme.Default
                };
            }
        }

        public void SetBackdrop(BackdropType backdrop)
        {
            CurrentBackdrop = backdrop;
            // TODO: Apply Mica or Acrylic to MainWindow
        }

        public void SetAccentColor(string hexColor)
        {
            // TODO: Update Application.Current.Resources["SystemAccentColor"]
        }
    }
}
