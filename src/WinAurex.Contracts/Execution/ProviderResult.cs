using System;
using System.Collections.Generic;

namespace WinAurex.Contracts.Execution
{
    public class ProviderResult
    {
        public bool IsSuccess { get; init; }
        public string UndoData { get; init; } = string.Empty;
        public string ErrorMessage { get; init; } = string.Empty;
        
        public TimeSpan Duration { get; init; } = TimeSpan.Zero;
        public IReadOnlyList<string> Warnings { get; init; } = Array.Empty<string>();
        public IReadOnlyList<string> VerificationMessages { get; init; } = Array.Empty<string>();

        public static ProviderResult Success(string undoData = "", TimeSpan duration = default) 
            => new() { IsSuccess = true, UndoData = undoData, Duration = duration };
            
        public static ProviderResult Failure(string error, TimeSpan duration = default) 
            => new() { IsSuccess = false, ErrorMessage = error, Duration = duration };
    }
}
