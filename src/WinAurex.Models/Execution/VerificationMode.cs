namespace WinAurex.Models.Execution;

/// <summary>
/// Defines the verification strictness during provider execution.
/// </summary>
public enum VerificationMode
{
    /// <summary>
    /// Do not perform any verification after execution.
    /// </summary>
    None,

    /// <summary>
    /// Basic verification (e.g. check if a file or registry key exists).
    /// </summary>
    Basic,

    /// <summary>
    /// Strict verification (e.g. check if the value precisely matches expected content/type).
    /// </summary>
    Strict
}
