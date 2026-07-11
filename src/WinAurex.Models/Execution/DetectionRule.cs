using System.Text.Json.Serialization;

namespace WinAurex.Models.Execution
{
    [JsonPolymorphic(TypeDiscriminatorPropertyName = "Type")]
    [JsonDerivedType(typeof(RegistryDetectionRule), typeDiscriminator: "Registry")]
    [JsonDerivedType(typeof(FileDetectionRule), typeDiscriminator: "File")]
    public abstract class DetectionRule
    {
        public abstract string Type { get; }
    }

    public class RegistryDetectionRule : DetectionRule
    {
        public override string Type => "Registry";
        public string Hive { get; set; } = string.Empty;
        public string Key { get; set; } = string.Empty;
        public string ValueName { get; set; } = string.Empty;
        public object? ExpectedValue { get; set; }
    }

    public class FileDetectionRule : DetectionRule
    {
        public override string Type => "File";
        public string Path { get; set; } = string.Empty;
    }
}
