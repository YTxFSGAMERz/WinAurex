using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
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

                var args = BuildArguments(operation.Target.Arguments ?? Array.Empty<string>());

                psi.Arguments = $"/d /s /c \"\"{operation.Target.FilePath}\" {args}\"";

                var scriptDirectory = Path.GetDirectoryName(Path.GetFullPath(operation.Target.FilePath));
                if (!string.IsNullOrWhiteSpace(scriptDirectory))
                {
                    psi.WorkingDirectory = scriptDirectory;
                }

                using var process = new Process { StartInfo = psi };
                var outputBuilder = new System.Text.StringBuilder();
                var errorBuilder = new System.Text.StringBuilder();

                process.OutputDataReceived += (sender, e) =>
                {
                    if (e.Data != null)
                    {
                        outputBuilder.AppendLine(e.Data);
                        context.Logger?.LogInfo(e.Data, "Batch");
                    }
                };

                process.ErrorDataReceived += (sender, e) =>
                {
                    if (e.Data != null)
                    {
                        errorBuilder.AppendLine(e.Data);
                        context.Logger?.LogWarning(e.Data, "Batch");
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

        private static string BuildArguments(IReadOnlyList<string> arguments)
        {
            if (arguments.Count == 0)
            {
                return string.Empty;
            }

            return string.Join(" ", arguments.Select(QuoteArgument));
        }

        private static string QuoteArgument(string? argument)
        {
            // cmd.exe expands metacharacters unless the value is quoted. Every argument
            // is wrapped so spaces and characters such as &, |, < and > stay literal.
            var value = argument ?? string.Empty;
            return $"\"{value.Replace("\"", "\"\"")}\"";
        }

        public Task<ProviderResult> RevertAsync(BatchOperation operation, string undoData, PlanContext context)
        {
            return Task.FromResult(ProviderResult.Failure("Revert not supported for batch scripts."));
        }
    }
}
