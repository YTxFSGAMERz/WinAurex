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
    public class RegFileCapabilityProviderTests : IDisposable
    {
        private readonly string _directory;

        public RegFileCapabilityProviderTests()
        {
            _directory = Path.Combine(Path.GetTempPath(), "WinAurexRegFileTests", Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_directory);
        }

        [Fact]
        public async Task AnalyzeAsync_RejectsNonRegFile()
        {
            var path = CreateFile("probe.txt");
            var result = await CreateProvider().AnalyzeAsync(CreateOperation(path), CreateContext());

            Assert.False(result.IsSuccess);
            Assert.Contains(".reg", result.ErrorMessage);
        }

        [Fact]
        public async Task AnalyzeAsync_AcceptsUppercaseRegExtension()
        {
            var path = CreateFile("probe.REG");
            var result = await CreateProvider().AnalyzeAsync(CreateOperation(path), CreateContext());

            Assert.True(result.IsSuccess, result.ErrorMessage);
        }

        [Fact]
        public async Task AnalyzeAsync_RejectsMissingFile()
        {
            var path = Path.Combine(_directory, "missing.reg");
            var result = await CreateProvider().AnalyzeAsync(CreateOperation(path), CreateContext());

            Assert.False(result.IsSuccess);
            Assert.Contains("not found", result.ErrorMessage);
        }

        [Fact]
        public async Task ExecuteAsync_RejectsNonRegFileBeforeRunningRegExe()
        {
            var path = CreateFile("probe.txt");
            var result = await CreateProvider().ExecuteAsync(CreateOperation(path), CreateContext());

            Assert.False(result.IsSuccess);
            Assert.Contains(".reg", result.ErrorMessage);
        }

        private string CreateFile(string name)
        {
            var path = Path.Combine(_directory, name);
            File.WriteAllText(path, "not a registry file");
            return path;
        }

        private static RegFileCapabilityProvider CreateProvider() => new();

        private static RegFileOperation CreateOperation(string path)
        {
            return new RegFileOperation(new OperationId("RegFileExecutor.test"))
            {
                Description = "Reg file test",
                Target = new RegFileTarget(path),
                Intent = new RegFileIntent()
            };
        }

        private static PlanContext CreateContext()
        {
            return new PlanContext(
                Guid.NewGuid(),
                isDryRun: false,
                CancellationToken.None,
                "tester",
                isElevated: true,
                "en-US",
                Path.GetTempPath(),
                logger: null!);
        }

        public void Dispose()
        {
            try
            {
                Directory.Delete(_directory, recursive: true);
            }
            catch
            {
                // Best-effort cleanup.
            }
        }
    }
}
