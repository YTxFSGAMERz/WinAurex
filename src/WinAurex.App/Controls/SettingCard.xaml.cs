using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using WinAurex.Models;
using WinAurex.Models.Execution.Operations;

namespace WinAurex_App.Controls
{
    public sealed partial class SettingCard : UserControl
    {
        public static readonly DependencyProperty ActionProperty =
            DependencyProperty.Register(
                nameof(Action),
                typeof(SystemAction),
                typeof(SettingCard),
                new PropertyMetadata(null));

        public SystemAction Action
        {
            get => (SystemAction)GetValue(ActionProperty);
            set => SetValue(ActionProperty, value);
        }

        public SettingCard()
        {
            this.InitializeComponent();
        }

        private async void InfoButton_Click(object sender, RoutedEventArgs e)
        {
            var action = Action;
            string content = action?.Description + "\n\n";
            
            content += "--- APPLY ACTION ---\n";
            content += await GetPlanCodeAsync(action?.ExecutionPlan);

            if (action?.RollbackPlan != null)
            {
                content += "\n\n--- REVERT ACTION ---\n";
                content += await GetPlanCodeAsync(action?.RollbackPlan);
            }

            var dialog = new ContentDialog
            {
                Title = $"{action?.DisplayName} - Execution Details",
                Content = new ScrollViewer 
                { 
                    Content = new TextBlock 
                    { 
                        Text = content, 
                        TextWrapping = TextWrapping.Wrap,
                        FontFamily = new Microsoft.UI.Xaml.Media.FontFamily("Consolas"),
                        FontSize = 12
                    },
                    MaxHeight = 400
                },
                CloseButtonText = "Close",
                XamlRoot = this.XamlRoot
            };

            await dialog.ShowAsync();
        }

        private async Task<string> GetPlanCodeAsync(WinAurex.Models.Execution.ExecutionPlan plan)
        {
            if (plan == null || plan.Operations == null || plan.Operations.Count == 0)
                return "No executable operation or binary file.";

            var operation = plan.Operations.First();
            
            string filePath = null;
            if (operation is PowerShellOperation psOp) filePath = psOp.Target.FilePath;
            else if (operation is BatchOperation batOp) filePath = batOp.Target.FilePath;
            else if (operation is RegFileOperation regOp) filePath = regOp.Target.FilePath;

            if (!string.IsNullOrEmpty(filePath) && File.Exists(filePath))
            {
                if (filePath.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                    return "Compiled Executable Binary. No source code available.";
                    
                return await File.ReadAllTextAsync(filePath);
            }

            return "Unknown or binary operation.";
        }

        public Visibility HasMultipleMethods(IList<WinAurex.Models.ActionExecutionMethod> methods)
        {
            return methods != null && methods.Count > 1 ? Visibility.Visible : Visibility.Collapsed;
        }

        private async void ToggleSwitch_Toggled(object sender, RoutedEventArgs e)
        {
            if (sender is ToggleSwitch toggle && Action != null)
            {
                // Prevent event firing loop if updated programmatically
                if (toggle.IsOn == Action.IsApplied)
                    return;

                Action.IsExecuting = true;

                try
                {
                    var actionService = App.GetService<WinAurex.Contracts.IActionService>();

                    if (toggle.IsOn)
                    {
                        var result = await actionService.ApplyAsync(Action);
                        if (result.Status != WinAurex.Models.ActionStatus.Applied)
                        {
                            // Revert toggle if execution failed
                            toggle.IsOn = false;
                        }
                        else
                        {
                            Action.IsApplied = true;
                        }
                    }
                    else
                    {
                        var result = await actionService.RollbackAsync(Action);
                        if (result.Status != WinAurex.Models.ActionStatus.NotApplied)
                        {
                            toggle.IsOn = true;
                        }
                        else
                        {
                            Action.IsApplied = false;
                        }
                    }
                }
                catch
                {
                    // Revert toggle if crashed
                    toggle.IsOn = !toggle.IsOn;
                }
                finally
                {
                    Action.IsExecuting = false;
                }
            }
        }
    }
}
