namespace WinAurex.Contracts
{
    public interface INavigationService
    {
        bool NavigateTo(NavigationRoute route, object? parameter = null);
        bool GoBack();
    }
}
