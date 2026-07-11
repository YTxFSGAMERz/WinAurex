using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;

namespace WinAurex.Infrastructure.Providers
{
    public class BatchCapabilityProvider : ICapabilityProvider<BatchOperation>
    {
        public ProviderMetadata Metadata { get; } = new ProviderMetadata(
            Id: "BatchExecutor",
            Name: "BatchExecutor",
            Version: "1.0",
            SupportsRollback: false,
            SupportsDryRun: false,
            RequiresElevation: true,
            MaxRiskLevel: WinAurex.Models.RiskLevel.Advanced
        );

        public Task<ProviderResult> AnalyzeAsync(BatchOperation operation, PlanContext context)
        {
            if (operation.Target == null || string.IsNullOrWhiteSpace(operation.Target.FilePath))
                return Task.FromResult(ProviderResult.Failure("FilePath is required."));

            if (!File.Exists(operation.Target.FilePath))
                return Task.FromResult(ProviderResult.Failure($"Script file not found: {operation.Target.FilePath}"));

            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> BackupAsync(BatchOperation operation, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Success());
        }

        public async Task<ProviderResult> ExecuteAsync(BatchOperation operation, PlanContext context)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                var args = string.Join(" ", operation.Target.Arguments ?? Array.Empty<string>());
                
                psi.Arguments = $"/c \"\"{operation.Target.FilePath}\" {args}\"";

                using var process = new Process { StartInfo = psi };
                process.Start();

                var outputTask = process.StandardOutput.ReadToEndAsync();
                var errorTask = process.StandardError.ReadToEndAsync();

                await process.WaitForExitAsync(context.CancellationToken);

                string output = await outputTask;
                string error = await errorTask;

                if (process.ExitCode != 0)
                {
                    return ProviderResult.Failure($"Batch script failed with exit code {process.ExitCode}.\nError: {error}\nOutput: {output}");
                }

                return ProviderResult.Success(output);
            }
            catch (Exception ex)
            {
                return ProviderResult.Failure($"Exception executing batch script: {ex.Message}");
            }
        }

        public Task<ProviderResult> VerifyAsync(BatchOperation operation, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Success());
        }

        public Task<ProviderResult> RevertAsync(BatchOperation operation, string undoData, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Failure("Revert not supported for batch scripts."));
        }
    }
}
