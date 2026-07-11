using System;

namespace WinAurex.Contracts
{
    public interface IEventBus
    {
        void Publish<TEvent>(TEvent @event);
        void Subscribe<TEvent>(Action<TEvent> handler);
        void Unsubscribe<TEvent>(Action<TEvent> handler);
    }
}
