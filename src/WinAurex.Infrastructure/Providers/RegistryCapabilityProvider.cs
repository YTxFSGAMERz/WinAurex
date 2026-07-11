using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Win32;
using WinAurex.Contracts.Execution;
using WinAurex.Models.Execution.Operations;
using RegistryHive = Microsoft.Win32.RegistryHive;
using RegistryValueKind = Microsoft.Win32.RegistryValueKind;
using WinAurexRegistryHive = WinAurex.Models.Execution.Operations.RegistryHive;
using WinAurexRegistryValueKind = WinAurex.Models.Execution.Operations.RegistryValueKind;

namespace WinAurex.Infrastructure.Providers
{
    public class RegistryCapabilityProvider : ICapabilityProvider<RegistryOperation>
    {
        public ProviderMetadata Metadata => new ProviderMetadata(
            Id: "Registry",
            Name: "Registry Operations Provider",
            Version: "1.0.0",
            SupportsRollback: true,
            SupportsDryRun: true,
            RequiresElevation: true,
            MaxRiskLevel: WinAurex.Models.RiskLevel.Aggressive
        );

        public Task<ProviderResult> AnalyzeAsync(RegistryOperation operation, PlanContext context)
        {
            try
            {
                if (operation.Target == null || string.IsNullOrWhiteSpace(operation.Target.KeyPath))
                    return Task.FromResult(ProviderResult.Failure("KeyPath is required."));

                return Task.FromResult(ProviderResult.Success());
            }
            catch (Exception ex)
            {
                return Task.FromResult(ProviderResult.Failure(ex.Message));
            }
        }

        public Task<ProviderResult> BackupAsync(RegistryOperation operation, PlanContext context)
        {
            try
            {
                var hive = MapHive(operation.Target.Hive);
                using var baseKey = RegistryKey.OpenBaseKey(hive, RegistryView.Default);
                using var subKey = baseKey.OpenSubKey(operation.Target.KeyPath, writable: false);

                if (subKey == null)
                {
                    var undoData = JsonSerializer.Serialize(new RegistryUndoState { Existed = false });
                    return Task.FromResult(ProviderResult.Success(undoData));
                }

                var existingValue = subKey.GetValue(operation.Target.ValueName);
                if (existingValue == null)
                {
                    var undoData = JsonSerializer.Serialize(new RegistryUndoState { Existed = false });
                    return Task.FromResult(ProviderResult.Success(undoData));
                }
                else
                {
                    var kind = subKey.GetValueKind(operation.Target.ValueName);
                    var undoData = JsonSerializer.Serialize(new RegistryUndoState 
                    { 
                        Existed = true, 
                        Value = existingValue, 
                        ValueKind = (int)kind 
                    });
                    return Task.FromResult(ProviderResult.Success(undoData));
                }
            }
            catch (Exception ex)
            {
                return Task.FromResult(ProviderResult.Failure($"Backup failed: {ex.Message}"));
            }
        }

        public Task<ProviderResult> ExecuteAsync(RegistryOperation operation, PlanContext context)
        {
            if (context.IsDryRun)
                return Task.FromResult(ProviderResult.Success());

            try
            {
                var hive = MapHive(operation.Target.Hive);
                using var baseKey = RegistryKey.OpenBaseKey(hive, RegistryView.Default);
                
                using var subKey = baseKey.CreateSubKey(operation.Target.KeyPath, writable: true);
                if (subKey == null)
                    return Task.FromResult(ProviderResult.Failure("Failed to create or open registry key."));

                if (operation.Intent is DeleteRegistryValueIntent)
                {
                    subKey.DeleteValue(operation.Target.ValueName, throwOnMissingValue: false);
                }
                else if (operation.Intent is SetRegistryValueIntent setIntent)
                {
                    var kind = MapKind(setIntent.ValueKind);
                    subKey.SetValue(operation.Target.ValueName, setIntent.Value, kind);
                }

                return Task.FromResult(ProviderResult.Success());
            }
            catch (Exception ex)
            {
                return Task.FromResult(ProviderResult.Failure($"Execution failed: {ex.Message}"));
            }
        }

