using System;

namespace WinAurex.Contracts.Exceptions
{
    /// <summary>
    /// The base exception class for all custom WinAurex platform errors.
    /// </summary>
    public abstract class WinAurexException : Exception
    {
        protected WinAurexException(string message) : base(message)
        {
        }

        protected WinAurexException(string message, Exception innerException) : base(message, innerException)
        {
        }
    }
}
