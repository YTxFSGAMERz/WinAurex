using System;
using WinAurex.Contracts;

namespace WinAurex.Infrastructure
{
    public class SystemStatusProvider : ISystemStatusProvider
    {
        public string GetWindowsVersion()
        {
            // Placeholder: Environment.OSVersion or ManagementObjectSearcher
            return Environment.OSVersion.VersionString;
        }

        public string GetHealthStatus()
        {
            return "Healthy";
        }
    }
}