        public Task<ProviderResult> VerifyAsync(RegistryOperation operation, PlanContext context)
        {
            try
            {
                var hive = MapHive(operation.Target.Hive);
                using var baseKey = RegistryKey.OpenBaseKey(hive, RegistryView.Default);
                using var subKey = baseKey.OpenSubKey(operation.Target.KeyPath, writable: false);

                if (operation.Intent is DeleteRegistryValueIntent)
                {
                    if (subKey != null && subKey.GetValue(operation.Target.ValueName) != null)
                        return Task.FromResult(ProviderResult.Failure("Value still exists."));
                }
                else if (operation.Intent is SetRegistryValueIntent setIntent)
                {
                    if (subKey == null)
                        return Task.FromResult(ProviderResult.Failure("Key does not exist."));

                    var actualValue = subKey.GetValue(operation.Target.ValueName);
                    if (actualValue == null)
                        return Task.FromResult(ProviderResult.Failure("Value does not exist."));

                    if (!actualValue.ToString()!.Equals(setIntent.Value.ToString()))
                        return Task.FromResult(ProviderResult.Failure($"Verification mismatch. Expected: {setIntent.Value}, Actual: {actualValue}"));
                }

                return Task.FromResult(ProviderResult.Success());
            }
            catch (Exception ex)
            {
                return Task.FromResult(ProviderResult.Failure($"Verification failed: {ex.Message}"));
            }
        }

        public Task<ProviderResult> RevertAsync(RegistryOperation operation, string undoData, PlanContext context)
        {
            if (context.IsDryRun)
                return Task.FromResult(ProviderResult.Success());

            try
            {
                if (string.IsNullOrWhiteSpace(undoData))
                    return Task.FromResult(ProviderResult.Failure("No undo data provided."));

                var state = JsonSerializer.Deserialize<RegistryUndoState>(undoData);
                if (state == null)
                    return Task.FromResult(ProviderResult.Failure("Invalid undo data."));

                var hive = MapHive(operation.Target.Hive);
                using var baseKey = RegistryKey.OpenBaseKey(hive, RegistryView.Default);

                if (!state.Existed)
                {
                    using var subKey = baseKey.OpenSubKey(operation.Target.KeyPath, writable: true);
                    subKey?.DeleteValue(operation.Target.ValueName, throwOnMissingValue: false);
                    return Task.FromResult(ProviderResult.Success());
                }
                else
                {
                    using var subKey = baseKey.CreateSubKey(operation.Target.KeyPath, writable: true);
                    if (subKey == null)
                        return Task.FromResult(ProviderResult.Failure("Failed to open or create registry key during revert."));
                    
                    object valToRestore = state.Value!;
                    if (valToRestore is JsonElement je)
                    {
                        if (state.ValueKind == (int)RegistryValueKind.DWord)
                            valToRestore = je.GetInt32();
                        else if (state.ValueKind == (int)RegistryValueKind.String || state.ValueKind == (int)RegistryValueKind.ExpandString)
                            valToRestore = je.GetString() ?? string.Empty;
                        else if (state.ValueKind == (int)RegistryValueKind.QWord)
                            valToRestore = je.GetInt64();
                    }
                    
                    subKey.SetValue(operation.Target.ValueName, valToRestore, (RegistryValueKind)state.ValueKind);
                    return Task.FromResult(ProviderResult.Success());
                }
            }
            catch (Exception ex)
            {
                return Task.FromResult(ProviderResult.Failure($"Revert failed: {ex.Message}"));
            }
        }

        private RegistryHive MapHive(WinAurexRegistryHive hive)
        {
            return hive switch
            {
                WinAurexRegistryHive.ClassesRoot => RegistryHive.ClassesRoot,
                WinAurexRegistryHive.CurrentUser => RegistryHive.CurrentUser,
                WinAurexRegistryHive.LocalMachine => RegistryHive.LocalMachine,
                WinAurexRegistryHive.Users => RegistryHive.Users,
                WinAurexRegistryHive.PerformanceData => RegistryHive.PerformanceData,
                WinAurexRegistryHive.CurrentConfig => RegistryHive.CurrentConfig,
                _ => RegistryHive.LocalMachine
            };
        }

        private RegistryValueKind MapKind(WinAurexRegistryValueKind kind)
        {
            return kind switch
            {
                WinAurexRegistryValueKind.String => RegistryValueKind.String,
                WinAurexRegistryValueKind.ExpandString => RegistryValueKind.ExpandString,
                WinAurexRegistryValueKind.Binary => RegistryValueKind.Binary,
                WinAurexRegistryValueKind.DWord => RegistryValueKind.DWord,
                WinAurexRegistryValueKind.MultiString => RegistryValueKind.MultiString,
                WinAurexRegistryValueKind.QWord => RegistryValueKind.QWord,
                _ => RegistryValueKind.Unknown
            };
        }

        private class RegistryUndoState
        {
            public bool Existed { get; set; }
            public object? Value { get; set; }
            public int ValueKind { get; set; }
        }
    }
}
