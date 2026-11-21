using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Win32;
using WinAurex.Contracts.Execution;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;

namespace WinAurex.Core.Execution
{
    public class SystemStateAnalyzer : ISystemStateAnalyzer
    {
        public Task<bool> IsActionAppliedAsync(SystemAction action)
        {
            if (action.Detection != null)
            {
                return Task.FromResult(EvaluateDetectionRule(action.Detection));
            }

            var plan = action.ExecutionPlan;
            if (plan == null || plan.Operations == null || plan.Operations.Count == 0)
            {
                return Task.FromResult(false);
            }

            // We consider the plan "applied" if ALL of its operations are applied
            foreach (var op in plan.Operations)
            {
                bool isOpApplied = false;

                if (op is RegistryOperation regOp)
                {
                    isOpApplied = CheckRegistryState(regOp);
                }
                else if (op is PowerShellOperation psOp)
                {
                    isOpApplied = CheckScriptState(psOp);
                }
                else if (op is BatchOperation batchOp)
                {
                    isOpApplied = CheckScriptState(batchOp);
                }
                else if (op is RegFileOperation regFileOp)
                {
                    isOpApplied = CheckRegFileState(regFileOp);
                }

                if (!isOpApplied)
                {
                    return Task.FromResult(false);
                }
            }

            return Task.FromResult(true);
        }

        private bool EvaluateDetectionRule(WinAurex.Models.Execution.DetectionRule rule)
        {
            try
            {
                if (rule is WinAurex.Models.Execution.RegistryDetectionRule regRule)
                {
                    RegistryKey? baseKey = regRule.Hive switch
                    {
                        "ClassesRoot" => Registry.ClassesRoot,
                        "CurrentUser" => Registry.CurrentUser,
                        "LocalMachine" => Registry.LocalMachine,
                        "Users" => Registry.Users,
                        "PerformanceData" => Registry.PerformanceData,
                        "CurrentConfig" => Registry.CurrentConfig,
                        _ => null
                    };

                    if (baseKey == null) return false;
                    using var subKey = baseKey.OpenSubKey(regRule.Key);
                    if (subKey == null) return false;
                    
                    var actualValue = subKey.GetValue(regRule.ValueName);
                    if (actualValue == null) return false;
                    
                    if (regRule.ExpectedValue != null)
                    {
                        return actualValue.ToString() == regRule.ExpectedValue.ToString();
                    }
                    return true;
                }
                else if (rule is WinAurex.Models.Execution.FileDetectionRule fileRule)
                {
                    var expandedPath = Environment.ExpandEnvironmentVariables(fileRule.Path);
                    return File.Exists(expandedPath);
                }
            }
            catch
            {
                return false;
            }
            return false;
        }

        private bool CheckRegistryState(RegistryOperation op)
        {
            var target = op.Target;
            var intent = op.Intent;

            RegistryKey? baseKey = GetBaseKey(target.Hive);
            if (baseKey == null) return false;

            try
            {
                using var subKey = baseKey.OpenSubKey(target.KeyPath);
                
                if (intent is SetRegistryValueIntent setIntent)
                {
                    if (subKey == null) return false; // Key doesn't exist, so value can't be set
                    
                    var actualValue = subKey.GetValue(target.ValueName);
                    if (actualValue == null) return false;

                    // Convert both to string for basic comparison (simplification for now)
                    return actualValue.ToString() == setIntent.Value.ToString();
                }
                else if (intent is DeleteRegistryValueIntent)
                {
                    if (subKey == null) return true; // Key doesn't exist, so value is implicitly deleted
                    
                    var actualValue = subKey.GetValue(target.ValueName);
                    return actualValue == null; // True if value does not exist
                }
            }
            catch (Exception)
            {
                // Inaccessible keys or errors mean we can't confirm it's applied
                return false;
            }

            return false;
        }

        private bool CheckScriptState(ExecutionOperation op)
        {
            // For scripts, we can't natively check state unless there's a specific detection logic.
            // For now, if a script doesn't have a check mechanism, we default to false (not applied).
            // A robust implementation would look for a "CheckScript" in the operation metadata.
            
            // TODO: Execute the check script if provided.
            return false;
        }

