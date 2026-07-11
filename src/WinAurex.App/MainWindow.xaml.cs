using Microsoft.UI.Xaml;

namespace WinAurex_App;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        AppWindow.SetIcon("Assets/AppIcon.ico");

        RootFrame.Navigate(typeof(Views.AppShell));
    }
}
