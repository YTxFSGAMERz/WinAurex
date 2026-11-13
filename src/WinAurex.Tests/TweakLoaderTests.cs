using System;
using System.IO;
using System.Linq;
using WinAurex.Core.Profiles;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public sealed class TweakLoaderTests : IDisposable
    {
        private readonly string _root = Path.Combine(Path.GetTempPath(), "WinAurexTests", Guid.NewGuid().ToString("N"));

        public TweakLoaderTests()
        {
            Directory.CreateDirectory(_root);
        }

        public void Dispose()
        {
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
        public void ScriptPairWithReadme_ProducesOneMethodWithNonNullOperations()
        {
            var directory = CreateProfileDirectory("a");
            File.WriteAllText(Path.Combine(directory, "Disable_Thing.ps1"), "# apply");
            File.WriteAllText(Path.Combine(directory, "Enable_Thing.ps1"), "# revert");
            File.WriteAllText(Path.Combine(directory, "readme.md"), "# documentation");

            var actions = new TweakLoader().LoadTweaks(directory).ToList();

            var action = Assert.Single(actions);
            var method = Assert.Single(action.AvailableMethods);
            Assert.Equal("PowerShell", method.Name);

            var apply = Assert.IsType<PowerShellOperation>(Assert.Single(method.ExecutionPlan.Operations));
            Assert.Equal(Path.Combine(directory, "Disable_Thing.ps1"), apply.Target.FilePath);

            var revert = Assert.IsType<PowerShellOperation>(Assert.Single(method.RollbackPlan!.Operations));
            Assert.Equal(Path.Combine(directory, "Enable_Thing.ps1"), revert.Target.FilePath);
        }

        [Fact]
        public void UnsupportedFilesOnly_ProduceNoActions()
        {
            var directory = CreateProfileDirectory("b");
            File.WriteAllText(Path.Combine(directory, "apply_notes.txt"), "notes");
            File.WriteAllText(Path.Combine(directory, "screenshot.png"), "not really a png");

            var actions = new TweakLoader().LoadTweaks(directory).ToList();

            Assert.Empty(actions);
        }

        [Fact]
        public void MixedExtensions_ProduceOneMethodPerExtensionWithNonNullOperations()
        {
            var directory = CreateProfileDirectory("c");
            File.WriteAllText(Path.Combine(directory, "Disable_Alpha.ps1"), "# apply via script");
            File.WriteAllText(Path.Combine(directory, "Disable_Alpha.reg"), "Windows Registry Editor Version 5.00");

            var actions = new TweakLoader().LoadTweaks(directory).ToList();

            var action = Assert.Single(actions);
            Assert.Equal(2, action.AvailableMethods.Count);

            foreach (var method in action.AvailableMethods)
            {
                var operation = Assert.Single(method.ExecutionPlan.Operations);
                Assert.NotNull(operation);
            }
        }

        [Fact]
        public void InvalidArguments_AreRejected()
        {
            var loader = new TweakLoader();

            Assert.Throws<ArgumentNullException>(() => loader.LoadTweaks(null!));
            Assert.Throws<ArgumentException>(() => loader.LoadTweaks(" "));
            Assert.Empty(loader.LoadTweaks(Path.Combine(_root, "does-not-exist")));
        }

        private string CreateProfileDirectory(string name)
        {
            var directory = Path.Combine(_root, name);
            Directory.CreateDirectory(directory);
            return directory;
        }
    }
}
