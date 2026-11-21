using System;
using System.Collections.Concurrent;
using System.IO;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Services;
using WinAurex.Models;
using WinAurex.Models.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public sealed class StateServiceTests : IDisposable
    {
        private readonly string _root = Path.Combine(Path.GetTempPath(), "WinAurexTests", Guid.NewGuid().ToString("N"));
        private readonly StubAnalyzer _analyzer = new();

        public StateServiceTests()
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
            catch (UnauthorizedAccessException)
            {
            }
        }

        [Fact]
        public async Task SetThenRead_RoundTripsThroughCacheAndDisk()
        {
            var service = new StateService(_analyzer, _root);
            var action = new SystemAction { Id = "tweak.one" };

            Assert.False(await service.IsActionAppliedAsync(action));

            await service.SetActionStateAsync(action, true);

            Assert.True(await service.IsActionAppliedAsync(action));
            Assert.True(action.IsApplied);

            var reloaded = new StateService(_analyzer, _root);
            Assert.True(await reloaded.IsActionAppliedAsync(action));
        }

        [Fact]
        public async Task AnalyzerResult_WinsOverCache_ButCacheIsUsedAfterwards()
        {
            var service = new StateService(_analyzer, _root);
            var action = new SystemAction
            {
                Id = "tweak.two",
                Detection = new FileDetectionRule { Path = @"C:\definitely-not-here.txt" }
            };

            _analyzer.Result = _ => true;
            Assert.True(await service.IsActionAppliedAsync(action));

            _analyzer.Result = _ => false;
            Assert.False(await service.IsActionAppliedAsync(action));

            await service.SetActionStateAsync(action, true);
            Assert.True(await service.IsActionAppliedAsync(action));
        }

        [Fact]
        public async Task ConcurrentReadsAndWrites_DoNotThrow()
        {
            var service = new StateService(_analyzer, _root);
            var actions = new SystemAction[100];
            for (var i = 0; i < actions.Length; i++)
            {
                actions[i] = new SystemAction { Id = $"tweak.{i}" };
            }

            await Task.Run(() => Parallel.For(0, actions.Length, i =>
                service.SetActionStateAsync(actions[i], i % 2 == 0).GetAwaiter().GetResult()));

            var mismatches = new ConcurrentBag<int>();
            await Task.Run(() => Parallel.For(0, actions.Length, i =>
            {
                var applied = service.IsActionAppliedAsync(actions[i]).GetAwaiter().GetResult();
                if (applied != (i % 2 == 0))
                {
                    mismatches.Add(i);
                }
            }));

            Assert.Empty(mismatches);
        }

        [Fact]
        public async Task CorruptCacheFile_DegradesToEmptyCache()
        {
            await File.WriteAllTextAsync(Path.Combine(_root, "applied_tweaks.json"), "{ this is not json");

            var service = new StateService(_analyzer, _root);

            Assert.False(await service.IsActionAppliedAsync(new SystemAction { Id = "tweak.three" }));
        }

        [Fact]
        public async Task Save_LeavesNoTempFileBehind()
        {
            var service = new StateService(_analyzer, _root);

            await service.SetActionStateAsync(new SystemAction { Id = "tweak.four" }, true);

            Assert.True(File.Exists(Path.Combine(_root, "applied_tweaks.json")));
            Assert.Empty(Directory.GetFiles(_root, "*.tmp"));
        }

        [Fact]
        public async Task NullArguments_AreRejected()
        {
            var service = new StateService(_analyzer, _root);

            await Assert.ThrowsAsync<ArgumentNullException>(() => service.IsActionAppliedAsync(null!));
            await Assert.ThrowsAsync<ArgumentNullException>(() => service.SetActionStateAsync(null!, true));
            Assert.Throws<ArgumentNullException>(() => new StateService(null!, _root));
            Assert.Throws<ArgumentException>(() => new StateService(_analyzer, " "));
        }

        private sealed class StubAnalyzer : ISystemStateAnalyzer
        {
            public Func<SystemAction, bool> Result { get; set; } = _ => false;

            public Task<bool> IsActionAppliedAsync(SystemAction action) => Task.FromResult(Result(action));
        }
    }
}
