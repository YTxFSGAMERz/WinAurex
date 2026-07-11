namespace WinAurex.Models
{
    public enum RiskLevel
    {
        Safe,
        Advanced,
        Aggressive
    }

    public enum RestoreMethod
    {
        None,
        RegistryRevert,
        ServiceRestart,
        ScriptRollback
    }

    public enum ActionStatus
    {
        NotApplied,
        Applied,
        Failed,
        Unknown
    }
}
