using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace WinAurex.Models.Execution
{
    [JsonConverter(typeof(OperationIdJsonConverter))]
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

    public class OperationIdJsonConverter : JsonConverter<OperationId>
    {
        public override OperationId Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.String)
            {
                throw new JsonException($"OperationId must be a JSON string, but found {reader.TokenType}.");
            }

            var value = reader.GetString();
            if (string.IsNullOrWhiteSpace(value))
            {
                throw new JsonException("OperationId cannot be empty.");
            }

            return new OperationId(value);
        }

        public override void Write(Utf8JsonWriter writer, OperationId value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.Value);
        }
    }
}
