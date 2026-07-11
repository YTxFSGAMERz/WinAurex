namespace WinAurex.Contracts
{
    public enum AppTheme
    {
        Light,
        Dark,
        Default
    }

    public enum BackdropType
    {
        Mica,
        Acrylic,
        None
    }

    public interface IAppearanceManager
    {
        AppTheme CurrentTheme { get; }
        BackdropType CurrentBackdrop { get; }

        void SetTheme(AppTheme theme);
        void SetBackdrop(BackdropType backdrop);
        void SetAccentColor(string hexColor);
    }
}
