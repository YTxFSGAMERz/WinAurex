using System;

namespace WinAurex.Contracts.Exceptions
{
    /// <summary>
    /// Thrown when the environment lacks the necessary privileges (e.g. running non-elevated for a registry tweak).
    /// </summary>
    public class AuthorizationException : WinAurexException
    {
        public AuthorizationException(string message) : base(message)
        {
        }

        public AuthorizationException(string message, Exception innerException) : base(message, innerException)
        {
        }
    }
}
