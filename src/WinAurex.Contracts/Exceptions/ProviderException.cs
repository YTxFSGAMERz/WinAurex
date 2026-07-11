using System;

namespace WinAurex.Contracts.Exceptions
{
    /// <summary>
    /// Thrown when an operation fails to execute within the capability provider itself.
    /// </summary>
    public class ProviderException : WinAurexException
    {
        public ProviderException(string message) : base(message)
        {
        }

        public ProviderException(string message, Exception innerException) : base(message, innerException)
        {
        }
    }
}
