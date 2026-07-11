using System;
using System.Diagnostics;
using WinAurex.Contracts;

namespace WinAurex.Services
{
    public class SimpleLogger : ILogContract
    {
        public void LogInfo(string message, string category = "General")
        {
            Debug.WriteLine($"[INFO] [{category}] {message}");
        }

        public void LogWarning(string message, string category = "General")
        {
            Debug.WriteLine($"[WARN] [{category}] {message}");
        }

        public void LogError(string message, Exception? ex = null, string category = "General")
        {
            Debug.WriteLine($"[ERROR] [{category}] {message}");
            if (ex != null)
            {
                Debug.WriteLine(ex.ToString());
            }
        }

        public void LogAction(string actionId, string result, string details)
        {
            Debug.WriteLine($"[ACTION] [{actionId}] {result}: {details}");
        }
    }
}
