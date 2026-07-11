using System;
using System.Threading.Tasks;
using Xunit;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution.Operations;
using WinAurex.Models.Execution;
using WinAurex.Infrastructure.Providers;
using Microsoft.Win32;

namespace WinAurex.Tests
{
    public class RegistryCapabilityProviderTests
    {
        [Fact]
        public async Task RegistryFlow_ExecuteAndRevert_Works()
        {
            var provider = new RegistryCapabilityProvider();
            
            var operation = new RegistryOperation(new OperationId("Registry.test-registry"))
            {
                Target = new RegistryTarget(
                    Hive: WinAurex.Models.Execution.Operations.RegistryHive.CurrentUser,
                    KeyPath: @"Software\WinAurexTest",
                    ValueName: "TestValue"
                ),
                Intent = new SetRegistryValueIntent(
                    Value: 12345,
                    ValueKind: WinAurex.Models.Execution.Operations.RegistryValueKind.DWord
                )
            };

            var context = new PlanContext(Guid.NewGuid(), false, default, "TestUser", false, "en-US", "C:\\", null!);

            // Analyze
            var analyzeResult = await provider.AnalyzeAsync(operation, context);
            Assert.True(analyzeResult.IsSuccess);

            // Backup
            var backupResult = await provider.BackupAsync(operation, context);
            Assert.True(backupResult.IsSuccess);

            // Execute
            var execResult = await provider.ExecuteAsync(operation, context);
            Assert.True(execResult.IsSuccess);

            // Verify
            var verifyResult = await provider.VerifyAsync(operation, context);
            Assert.True(verifyResult.IsSuccess);
            
            // Actually check the registry to be absolutely sure
            using (var key = Registry.CurrentUser.OpenSubKey(@"Software\WinAurexTest"))
            {
                Assert.NotNull(key);
                Assert.Equal(12345, key.GetValue("TestValue"));
            }

            // Revert
            var revertResult = await provider.RevertAsync(operation, backupResult.UndoData, context);
            Assert.True(revertResult.IsSuccess);

            // Verify revert
            using (var key = Registry.CurrentUser.OpenSubKey(@"Software\WinAurexTest"))
            {
                if (key != null)
                {
                    Assert.Null(key.GetValue("TestValue"));
                }
            }
        }
    }
}
