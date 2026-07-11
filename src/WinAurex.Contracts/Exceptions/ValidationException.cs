using System;

namespace WinAurex.Contracts.Exceptions
{
    /// <summary>
    /// Thrown when an execution plan or operation fails logical validation before execution begins.
    /// </summary>
    public class ValidationException : WinAurexException
    {
        public ValidationException(string message) : base(message)
        {
        }

        public ValidationException(string message, Exception innerException) : base(message, innerException)
        {
        }
    }
}