        private bool CheckRegFileState(RegFileOperation op)
        {
            var target = op.Target;
            if (target == null || !File.Exists(target.FilePath))
            {
                return false;
            }

            try
            {
                return EvaluateRegFile(File.ReadAllLines(target.FilePath));
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Evaluates a .reg document as a whole: true only when every value it sets
        /// is present with the expected data and every key it deletes is absent.
        /// </summary>
        private static bool EvaluateRegFile(IReadOnlyList<string> lines)
        {
            string? currentKey = null;
            var deletionSections = new List<string>();
            var valueChecks = new List<(string Key, string? ValueName, string Data)>();
            var sawCheckableEntry = false;

            for (var i = 0; i < lines.Count; i++)
            {
                var trimmed = lines[i].Trim();
                if (trimmed.Length == 0 || trimmed.StartsWith(";"))
                {
                    continue;
                }

                if (trimmed.StartsWith("["))
                {
                    var section = trimmed;
                    while (!section.EndsWith("]") && i + 1 < lines.Count)
                    {
                        i++;
                        section += lines[i].Trim();
                    }

                    if (!section.EndsWith("]"))
                    {
                        return false;
                    }

                    var keyPath = section.Substring(1, section.Length - 2).Trim();
                    if (keyPath.StartsWith("-"))
                    {
                        deletionSections.Add(NormalizeKeyPath(keyPath.Substring(1).Trim()));
                        currentKey = null;
                    }
                    else
                    {
                        currentKey = NormalizeKeyPath(keyPath);
                    }

                    continue;
                }

                var separator = trimmed.IndexOf('=');
                if (separator <= 0 || currentKey == null)
                {
                    continue;
                }

                var rawName = trimmed.Substring(0, separator).Trim();
                var rawData = trimmed.Substring(separator + 1).Trim();

                // Hex payloads can be wrapped over lines with a trailing backslash.
                while (rawData.EndsWith("\\") && i + 1 < lines.Count)
                {
                    rawData = rawData.Substring(0, rawData.Length - 1) + lines[++i].Trim();
                }

                var valueName = rawName == "@" ? null : rawName.Trim('"');
                valueChecks.Add((currentKey, valueName, rawData));
            }

            foreach (var check in valueChecks)
            {
                if (!ValueMatches(Registry.GetValue(check.Key, check.ValueName, null), check.Data))
                {
                    return false;
                }

                sawCheckableEntry = true;
            }

            foreach (var key in deletionSections)
            {
                if (KeyExists(key))
                {
                    return false;
                }

                sawCheckableEntry = true;
            }

            return sawCheckableEntry;
        }

        private static bool ValueMatches(object? actual, string rawData)
        {
            var data = rawData.Trim();

            if (data.Length >= 2 && data.StartsWith("\"") && data.EndsWith("\""))
            {
                var expected = UnescapeRegString(data.Substring(1, data.Length - 2));
                return actual is string actualString && string.Equals(actualString, expected, StringComparison.Ordinal);
            }

            if (data.StartsWith("dword:", StringComparison.OrdinalIgnoreCase))
            {
                if (!uint.TryParse(data.Substring(6).Trim(), NumberStyles.HexNumber, CultureInfo.InvariantCulture, out var expectedDword))
                {
                    return false;
                }

                return actual is int actualInt && unchecked((uint)actualInt) == expectedDword;
            }

            if (data.StartsWith("hex:", StringComparison.OrdinalIgnoreCase))
            {
                var bytes = ParseHexBytes(data.Substring(4));
                return bytes != null && actual is byte[] actualBytes && actualBytes.AsSpan().SequenceEqual(bytes);
            }

            if (data.StartsWith("hex(", StringComparison.OrdinalIgnoreCase))
            {
                var close = data.IndexOf(')');
                if (close < 0)
                {
                    return false;
                }

                var type = data.Substring(4, close - 4);
                var colon = data.IndexOf(':', close);
                if (colon < 0)
                {
                    return false;
                }

                var bytes = ParseHexBytes(data.Substring(colon + 1));
                if (bytes == null)
                {
                    return false;
                }

                return type switch
                {
                    "0" or "1" or "3" => actual is byte[] actualBytes && actualBytes.AsSpan().SequenceEqual(bytes),
                    "b" or "B" => bytes.Length == 8 && actual is long qword && BitConverter.ToInt64(bytes, 0) == qword,
                    "4" => bytes.Length == 4 && actual is int dword && unchecked((uint)dword) == BitConverter.ToUInt32(bytes, 0),
                    "2" => actual is string expandString && string.Equals(expandString, DecodeUtf16(bytes), StringComparison.Ordinal),
                    "7" => actual is string[] multiString && multiString.SequenceEqual(SplitMultiString(DecodeUtf16(bytes)), StringComparer.Ordinal),
                    _ => false
                };
            }

            // Unknown data format is treated as unverifiable, never as applied.
            return false;
        }

        private static byte[]? ParseHexBytes(string hexData)
        {
            var cleaned = hexData.Replace(" ", string.Empty).Trim();
            if (cleaned.Length == 0)
            {
                return Array.Empty<byte>();
            }

            var parts = cleaned.Split(',');
            var bytes = new byte[parts.Length];

            for (var i = 0; i < parts.Length; i++)
            {
                if (!byte.TryParse(parts[i], NumberStyles.HexNumber, CultureInfo.InvariantCulture, out bytes[i]))
                {
                    return null;
                }
            }

            return bytes;
        }

        private static string DecodeUtf16(byte[] bytes) =>
            Encoding.Unicode.GetString(bytes);

        private static string[] SplitMultiString(string text) =>
            text.Split('\0', StringSplitOptions.RemoveEmptyEntries);

        private static string UnescapeRegString(string value)
        {
            var builder = new StringBuilder(value.Length);

            for (var i = 0; i < value.Length; i++)
            {
                if (value[i] == '\\' && i + 1 < value.Length && (value[i + 1] == '\\' || value[i + 1] == '\"'))
                {
                    builder.Append(value[i + 1]);
                    i++;
                }
                else
                {
                    builder.Append(value[i]);
                }
            }

            return builder.ToString();
        }

        private static string NormalizeKeyPath(string path)
        {
            var trimmed = path.Trim();
            var upper = trimmed.ToUpperInvariant();

            if (upper.StartsWith("HKCU"))
            {
                return "HKEY_CURRENT_USER" + trimmed.Substring(4);
            }

            if (upper.StartsWith("HKLM"))
            {
                return "HKEY_LOCAL_MACHINE" + trimmed.Substring(4);
            }

            if (upper.StartsWith("HKCR"))
            {
                return "HKEY_CLASSES_ROOT" + trimmed.Substring(4);
            }

            if (upper.StartsWith("HKCC"))
            {
                return "HKEY_CURRENT_CONFIG" + trimmed.Substring(4);
            }

            if (upper.StartsWith("HKU"))
            {
                return "HKEY_USERS" + trimmed.Substring(3);
            }

            return trimmed;
        }

        private static bool KeyExists(string fullPath)
        {
            var separator = fullPath.IndexOf('\\');
            var rootName = (separator < 0 ? fullPath : fullPath.Substring(0, separator)).ToUpperInvariant();
            var subPath = separator < 0 ? string.Empty : fullPath.Substring(separator + 1);

            RegistryKey? root = rootName switch
            {
                "HKEY_CURRENT_USER" => Registry.CurrentUser,
                "HKEY_LOCAL_MACHINE" => Registry.LocalMachine,
                "HKEY_CLASSES_ROOT" => Registry.ClassesRoot,
                "HKEY_USERS" => Registry.Users,
                "HKEY_CURRENT_CONFIG" => Registry.CurrentConfig,
                "HKEY_PERFORMANCE_DATA" => Registry.PerformanceData,
                _ => null
            };

            if (root == null)
            {
                return false;
            }

            if (string.IsNullOrEmpty(subPath))
            {
                return true;
            }

            try
            {
                using var subKey = root.OpenSubKey(subPath);
                return subKey != null;
            }
            catch
            {
                return false;
            }
        }

        private RegistryKey? GetBaseKey(WinAurex.Models.Execution.Operations.RegistryHive hive)
        {
            return hive switch
            {
                WinAurex.Models.Execution.Operations.RegistryHive.ClassesRoot => Registry.ClassesRoot,
                WinAurex.Models.Execution.Operations.RegistryHive.CurrentUser => Registry.CurrentUser,
                WinAurex.Models.Execution.Operations.RegistryHive.LocalMachine => Registry.LocalMachine,
                WinAurex.Models.Execution.Operations.RegistryHive.Users => Registry.Users,
                WinAurex.Models.Execution.Operations.RegistryHive.PerformanceData => Registry.PerformanceData,
                WinAurex.Models.Execution.Operations.RegistryHive.CurrentConfig => Registry.CurrentConfig,
                _ => null
            };
        }
    }
}
