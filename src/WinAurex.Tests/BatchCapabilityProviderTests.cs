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
    public class BatchCapabilityProviderTests
    {
        [Fact]
        public async Task ExecuteAsync_PreservesSpacedAndMetaArguments_AndUsesScriptDirectory()
        {
            var directory = Path.Combine(Path.GetTempPath(), "WinAurexBatchTests", Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(directory);

            try
            {
                var scriptPath = Path.Combine(directory, "args.cmd");
                File.WriteAllText(scriptPath, string.Join("\r\n",
                    "@echo off",
                    "setlocal EnableDelayedExpansion",
                    "set \"ARG1=%~1\"",
                    "set \"ARG2=%~2\"",
                    "set \"ARG3=%~3\"",
                    "echo ARG1=[!ARG1!]",
                    "echo ARG2=[!ARG2!]",
                    "echo ARG3=[!ARG3!]",
                    "echo CWD=[%CD%]"));

                var operation = new BatchOperation(new OperationId("BatchExecutor.args-test"))
                {
                    Description = "Argument round trip",
                    Target = new ScriptTarget(scriptPath, new[] { "hello world", "second", "a&b" }),
                    Intent = new BatchIntent()
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

                var result = await new BatchCapabilityProvider().ExecuteAsync(operation, context);

                Assert.True(result.IsSuccess, result.ErrorMessage);
                Assert.Contains("ARG1=[hello world]", result.UndoData);
                Assert.Contains("ARG2=[second]", result.UndoData);
                Assert.Contains("ARG3=[a&b]", result.UndoData);
                Assert.Contains($"CWD=[{directory}]", result.UndoData, StringComparison.OrdinalIgnoreCase);
            }
            finally
            {
                try
                {
                    Directory.Delete(directory, recursive: true);
                }
                catch
                {
                    // Best-effort cleanup.
                }
            }
        }
    }
}
