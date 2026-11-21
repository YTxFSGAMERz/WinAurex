using System;
using System.Threading.Tasks;
using WinAurex.Contracts;
using WinAurex.Contracts.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Services;
using Xunit;

namespace WinAurex.Tests
{
    public class ActionServiceTests
    {
        [Fact]
        public async Task PreviewAsync_RunsThePlanAsADryRunAndLeavesStateUntouched()
        {
            var engine = new StubEngine(isSuccess: true);
            var stateService = new StubStateService();
            var service = new ActionService(engine, stateService, new StubLogger());

            var result = await service.PreviewAsync(CreateAction(withPlan: true));

            Assert.Equal(1, engine.Calls);
            Assert.True(engine.LastContext!.IsDryRun);
            Assert.Equal(0, stateService.SetCalls);
            Assert.Equal(ActionStatus.NotApplied, result.Status);
            Assert.Contains("No changes were made", result.Message);
        }

        [Fact]
        public async Task PreviewAsync_WithProblemsInThePlan_ReturnsFailure()
        {
            var engine = new StubEngine(isSuccess: false);
            var stateService = new StubStateService();
            var service = new ActionService(engine, stateService, new StubLogger());

            var result = await service.PreviewAsync(CreateAction(withPlan: true));

            Assert.Equal(1, engine.Calls);
            Assert.True(engine.LastContext!.IsDryRun);
            Assert.Equal(0, stateService.SetCalls);
            Assert.Equal(ActionStatus.Failed, result.Status);
        }

        [Fact]
        public async Task PreviewAsync_WithoutAPlan_ReturnsFailureWithoutExecuting()
        {
            var engine = new StubEngine(isSuccess: true);
            var stateService = new StubStateService();
            var service = new ActionService(engine, stateService, new StubLogger());

            var result = await service.PreviewAsync(CreateAction(withPlan: false));

            Assert.Equal(0, engine.Calls);
            Assert.Equal(0, stateService.SetCalls);
            Assert.Equal(ActionStatus.Failed, result.Status);
            Assert.Contains("No execution plan found.", result.Message);
        }

        [Fact]
        public async Task ApplyAsync_StillRunsNormallyAndUpdatesState()
        {
            var engine = new StubEngine(isSuccess: true);
            var stateService = new StubStateService();
            var service = new ActionService(engine, stateService, new StubLogger());

            var result = await service.ApplyAsync(CreateAction(withPlan: true));

            Assert.Equal(1, engine.Calls);
            Assert.False(engine.LastContext!.IsDryRun);
            Assert.Equal(1, stateService.SetCalls);
            Assert.Equal(ActionStatus.Applied, result.Status);
        }

        private static SystemAction CreateAction(bool withPlan)
        {
            var action = new SystemAction { Id = "test.action" };
            if (withPlan)
            {
                action.AvailableMethods.Add(new ActionExecutionMethod
                {
                    Name = "Default",
                    ExecutionPlan = new ExecutionPlan { Name = "Test Plan" }
                });
                action.SelectedMethod = action.AvailableMethods[0];
            }

            return action;
        }

        public sealed class StubEngine : IExecutionEngine
        {
            private readonly bool _isSuccess;

            public StubEngine(bool isSuccess)
            {
                _isSuccess = isSuccess;
            }

            public int Calls { get; private set; }
            public PlanContext? LastContext { get; private set; }

            public Task<ExecutionJournal> ExecutePlanAsync(ExecutionPlan plan, PlanContext context)
            {
                Calls++;
                LastContext = context;

                var journal = new ExecutionJournal { ExecutionId = context.ExecutionId };
                journal.Events.Add(new ExecutionStartedEntry { PlanName = plan.Name });
                journal.Events.Add(new ExecutionCompletedEntry { IsSuccess = _isSuccess });
                return Task.FromResult(journal);
            }
        }

        public sealed class StubStateService : IStateService
        {
            public int SetCalls { get; private set; }

            public Task<bool> IsActionAppliedAsync(SystemAction action) => Task.FromResult(false);

            public Task SetActionStateAsync(SystemAction action, bool isApplied)
            {
                SetCalls++;
                return Task.CompletedTask;
            }
        }

        public sealed class StubLogger : ILogContract
        {
            public void LogInfo(string message, string category = "General")
            {
            }

            public void LogWarning(string message, string category = "General")
            {
            }

            public void LogError(string message, Exception? ex = null, string category = "General")
            {
            }

            public void LogAction(string actionId, string result, string details)
            {
            }
        }
    }
}
