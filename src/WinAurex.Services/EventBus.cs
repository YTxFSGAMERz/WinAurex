using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using WinAurex.Contracts;

namespace WinAurex.Services
{
    public class EventBus : IEventBus
    {
        private readonly ConcurrentDictionary<Type, List<Delegate>> _handlers = new();

        public void Publish<TEvent>(TEvent @event)
        {
            if (_handlers.TryGetValue(typeof(TEvent), out var handlers))
            {
                // Create a copy to iterate safely
                var handlersCopy = new List<Delegate>(handlers);
                foreach (var handler in handlersCopy)
                {
                    if (handler is Action<TEvent> typedHandler)
                    {
                        typedHandler(@event);
                    }
                }
            }
        }

        public void Subscribe<TEvent>(Action<TEvent> handler)
        {
            _handlers.AddOrUpdate(
                typeof(TEvent),
                _ => new List<Delegate> { handler },
                (_, existingHandlers) =>
                {
                    existingHandlers.Add(handler);
                    return existingHandlers;
                });
        }

        public void Unsubscribe<TEvent>(Action<TEvent> handler)
        {
            if (_handlers.TryGetValue(typeof(TEvent), out var handlers))
            {
                handlers.Remove(handler);
            }
        }
    }
}
