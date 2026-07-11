using System;

namespace WinAurex.Contracts
{
    public interface ILogContract
    {
        void LogInfo(string message, string category = "General");
        void LogWarning(string message, string category = "General");
        void LogError(string message, Exception? ex = null, string category = "General");
        void LogAction(string actionId, string result, string details);
    }
}
