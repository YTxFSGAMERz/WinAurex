using System;
using System.Threading.Tasks;
using WinAurex.Contracts.Execution;
using WinAurex.Core.Execution.Middleware;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;
using Xunit;

namespace WinAurex.Tests
{
    public class RetryMiddlewareTests
    {
        [Fact]
        public async Task NonePolicy_ExecutesOnceEvenWithMaxRetries()
        {
            var policy = new ExecutionPolicy { RetryPolicy = RetryPolicy.None, MaxRetries = 3 };
            var context = CreateContext();
            int calls = 0;

            await new RetryMiddleware().InvokeAsync(CreateOperation(policy), context, (op, ctx) =>
            {
                calls++;
                ctx.ExecutionResult = ProviderResult.Failure("should not retry");
                return Task.CompletedTask;
            });

            Assert.Equal(1, calls);
            Assert.False(context.ExecutionResult!.IsSuccess);
            Assert.Contains("should not retry", context.ExecutionResult.ErrorMessage);
        }

        [Fact]
        public async Task FixedPolicy_SucceedsOnThirdAttemptAndStops()
        {
            var policy = new ExecutionPolicy
            {
                RetryPolicy = RetryPolicy.Fixed,
                MaxRetries = 2,
                RetryDelay = TimeSpan.FromMilliseconds(1)
            };
            var context = CreateContext();
            int calls = 0;

            await new RetryMiddleware().InvokeAsync(CreateOperation(policy), context, (op, ctx) =>
            {
                calls++;
                ctx.ExecutionResult = calls < 3
                    ? ProviderResult.Failure($"attempt {calls}")
                    : ProviderResult.Success();
                return Task.CompletedTask;
            });

            Assert.Equal(3, calls);
            Assert.True(context.ExecutionResult!.IsSuccess);
        }

        [Fact]
        public async Task FixedPolicy_AfterExhaustingRetries_ReportsLastError()
        {
            var policy = new ExecutionPolicy
            {
                RetryPolicy = RetryPolicy.Fixed,
                MaxRetries = 2,
                RetryDelay = TimeSpan.FromMilliseconds(1)
            };
            var context = CreateContext();
            int calls = 0;

            await new RetryMiddleware().InvokeAsync(CreateOperation(policy), context, (op, ctx) =>
            {
                calls++;
                ctx.ExecutionResult = ProviderResult.Failure($"boom {calls}");
                return Task.CompletedTask;
            });

            Assert.Equal(3, calls);
            Assert.False(context.ExecutionResult!.IsSuccess);
            Assert.Contains("boom 3", context.ExecutionResult.ErrorMessage);
        }

        [Fact]
        public async Task NegativeMaxRetries_ExecutesSingleAttempt()
        {
            var policy = new ExecutionPolicy
            {
                RetryPolicy = RetryPolicy.Fixed,
                MaxRetries = -5,
                RetryDelay = TimeSpan.FromMilliseconds(1)
            };
            var context = CreateContext();
            int calls = 0;

            await new RetryMiddleware().InvokeAsync(CreateOperation(policy), context, (op, ctx) =>
            {
                calls++;
                ctx.ExecutionResult = ProviderResult.Failure("attempt failed");
                return Task.CompletedTask;
            });

            Assert.Equal(1, calls);
            Assert.False(context.ExecutionResult!.IsSuccess);
            Assert.Contains("attempt failed", context.ExecutionResult.ErrorMessage);
        }

        [Fact]
        public void GetMaxAttempts_MatchesStrategy()
        {
            Assert.Equal(1, RetryMiddleware.GetMaxAttempts(new ExecutionPolicy { RetryPolicy = RetryPolicy.None, MaxRetries = 10 }));
            Assert.Equal(4, RetryMiddleware.GetMaxAttempts(new ExecutionPolicy { RetryPolicy = RetryPolicy.Fixed, MaxRetries = 3 }));
            Assert.Equal(1, RetryMiddleware.GetMaxAttempts(new ExecutionPolicy { RetryPolicy = RetryPolicy.Fixed, MaxRetries = -3 }));
            Assert.Equal(6, RetryMiddleware.GetMaxAttempts(new ExecutionPolicy { RetryPolicy = RetryPolicy.ExponentialBackoff, MaxRetries = 5 }));
        }

        [Fact]
        public void ComputeRetryDelay_FixedIsConstant()
        {
            var policy = new ExecutionPolicy
            {
                RetryPolicy = RetryPolicy.Fixed,
                MaxRetries = 5,
                RetryDelay = TimeSpan.FromMilliseconds(250)
            };

            Assert.Equal(TimeSpan.FromMilliseconds(250), RetryMiddleware.ComputeRetryDelay(policy, 1));
            Assert.Equal(TimeSpan.FromMilliseconds(250), RetryMiddleware.ComputeRetryDelay(policy, 4));
        }

        [Fact]
        public void ComputeRetryDelay_ExponentialDoublesPerFailedAttempt()
        {
            var policy = new ExecutionPolicy
            {
                RetryPolicy = RetryPolicy.ExponentialBackoff,
                MaxRetries = 5,
                RetryDelay = TimeSpan.FromMilliseconds(100)
            };

            Assert.Equal(TimeSpan.FromMilliseconds(100), RetryMiddleware.ComputeRetryDelay(policy, 1));
            Assert.Equal(TimeSpan.FromMilliseconds(200), RetryMiddleware.ComputeRetryDelay(policy, 2));
            Assert.Equal(TimeSpan.FromMilliseconds(400), RetryMiddleware.ComputeRetryDelay(policy, 3));
        }

        [Fact]
        public void ComputeRetryDelay_ExponentialIsCappedAtMaxValue()
        {
            var policy = new ExecutionPolicy
            {
                RetryPolicy = RetryPolicy.ExponentialBackoff,
                MaxRetries = 100,
                RetryDelay = TimeSpan.FromDays(8000)
            };

            Assert.Equal(TimeSpan.MaxValue, RetryMiddleware.ComputeRetryDelay(policy, 60));
        }

        [Fact]
        public void ComputeRetryDelay_NoneOrMissingDelayIsZero()
        {
            Assert.Equal(TimeSpan.Zero, RetryMiddleware.ComputeRetryDelay(
                new ExecutionPolicy { RetryPolicy = RetryPolicy.None, RetryDelay = TimeSpan.FromSeconds(1) }, 1));
            Assert.Equal(TimeSpan.Zero, RetryMiddleware.ComputeRetryDelay(
                new ExecutionPolicy { RetryPolicy = RetryPolicy.Fixed }, 1));
        }

        private static RegistryOperation CreateOperation(ExecutionPolicy policy) =>
            new(new OperationId("Registry.retry-test"))
            {
                Target = new RegistryTarget(RegistryHive.CurrentUser, @"Software\WinAurexTest", "Value"),
                Intent = new SetRegistryValueIntent(1, RegistryValueKind.DWord),
                PolicyOverride = policy
            };

        private static OperationContext CreateContext() =>
            new(new PlanContext(Guid.NewGuid(), false, default, "tester", false, "en-US", "C:\\", null!))
            {
                Journal = new ExecutionJournal { ExecutionId = Guid.NewGuid() }
            };
    }
}
