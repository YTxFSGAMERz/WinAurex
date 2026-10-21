using System;
using System.IO;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Infrastructure.Providers;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class PowerShellCapabilityProviderTests
    {
        [Fact]
        public async Task ExecuteAsync_HandlesApostrophePathSpacedArgumentsAndWorkingDirectory()
        {
            var root = Path.Combine(Path.GetTempPath(), "WinAurexPowerShellTests", Guid.NewGuid().ToString("N"));
            var directory = Path.Combine(root, "it's here");
            Directory.CreateDirectory(directory);

            try
            {
                var scriptPath = Path.Combine(directory, "probe.ps1");
                File.WriteAllText(scriptPath, string.Join(Environment.NewLine,
                    "Write-Output \"ARG1=$($args[0])\"",
                    "Write-Output \"ARG2=$($args[1])\"",
                    "Write-Output \"CWD=$PWD\""));

                var operation = new PowerShellOperation(new OperationId("PowerShellExecutor.args-test"))
                {
                    Description = "Argument round trip",
                    Target = new ScriptTarget(scriptPath, new[] { "hello world", "second" }),
                    Intent = new PowerShellIntent()
                };

                var context = new PlanContext(
                    Guid.NewGuid(),
                    isDryRun: false,
                    CancellationToken.None,
                    "tester",
                    isElevated: false,
                    "en-US",
                    directory,
                    logger: null!);

                var result = await new PowerShellCapabilityProvider().ExecuteAsync(operation, context);

                Assert.True(result.IsSuccess, result.ErrorMessage);
                Assert.Contains("ARG1=hello world", result.UndoData);
                Assert.Contains("ARG2=second", result.UndoData);
                Assert.Contains($"CWD={directory}", result.UndoData, StringComparison.OrdinalIgnoreCase);
            }
            finally
            {
                try
                {
                    Directory.Delete(root, recursive: true);
                }
                catch
                {
                    // Best-effort cleanup.
                }
            }
        }
    }
}
