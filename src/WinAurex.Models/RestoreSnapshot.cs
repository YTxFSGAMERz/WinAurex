using System;
using System.Collections.Generic;

namespace WinAurex.Models
{
    public class RestoreSnapshot
    {
        public string SnapshotId { get; set; } = string.Empty;
        public string ActionId { get; set; } = string.Empty;
        public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
        public string RestoreMethod { get; set; } = string.Empty;
        public Dictionary<string, string> Metadata { get; set; } = new Dictionary<string, string>();
    }
}
