namespace WinAurex.Models.Execution;

/// <summary>
/// Defines the retry strategy if an operation fails.
/// </summary>
public enum RetryPolicy
{
    /// <summary>
    /// No retries. Fail immediately.
    /// </summary>
    None,

    /// <summary>
    /// Retry a fixed number of times with a constant delay.
    /// </summary>
    Fixed,

    /// <summary>
    /// Retry with exponentially increasing delays.
    /// </summary>
    ExponentialBackoff
}
