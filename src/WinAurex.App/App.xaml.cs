using System;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using WinAurex.Contracts;
using WinAurex.Core;
using WinAurex.Services;
using WinAurex_App.State;
using WinAurex_App.ViewModels;
using WinAurex_App.Services;
using Windows.ApplicationModel;
using Windows.ApplicationModel.Activation;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Data;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Navigation;
using Microsoft.UI.Xaml.Shapes;

namespace WinAurex_App;

public partial class App : Application
{
    private Window? _window;
    
    public Window? MainWindow => _window;

    public IHost Host { get; }

    public static T GetService<T>() where T : class
    {
        if ((App.Current as App)!.Host.Services.GetService(typeof(T)) is not T service)
        {
            throw new ArgumentException($"{typeof(T)} needs to be registered in DI container.");
        }
        return service;
    }

    public App()
    {
        InitializeComponent();
        
        this.UnhandledException += (s, e) => 
        {
            System.IO.File.WriteAllText("crash.log", e.Exception.ToString());
        };

        Host = Microsoft.Extensions.Hosting.Host.CreateDefaultBuilder()
            .ConfigureServices((context, services) =>
            {
                // Infrastructure & Core
                services.AddSingleton<IRestoreContract, RestoreEngine>();
                services.AddSingleton<ISystemStatusProvider, WinAurex.Infrastructure.SystemStatusProvider>();
                
                services.AddSingleton<WinAurex.Contracts.Execution.ICapabilityRegistry, WinAurex.Core.Execution.CapabilityRegistry>();
                services.AddSingleton<WinAurex.Contracts.Execution.IExecutionEngine, WinAurex.Core.Execution.ExecutionEngine>();
                services.AddSingleton<WinAurex.Core.Execution.IRollbackEngine, WinAurex.Core.Execution.RollbackEngine>();
                
                services.AddSingleton<WinAurex.Contracts.Execution.ISystemStateAnalyzer, WinAurex.Core.Execution.SystemStateAnalyzer>();
                services.AddSingleton<WinAurex.Contracts.IStateService, WinAurex.Core.Services.StateService>();
                
                // Services
                services.AddSingleton<WinAurex.Core.Profiles.ITweakLoader, WinAurex.Core.Profiles.TweakLoader>();
                services.AddSingleton<IEventBus, EventBus>();
                services.AddSingleton<IActionService, ActionService>();

                // UI Services
                services.AddSingleton<NavigationService>();
                services.AddSingleton<INavigationService>(sp => sp.GetRequiredService<NavigationService>());
                services.AddSingleton<INavigationHistory>(sp => sp.GetRequiredService<NavigationService>());
                services.AddSingleton<IAppearanceManager, AppearanceManager>();
                services.AddSingleton<ILogContract, SimpleLogger>();

                // State
                services.AddSingleton<AppState>();

                // ViewModels
                services.AddTransient<DashboardViewModel>();
                services.AddTransient<SettingsViewModel>();
                services.AddTransient<OptimizationProfilesViewModel>();
                
                // Views
            })
            .Build();
            
        // Register capability providers
        var capabilityRegistry = Host.Services.GetRequiredService<WinAurex.Contracts.Execution.ICapabilityRegistry>();
        capabilityRegistry.Register<WinAurex.Infrastructure.Providers.RegistryCapabilityProvider>();
        capabilityRegistry.Register<WinAurex.Infrastructure.Providers.PowerShellCapabilityProvider>();
        capabilityRegistry.Register<WinAurex.Infrastructure.Providers.BatchCapabilityProvider>();
        capabilityRegistry.Register<WinAurex.Infrastructure.Providers.RegFileCapabilityProvider>();
    }

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        _window = new MainWindow();
        _window.Activate();
    }
}
