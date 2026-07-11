using System;
using System.Collections.Generic;

namespace WinAurex.Models
{
    public class ActionExecutionResult
    {
        public string ActionId { get; set; } = string.Empty;
        public ActionStatus Status { get; set; } = ActionStatus.NotApplied;
        public string Message { get; set; } = string.Empty;
        public bool RestoreCreated { get; set; }
        public DateTimeOffset ExecutedAt { get; set; } = DateTimeOffset.UtcNow;
        public Dictionary<string, string> Details { get; set; } = new Dictionary<string, string>();
    }
}
