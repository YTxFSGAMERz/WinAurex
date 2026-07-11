using System;

namespace WinAurex.Models.Execution;

/// <summary>
/// Defines the execution parameters, resilience, and verification rules for operations.
/// This decouples execution mechanics (timeouts, retries) from the structural definition of an operation.
/// </summary>
public sealed record ExecutionPolicy
{
    /// <summary>
    /// The maximum time allowed for the operation to execute before being canceled.
    /// </summary>
    public TimeSpan? Timeout { get; init; }

    /// <summary>
    /// The strategy used to retry failed operations.
    /// </summary>
    public RetryPolicy RetryPolicy { get; init; } = RetryPolicy.None;

    /// <summary>
    /// The maximum number of retry attempts if the operation fails.
    /// </summary>
    public int MaxRetries { get; init; } = 0;

    /// <summary>
    /// The delay between retries. Use varies depending on the RetryPolicy.
    /// </summary>
    public TimeSpan? RetryDelay { get; init; }

    /// <summary>
    /// Whether the execution engine should continue executing subsequent operations if this one fails.
    /// </summary>
    public bool ContinueOnFailure { get; init; } = false;

    /// <summary>
    /// The strictness level of verification to perform after execution.
    /// </summary>
    public VerificationMode VerificationMode { get; init; } = VerificationMode.Strict;

    /// <summary>
    /// Provides a default execution policy.
    /// </summary>
    public static ExecutionPolicy Default => new ExecutionPolicy();
}
