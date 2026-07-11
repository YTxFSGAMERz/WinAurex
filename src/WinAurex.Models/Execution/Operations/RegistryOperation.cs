namespace WinAurex.Models.Execution.Operations
{
    public enum RegistryHive
    {
        ClassesRoot,
        CurrentUser,
        LocalMachine,
        Users,
        PerformanceData,
        CurrentConfig
    }

    public enum RegistryValueKind
    {
        String,
        ExpandString,
        Binary,
        DWord,
        MultiString,
        QWord,
        Unknown
    }

    public record RegistryTarget(RegistryHive Hive, string KeyPath, string ValueName) : OperationTarget;

    public abstract record RegistryIntent : OperationIntent;
    
    public record SetRegistryValueIntent(object Value, RegistryValueKind ValueKind) : RegistryIntent;
    
    public record DeleteRegistryValueIntent : RegistryIntent;

    public class RegistryOperation : ExecutionOperation<RegistryTarget, RegistryIntent>
    {
        public RegistryOperation(OperationId id) : base(id) { }
    }
}
