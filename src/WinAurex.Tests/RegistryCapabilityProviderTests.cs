using System;
using System.Threading.Tasks;
using Xunit;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution.Operations;
using WinAurex.Models.Execution;
using WinAurex.Infrastructure.Providers;
using Microsoft.Win32;
using MicrosoftRegistryValueKind = Microsoft.Win32.RegistryValueKind;
using WinAurexValueKind = WinAurex.Models.Execution.Operations.RegistryValueKind;

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
                    ValueKind: WinAurexValueKind.DWord
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

        [Fact]
        public async Task MultiString_RoundTripsThroughBackupExecuteVerifyRevert()
        {
            var keyPath = CreateTestKeyPath();
            var provider = new RegistryCapabilityProvider();
            var context = CreateContext();
            var operation = CreateArrayOperation(
                keyPath,
                "Multi",
                new[] { "alpha", "beta" },
                WinAurexValueKind.MultiString);

            try
            {
                using (var seed = Registry.CurrentUser.CreateSubKey(keyPath))
                {
                    seed!.SetValue("Multi", new[] { "old-one", "old-two" }, MicrosoftRegistryValueKind.MultiString);
                }

                var backup = await provider.BackupAsync(operation, context);
                Assert.True(backup.IsSuccess);

                var execute = await provider.ExecuteAsync(operation, context);
                Assert.True(execute.IsSuccess);

                var verify = await provider.VerifyAsync(operation, context);
                Assert.True(verify.IsSuccess);

                var revert = await provider.RevertAsync(operation, backup.UndoData, context);
                Assert.True(revert.IsSuccess);

                using var key = Registry.CurrentUser.OpenSubKey(keyPath);
                Assert.Equal(new[] { "old-one", "old-two" }, (string[]?)key!.GetValue("Multi"));
            }
            finally
            {
                Registry.CurrentUser.DeleteSubKeyTree(keyPath, throwOnMissingSubKey: false);
            }
        }

        [Fact]
        public async Task Binary_RoundTripsThroughBackupExecuteVerifyRevert()
        {
            var keyPath = CreateTestKeyPath();
            var provider = new RegistryCapabilityProvider();
            var context = CreateContext();
            var operation = CreateArrayOperation(
                keyPath,
                "Binary",
                new byte[] { 1, 2, 3 },
                WinAurexValueKind.Binary);

            try
            {
                using (var seed = Registry.CurrentUser.CreateSubKey(keyPath))
                {
                    seed!.SetValue("Binary", new byte[] { 9, 9 }, MicrosoftRegistryValueKind.Binary);
                }

                var backup = await provider.BackupAsync(operation, context);
                Assert.True(backup.IsSuccess);

                var execute = await provider.ExecuteAsync(operation, context);
                Assert.True(execute.IsSuccess);

                var verify = await provider.VerifyAsync(operation, context);
                Assert.True(verify.IsSuccess);

                var revert = await provider.RevertAsync(operation, backup.UndoData, context);
                Assert.True(revert.IsSuccess);

                using var key = Registry.CurrentUser.OpenSubKey(keyPath);
                Assert.Equal(new byte[] { 9, 9 }, (byte[]?)key!.GetValue("Binary"));
            }
            finally
            {
                Registry.CurrentUser.DeleteSubKeyTree(keyPath, throwOnMissingSubKey: false);
            }
        }

        [Fact]
        public async Task Verify_RejectsDifferingArrayValues()
        {
            var keyPath = CreateTestKeyPath();
            var provider = new RegistryCapabilityProvider();
            var context = CreateContext();

            try
            {
                var multiOperation = CreateArrayOperation(
                    keyPath,
                    "Multi",
                    new[] { "alpha", "beta" },
                    WinAurexValueKind.MultiString);
                var binaryOperation = CreateArrayOperation(
                    keyPath,
                    "Binary",
                    new byte[] { 1, 2, 3 },
                    WinAurexValueKind.Binary);

                using (var seed = Registry.CurrentUser.CreateSubKey(keyPath))
                {
                    seed!.SetValue("Multi", new[] { "alpha", "gamma" }, MicrosoftRegistryValueKind.MultiString);
                    seed.SetValue("Binary", new byte[] { 1, 2, 4 }, MicrosoftRegistryValueKind.Binary);
                }

                Assert.False((await provider.VerifyAsync(multiOperation, context)).IsSuccess);
                Assert.False((await provider.VerifyAsync(binaryOperation, context)).IsSuccess);
            }
            finally
            {
                Registry.CurrentUser.DeleteSubKeyTree(keyPath, throwOnMissingSubKey: false);
            }
        }

        private static string CreateTestKeyPath() =>
            @"Software\WinAurexTest\ValueKinds_" + Guid.NewGuid().ToString("N").Substring(0, 8);

        private static PlanContext CreateContext() =>
            new(Guid.NewGuid(), false, default, "TestUser", false, "en-US", "C:\\", null!);

        private static RegistryOperation CreateArrayOperation(
            string keyPath,
            string valueName,
            object value,
            WinAurexValueKind kind) =>
            new(new OperationId("Registry.value-kind-test"))
            {
                Target = new RegistryTarget(
                    Hive: WinAurex.Models.Execution.Operations.RegistryHive.CurrentUser,
                    KeyPath: keyPath,
                    ValueName: valueName),
                Intent = new SetRegistryValueIntent(Value: value, ValueKind: kind)
            };
    }
}
