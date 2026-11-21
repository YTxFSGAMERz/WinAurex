using System;
using System.IO;
using System.Linq;
using WinAurex.Contracts;

namespace WinAurex.Services
{
    public class FileLogger : ILogContract
    {
        private readonly string _baseLogDirectory;
        private readonly object _lockObj = new object();

        public FileLogger()
            : this(null)
        {
        }

        public FileLogger(string? baseLogDirectory)
        {
            _baseLogDirectory = string.IsNullOrWhiteSpace(baseLogDirectory)
                ? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "WinAurex Logs")
                : Path.GetFullPath(baseLogDirectory);
        }

        private void WriteToFile(string category, string logLine)
        {
            try
            {
                lock (_lockObj)
                {
                    string categoryDir = Path.Combine(_baseLogDirectory, GetSafeCategory(category));
                    if (!Directory.Exists(categoryDir))
                    {
                        Directory.CreateDirectory(categoryDir);
                    }

                    string fileName = $"{DateTime.Now:yyyy-MM-dd}.log";
                    string filePath = Path.Combine(categoryDir, fileName);

                    File.AppendAllText(filePath, logLine + Environment.NewLine);
                    Console.WriteLine(logLine);
                }
            }
            catch
            {
                // Fallback or ignore if we absolutely cannot write to the log (e.g. permission issues)
                System.Diagnostics.Debug.WriteLine($"FAILED TO LOG: {logLine}");
            }
        }

        private static string GetSafeCategory(string category)
        {
            if (string.IsNullOrWhiteSpace(category))
            {
                return "General";
            }

            var sanitized = new string(category
                .Select(c => char.IsLetterOrDigit(c) || c == '-' || c == '_' || c == ' ' ? c : '_')
                .ToArray())
                .Trim(' ', '.', '_');

            return string.IsNullOrWhiteSpace(sanitized) ? "General" : sanitized;
        }

        public void LogInfo(string message, string category = "General")
        {
            string logLine = $"[{DateTime.Now:HH:mm:ss}] [INFO] {message}";
            WriteToFile(category, logLine);
        }

        public void LogWarning(string message, string category = "General")
        {
            string logLine = $"[{DateTime.Now:HH:mm:ss}] [WARN] {message}";
            WriteToFile(category, logLine);
        }

        public void LogError(string message, Exception? ex = null, string category = "General")
        {
            string logLine = $"[{DateTime.Now:HH:mm:ss}] [ERROR] {message}";
            if (ex != null)
            {
                logLine += $"{Environment.NewLine}{ex}";
            }
            WriteToFile(category, logLine);
        }

        public void LogAction(string actionId, string result, string details)
        {
            string logLine = $"[{DateTime.Now:HH:mm:ss}] [ACTION] [{actionId}] {result}: {details}";
            // Actions will be saved to the "Action" category folder by default.
            WriteToFile("Action", logLine);
        }
    }
}
