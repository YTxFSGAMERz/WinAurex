using System;
using System.IO;
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
            if (!File.Exists(target.FilePath)) return false;

            try
            {
                // Simple parser for the first key-value pair to determine state
                var lines = File.ReadAllLines(target.FilePath);
                string currentKey = null;

                foreach (var line in lines)
                {
                    var trimmed = line.Trim();
                    if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith(";")) continue;

                    if (trimmed.StartsWith("[") && trimmed.EndsWith("]"))
                    {
                        var keyPath = trimmed.Substring(1, trimmed.Length - 2);
                        if (keyPath.StartsWith("-")) keyPath = keyPath.Substring(1); // Deletion key
                        
                        // Map registry root names to short names compatible with Registry.GetValue
                        if (keyPath.StartsWith("HKEY_CURRENT_USER")) keyPath = keyPath.Replace("HKEY_CURRENT_USER", "HKEY_CURRENT_USER");
                        else if (keyPath.StartsWith("HKEY_LOCAL_MACHINE")) keyPath = keyPath.Replace("HKEY_LOCAL_MACHINE", "HKEY_LOCAL_MACHINE");
                        else if (keyPath.StartsWith("HKEY_CLASSES_ROOT")) keyPath = keyPath.Replace("HKEY_CLASSES_ROOT", "HKEY_CLASSES_ROOT");
                        else if (keyPath.StartsWith("HKEY_USERS")) keyPath = keyPath.Replace("HKEY_USERS", "HKEY_USERS");
                        else if (keyPath.StartsWith("HKEY_CURRENT_CONFIG")) keyPath = keyPath.Replace("HKEY_CURRENT_CONFIG", "HKEY_CURRENT_CONFIG");

                        currentKey = keyPath;
                    }
                    else if (currentKey != null && trimmed.StartsWith("\""))
                    {
                        var parts = trimmed.Split(new[] { '=' }, 2);
                        if (parts.Length == 2)
                        {
                            var valueName = parts[0].Trim('"');
                            var valueDataStr = parts[1];
                            
                            // Check the registry
                            var actualValue = Registry.GetValue(currentKey, valueName, null);
                            if (actualValue == null) return false;

                            // Very basic verification for DWORD and Strings
                            if (valueDataStr.StartsWith("dword:"))
                            {
                                if (int.TryParse(valueDataStr.Substring(6), System.Globalization.NumberStyles.HexNumber, null, out int expectedDword))
                                {
                                    if (actualValue is int actualInt && actualInt == expectedDword)
                                        return true; // We only check the first value we find for performance
                                }
                            }
                            else if (valueDataStr.StartsWith("\"") && valueDataStr.EndsWith("\""))
                            {
                                var expectedStr = valueDataStr.Trim('"');
                                if (actualValue is string actualStr && actualStr == expectedStr)
                                    return true;
                            }
                            return false;
                        }
                    }
                }
            }
            catch
            {
                return false;
            }

            return false;
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
