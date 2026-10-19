using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Win32;
using MicrosoftRegistryValueKind = Microsoft.Win32.RegistryValueKind;
using WinAurex.Core.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public sealed class SystemStateAnalyzerTests : IDisposable
    {
        private readonly string _root = Path.Combine(Path.GetTempPath(), "WinAurexTests", Guid.NewGuid().ToString("N"));
        private readonly string _keyPrefix = @"Software\WinAurexTest\RegFileCheck_" + Guid.NewGuid().ToString("N").Substring(0, 8);
        private readonly SystemStateAnalyzer _analyzer = new();

        public SystemStateAnalyzerTests()
        {
            Directory.CreateDirectory(_root);
        }

        public void Dispose()
        {
            try
            {
                Registry.CurrentUser.DeleteSubKeyTree(_keyPrefix, throwOnMissingSubKey: false);
            }
            catch
            {
            }

            try
            {
                if (Directory.Exists(_root))
                {
                    Directory.Delete(_root, recursive: true);
                }
            }
            catch (IOException)
            {
            }
        }

        [Fact]
        public async Task AllValuesMatch_ReturnsTrue()
        {
            using (var key = Registry.CurrentUser.CreateSubKey(_keyPrefix + @"\Case1"))
            {
                key!.SetValue("Alpha", "one");
                key.SetValue("Beta", 42, MicrosoftRegistryValueKind.DWord);
            }

            var regFile = WriteRegFile($$"""
            Windows Registry Editor Version 5.00

            [HKEY_CURRENT_USER\{{_keyPrefix}}\Case1]
            "Alpha"="one"
            "Beta"=dword:0000002a
            """);

            Assert.True(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));
        }

        [Fact]
        public async Task FirstValueMatches_LaterValueDiffers_ReturnsFalse()
        {
            using (var key = Registry.CurrentUser.CreateSubKey(_keyPrefix + @"\Case2"))
            {
                key!.SetValue("Alpha", "one");
                key.SetValue("Beta", 42, MicrosoftRegistryValueKind.DWord);
            }

            var regFile = WriteRegFile($$"""
            Windows Registry Editor Version 5.00

            [HKEY_CURRENT_USER\{{_keyPrefix}}\Case2]
            "Alpha"="one"
            "Beta"=dword:00000063
            """);

            Assert.False(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));
        }

        [Fact]
        public async Task MissingValue_ReturnsFalse()
        {
            using (var key = Registry.CurrentUser.CreateSubKey(_keyPrefix + @"\Case3"))
            {
                key!.SetValue("Alpha", "one");
            }

            var regFile = WriteRegFile($$"""
            Windows Registry Editor Version 5.00

            [HKEY_CURRENT_USER\{{_keyPrefix}}\Case3]
            "Alpha"="one"
            "Gamma"="missing"
            """);

            Assert.False(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));
        }

        [Fact]
        public async Task DefaultValue_Matches_ReturnsTrue()
        {
            using (var key = Registry.CurrentUser.CreateSubKey(_keyPrefix + @"\Case4"))
            {
                key!.SetValue(string.Empty, "default-text");
            }

            var regFile = WriteRegFile($$"""
            Windows Registry Editor Version 5.00

            [HKEY_CURRENT_USER\{{_keyPrefix}}\Case4]
            @="default-text"
            """);

            Assert.True(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));
        }

        [Fact]
        public async Task DeletionSection_RequiresKeyToBeAbsent()
        {
            var deletedPath = _keyPrefix + @"\Case5";
            using (var key = Registry.CurrentUser.CreateSubKey(deletedPath))
            {
                key!.SetValue("Something", 1, MicrosoftRegistryValueKind.DWord);
            }

            var regFile = WriteRegFile($$"""
            Windows Registry Editor Version 5.00

            [-HKEY_CURRENT_USER\{{deletedPath}}]
            """);

            Assert.False(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));

            Registry.CurrentUser.DeleteSubKeyTree(deletedPath, throwOnMissingSubKey: false);

            Assert.True(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));
        }

        [Fact]
        public async Task HexMultiString_Matches()
        {
            using (var key = Registry.CurrentUser.CreateSubKey(_keyPrefix + @"\Case6"))
            {
                key!.SetValue("List", new[] { "al" }, MicrosoftRegistryValueKind.MultiString);
            }

            var regFile = WriteRegFile($$"""
            Windows Registry Editor Version 5.00

            [HKEY_CURRENT_USER\{{_keyPrefix}}\Case6]
            "List"=hex(7):61,00,6c,00,00,00
            """);

            Assert.True(await _analyzer.IsActionAppliedAsync(CreateAction(regFile)));
        }

        private string WriteRegFile(string content)
        {
            var path = Path.Combine(_root, Guid.NewGuid().ToString("N") + ".reg");
            File.WriteAllText(path, content);
            return path;
        }

        private static SystemAction CreateAction(string regFilePath)
        {
            var operation = new RegFileOperation(new OperationId("RegFileExecutor.test"))
            {
                Target = new RegFileTarget(regFilePath),
                Intent = new RegFileIntent()
            };

            return new SystemAction
            {
                Id = "regfile.test",
                SelectedMethod = new ActionExecutionMethod
                {
                    Name = "Registry",
                    ExecutionPlan = new ExecutionPlan
                    {
                        Operations = ImmutableList.Create<ExecutionOperation>(operation)
                    }
                }
            };
        }
    }
}
