using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;

namespace WinAurex.Infrastructure.Providers
{
    public class PowerShellCapabilityProvider : ICapabilityProvider<PowerShellOperation>
    {
        public ProviderMetadata Metadata { get; } = new ProviderMetadata(
            Id: "PowerShellExecutor",
            Name: "PowerShellExecutor",
            Version: "1.0",
            SupportsRollback: false,
            SupportsDryRun: false,
            RequiresElevation: true,
            MaxRiskLevel: WinAurex.Models.RiskLevel.Advanced
        );

        public Task<ProviderResult> AnalyzeAsync(PowerShellOperation operation, PlanContext context)
        {
            if (operation.Target == null || string.IsNullOrWhiteSpace(operation.Target.FilePath))
                return Task.FromResult(ProviderResult.Failure("FilePath is required."));

            if (!File.Exists(operation.Target.FilePath))
                return Task.FromResult(ProviderResult.Failure($"Script file not found: {operation.Target.FilePath}"));

            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> BackupAsync(PowerShellOperation operation, PlanContext context)
        {
            // We do not support automatic rollback for scripts yet
            return Task.FromResult(ProviderResult.Success());
        }

        public async Task<ProviderResult> ExecuteAsync(PowerShellOperation operation, PlanContext context)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                var args = string.Join(" ", operation.Target.Arguments ?? Array.Empty<string>());
                
                string executionPolicyArgs = "";
                if (operation.Intent != null && operation.Intent.BypassExecutionPolicy)
                {
                    executionPolicyArgs = "-ExecutionPolicy Bypass ";
                }

                psi.Arguments = $"-NoProfile -NonInteractive {executionPolicyArgs}-Command \"& '{operation.Target.FilePath}' {args} *>&1\"";

                using var process = new Process { StartInfo = psi };
                var outputBuilder = new System.Text.StringBuilder();
                var errorBuilder = new System.Text.StringBuilder();

                process.OutputDataReceived += (sender, e) =>
                {
                    if (e.Data != null)
                    {
                        outputBuilder.AppendLine(e.Data);
                        context.Logger?.LogInfo(e.Data, "PowerShell");
                    }
                };

                process.ErrorDataReceived += (sender, e) =>
                {
                    if (e.Data != null)
                    {
                        errorBuilder.AppendLine(e.Data);
                        context.Logger?.LogWarning(e.Data, "PowerShell");
                    }
                };

                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                await process.WaitForExitAsync(context.CancellationToken);

                string output = outputBuilder.ToString();
                string error = errorBuilder.ToString();

                if (process.ExitCode != 0)
                {
                    return ProviderResult.Failure($"Script failed with exit code {process.ExitCode}.\nError: {error}\nOutput: {output}");
                }

                return ProviderResult.Success(output);
            }
            catch (Exception ex)
            {
                return ProviderResult.Failure($"Exception executing script: {ex.Message}");
            }
        }

        public Task<ProviderResult> VerifyAsync(PowerShellOperation operation, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> RevertAsync(PowerShellOperation operation, string undoData, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Failure("Revert not supported for PowerShell scripts."));
        }
    }
}
