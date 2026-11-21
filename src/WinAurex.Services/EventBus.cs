using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Diagnostics;
using WinAurex.Contracts;

namespace WinAurex.Services
{
    public class EventBus : IEventBus
    {
        private readonly ConcurrentDictionary<Type, ImmutableArray<Delegate>> _handlers = new();
        private readonly Action<Exception>? _onHandlerError;

        public EventBus()
            : this(null)
        {
        }

        public EventBus(Action<Exception>? onHandlerError)
        {
            _onHandlerError = onHandlerError;
        }

        public void Publish<TEvent>(TEvent @event)
        {
            if (!_handlers.TryGetValue(typeof(TEvent), out var handlers))
            {
                return;
            }

            // The snapshot is immutable, so it cannot be mutated while in use.
            foreach (var handler in handlers)
            {
                if (handler is not Action<TEvent> typedHandler)
                {
                    continue;
                }

                try
                {
                    typedHandler(@event);
                }
                catch (Exception ex)
                {
                    ReportHandlerError(ex);
                }
            }
        }

        public void Subscribe<TEvent>(Action<TEvent> handler)
        {
            if (handler is null)
            {
                throw new ArgumentNullException(nameof(handler));
            }

            _handlers.AddOrUpdate(
                typeof(TEvent),
                _ => ImmutableArray.Create<Delegate>(handler),
                (_, existing) => existing.Contains(handler) ? existing : existing.Add(handler));
        }

        public void Unsubscribe<TEvent>(Action<TEvent> handler)
        {
            if (handler is null)
            {
                throw new ArgumentNullException(nameof(handler));
            }

            var eventType = typeof(TEvent);
            while (_handlers.TryGetValue(eventType, out var existing))
            {
                var updated = existing.Remove(handler);
                if (updated == existing)
                {
                    // The handler was never subscribed.
                    return;
                }

                if (!updated.IsEmpty)
                {
                    if (_handlers.TryUpdate(eventType, updated, existing))
                    {
                        return;
                    }

                    continue;
                }

                // Drop the bucket atomically, but only if nobody re-subscribed meanwhile.
                if (((ICollection<KeyValuePair<Type, ImmutableArray<Delegate>>>)_handlers)
                    .Remove(new KeyValuePair<Type, ImmutableArray<Delegate>>(eventType, existing)))
                {
                    return;
                }
            }
        }

        private void ReportHandlerError(Exception exception)
        {
            var onError = _onHandlerError;
            if (onError is null)
            {
                Trace.WriteLine($"[EventBus] Subscriber failed: {exception}");
                return;
            }

            try
            {
                onError(exception);
            }
            catch (Exception reportingFailure)
            {
                Trace.WriteLine($"[EventBus] Error callback failed: {reportingFailure}");
            }
        }
    }
}
