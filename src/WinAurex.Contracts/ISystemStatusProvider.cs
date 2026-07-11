namespace WinAurex.Contracts
{
    public interface ISystemStatusProvider
    {
        string GetWindowsVersion();
        string GetHealthStatus();
    }
}
