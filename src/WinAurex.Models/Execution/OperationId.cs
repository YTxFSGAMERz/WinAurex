using System;

namespace WinAurex.Models.Execution
{
    [System.Text.Json.Serialization.JsonConverter(typeof(OperationIdJsonConverter))]
    public readonly record struct OperationId
    {
        public string Value { get; }
        public string Provider { get; }
        public string Action { get; }

        public OperationId(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("OperationId cannot be empty.", nameof(value));
            
            Value = value;
            var parts = value.Split('.', 2);
            Provider = parts[0];
            Action = parts.Length > 1 ? parts[1] : string.Empty;
        }

        public override string ToString() => Value;

        public static implicit operator string(OperationId id) => id.Value;
        public static explicit operator OperationId(string value) => new(value);
    }

    public class OperationIdJsonConverter : System.Text.Json.Serialization.JsonConverter<OperationId>
    {
        public override OperationId Read(ref System.Text.Json.Utf8JsonReader reader, Type typeToConvert, System.Text.Json.JsonSerializerOptions options)
        {
            return new OperationId(reader.GetString() ?? string.Empty);
        }

        public override void Write(System.Text.Json.Utf8JsonWriter writer, OperationId value, System.Text.Json.JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.Value);
        }
    }
}
