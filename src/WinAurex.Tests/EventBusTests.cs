using System;
using System.Collections.Generic;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Services;
using Xunit;

namespace WinAurex.Tests
{
    public class EventBusTests
    {
        [Fact]
        public void ThrowingHandler_DoesNotBlockLaterHandlers_AndIsReported()
        {
            var reported = new List<Exception>();
            var bus = new EventBus(ex =>
            {
                lock (reported)
                {
                    reported.Add(ex);
                }
            });
            var delivered = 0;

            bus.Subscribe<string>(_ => throw new InvalidOperationException("ui handler failed"));
            bus.Subscribe<string>(_ => Interlocked.Increment(ref delivered));

            bus.Publish("progress");

            Assert.Equal(1, Volatile.Read(ref delivered));
            var error = Assert.Single(reported);
            Assert.IsType<InvalidOperationException>(error);
        }

        [Fact]
        public void ThrowingHandler_WithoutErrorCallback_IsSwallowedSilently()
        {
            var bus = new EventBus();
            var delivered = 0;

            bus.Subscribe<int>(_ => throw new ApplicationException("boom"));
            bus.Subscribe<int>(_ => Interlocked.Increment(ref delivered));

            bus.Publish(1);

            Assert.Equal(1, Volatile.Read(ref delivered));
        }

        [Fact]
        public async Task ConcurrentSubscribeAndPublish_IsSafeAndDeliversToEveryHandler()
        {
            var bus = new EventBus();
            var counters = new int[64];

            await Task.WhenAll(
                Task.Run(() => Parallel.For(0, counters.Length, i =>
                    bus.Subscribe<int>(_ => Interlocked.Increment(ref counters[i])))),
                Task.Run(() => Parallel.For(0, 200, i => bus.Publish(i))));

            var before = counters.Sum();
            bus.Publish(0);

            // Every handler from the concurrent phase must survive into the final snapshot.
            Assert.Equal(before + counters.Length, counters.Sum());
        }

        [Fact]
        public void DuplicateSubscribe_FiresOnce_AndUnsubscribeDropsTheBucket()
        {
            var bus = new EventBus();
            var hits = 0;
            Action<int> handler = _ => hits++;

            bus.Subscribe(handler);
            bus.Subscribe(handler);
            bus.Publish(1);
            Assert.Equal(1, hits);

            bus.Unsubscribe(handler);
            bus.Publish(2);
            Assert.Equal(1, hits);

            Assert.Equal(0, GetBucketCount(bus));
        }

        [Fact]
        public void UnsubscribeOfUnknownHandler_IsANoOp()
        {
            var bus = new EventBus();
            var hits = 0;
            Action<int> subscribed = _ => hits++;
            Action<int> neverSubscribed = _ => hits += 100;

            bus.Subscribe(subscribed);
            bus.Unsubscribe(neverSubscribed);
            bus.Publish(1);

            Assert.Equal(1, hits);
            Assert.Equal(1, GetBucketCount(bus));
        }

        [Fact]
        public void NullHandler_IsRejected()
        {
            var bus = new EventBus();

            Assert.Throws<ArgumentNullException>(() => bus.Subscribe<string>(null!));
            Assert.Throws<ArgumentNullException>(() => bus.Unsubscribe<string>(null!));
        }

        private static int GetBucketCount(EventBus bus)
        {
            var field = typeof(EventBus).GetField("_handlers", BindingFlags.NonPublic | BindingFlags.Instance);
            Assert.NotNull(field);
            var dictionary = field!.GetValue(bus);
            Assert.NotNull(dictionary);
            var count = dictionary!.GetType().GetProperty("Count")!.GetValue(dictionary);
            return (int)count!;
        }
    }
}
