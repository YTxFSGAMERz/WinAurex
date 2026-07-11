using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;

namespace WinAurex.Infrastructure.Providers
{
    public class RegFileCapabilityProvider : ICapabilityProvider<RegFileOperation>
    {
        public ProviderMetadata Metadata { get; } = new ProviderMetadata(
            Id: "RegFileExecutor",
            Name: "RegFileExecutor",
            Version: "1.0",
            SupportsRollback: false,
            SupportsDryRun: false,
            RequiresElevation: true,
            MaxRiskLevel: WinAurex.Models.RiskLevel.Advanced
        );

        public Task<ProviderResult> AnalyzeAsync(RegFileOperation operation, PlanContext context)
        {
            if (operation.Target == null || string.IsNullOrWhiteSpace(operation.Target.FilePath))
                return Task.FromResult(ProviderResult.Failure("FilePath is required."));

            if (!File.Exists(operation.Target.FilePath))
                return Task.FromResult(ProviderResult.Failure($"Reg file not found: {operation.Target.FilePath}"));

            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> BackupAsync(RegFileOperation operation, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Success());
        }

        public async Task<ProviderResult> ExecuteAsync(RegFileOperation operation, PlanContext context)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "reg.exe",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    Arguments = $"import \"{operation.Target.FilePath}\""
                };

                using var process = new Process { StartInfo = psi };
                process.Start();

                var outputTask = process.StandardOutput.ReadToEndAsync();
                var errorTask = process.StandardError.ReadToEndAsync();

                await process.WaitForExitAsync(context.CancellationToken);

                string output = await outputTask;
                string error = await errorTask;

                if (process.ExitCode != 0)
                {
                    return ProviderResult.Failure($"Reg import failed with exit code {process.ExitCode}.\nError: {error}\nOutput: {output}");
                }

                return ProviderResult.Success(output);
            }
            catch (Exception ex)
            {
                return ProviderResult.Failure($"Exception executing reg import: {ex.Message}");
            }
        }

        public Task<ProviderResult> VerifyAsync(RegFileOperation operation, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> RevertAsync(RegFileOperation operation, string undoData, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Failure("Revert not supported for Reg files."));
        }
    }
}
