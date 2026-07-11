using System;
using System.Collections.Generic;

namespace WinAurex.Contracts
{
    public interface INavigationHistory
    {
        IReadOnlyList<NavigationRoute> Breadcrumbs { get; }
        event EventHandler<IReadOnlyList<NavigationRoute>>? HistoryChanged;
    }
}
