using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.IO;
using System.Text.Json;
using WinAurex.Models;
using WinAurex.Models.Execution;
using WinAurex.Models.Execution.Operations;

namespace WinAurex.Core.Profiles
{
    using System.Text.RegularExpressions;
    using System.Linq;

    public interface ITweakLoader
    {
        IEnumerable<SystemAction> LoadTweaks(string directoryPath);
    }

    public class TweakLoader : ITweakLoader
    {
        public IEnumerable<SystemAction> LoadTweaks(string directoryPath)
        {
            var actions = new List<SystemAction>();
            
            if (!Directory.Exists(directoryPath))
            {
                return actions;
            }

            // Load descriptions map
            var descriptionsMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            var descriptionsFile = Path.Combine(directoryPath, "descriptions.json");
            if (File.Exists(descriptionsFile))
            {
                try
                {
                    var json = File.ReadAllText(descriptionsFile);
                    var parsed = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
                    if (parsed != null)
                    {
                        foreach (var kvp in parsed)
                        {
                            descriptionsMap[kvp.Key] = kvp.Value;
                        }
                    }
                }
                catch { /* Ignore if it fails */ }
            }

            // Load detections map
            var detectionsMap = new Dictionary<string, DetectionRule>(StringComparer.OrdinalIgnoreCase);
            var detectionsFile = Path.Combine(directoryPath, "detections.json");
            if (File.Exists(detectionsFile))
            {
                try
                {
                    var json = File.ReadAllText(detectionsFile);
                    var parsed = JsonSerializer.Deserialize<Dictionary<string, DetectionRule>>(json);
                    if (parsed != null)
                    {
                        foreach (var kvp in parsed)
                        {
                            detectionsMap[kvp.Key] = kvp.Value;
                        }
                    }
                }
                catch { /* Ignore if it fails */ }
            }

            var allFiles = Directory.GetFiles(directoryPath, "*.*", SearchOption.AllDirectories)
                .Where(f => !Path.GetFileName(f).Equals("descriptions.json", StringComparison.OrdinalIgnoreCase) && 
                            !Path.GetFileName(f).Equals("detections.json", StringComparison.OrdinalIgnoreCase));

            // Group files by category and subject
            var tweaksData = new Dictionary<string, TweakGroup>();

            foreach (var filePath in allFiles)
            {
                var extension = Path.GetExtension(filePath).ToLowerInvariant();
                var fileName = Path.GetFileNameWithoutExtension(filePath);
                var category = new DirectoryInfo(Path.GetDirectoryName(filePath)).Name;

                // Simple regex to parse prefix and subject
                var match = Regex.Match(fileName, @"^(Disable|Enable|Apply|Revert|Restore|Remove|Set|Light|Dark|Configure|Optimizar|Optimize)\s*_*_?\s*(.*?)(?:\s*\(Restore\))?$", RegexOptions.IgnoreCase);
                
                string subject = fileName;
                string actionType = "Apply"; // Default to apply

                if (match.Success)
                {
                    string prefix = match.Groups[1].Value;
                    subject = match.Groups[2].Value;

                    if (string.IsNullOrWhiteSpace(subject))
                        subject = fileName; // fallback

                    // Determine if this file acts as Apply or Revert based on its prefix
                    if (prefix.Equals("Enable", StringComparison.OrdinalIgnoreCase) ||
                        prefix.Equals("Revert", StringComparison.OrdinalIgnoreCase) ||
                        prefix.Equals("Restore", StringComparison.OrdinalIgnoreCase) ||
                        prefix.Equals("Light", StringComparison.OrdinalIgnoreCase))
                    {
                        // Enable could be Apply if there is no Disable. We will resolve this after grouping.
                        actionType = prefix;
                    }
                    else
                    {
                        actionType = prefix; // Disable, Apply, Remove, etc.
                    }
                }

                string key = $"{category}_{subject}".ToLowerInvariant();

                if (!tweaksData.ContainsKey(key))
                {
                    tweaksData[key] = new TweakGroup { Category = category, Subject = subject.Replace("_", " "), Key = key };
                }

                tweaksData[key].Files.Add(new TweakFile { Path = filePath, Extension = extension, Prefix = actionType, OriginalName = fileName });
            }

            foreach (var group in tweaksData.Values)
            {
                string description = $"Executes the {group.Subject} tweak.";
                foreach (var file in group.Files)
                {
                    if (descriptionsMap.TryGetValue(file.OriginalName, out string mappedDesc))
                    {
                        // Prefer apply file description
                        if (!new[] { "Enable", "Revert", "Restore" }.Contains(file.Prefix, StringComparer.OrdinalIgnoreCase))
                        {
                            description = mappedDesc;
                            break;
                        }
                        else if (description.StartsWith("Executes the"))
                        {
                            description = mappedDesc; // fallback to revert description if we haven't found an apply one
                        }
                    }
                }

                DetectionRule? detection = null;
                foreach (var file in group.Files)
                {
                    if (detectionsMap.TryGetValue(file.OriginalName, out var mappedRule))
                    {
                        detection = mappedRule;
                        break;
                    }
                }

                var action = new SystemAction
                {
                    Id = group.Key.Replace(" ", "_"),
                    DisplayName = group.Subject,
                    Description = description,
                    Category = group.Category,
                    RiskLevel = RiskLevel.Advanced,
                    AvailableMethods = new List<ActionExecutionMethod>(),
                    Detection = detection
                };

                // Group by method (extension)
                var filesByExtension = group.Files.GroupBy(f => f.Extension);

                foreach (var extGroup in filesByExtension)
                {
                    var ext = extGroup.Key;
                    
                    var method = new ActionExecutionMethod
                    {
                        Name = ext == ".ps1" ? "PowerShell" : (ext == ".reg" ? "Registry" : (ext == ".bat" || ext == ".cmd" ? "Batch" : "Unknown")),
                        ExecutionPlan = new ExecutionPlan { Id = Guid.NewGuid(), Operations = ImmutableList<ExecutionOperation>.Empty }
                    };

                    // Find apply and revert files
                    var files = extGroup.ToList();
                    TweakFile applyFile = null;
                    TweakFile revertFile = null;

                    // If there are exactly two files, and one is 'Enable/Restore/Revert/Light' and the other is 'Disable/Dark/Remove/Apply'
                    if (files.Count == 2)
                    {
                        var potentialReverts = new[] { "Enable", "Revert", "Restore", "Light" };
                        revertFile = files.FirstOrDefault(f => potentialReverts.Contains(f.Prefix, StringComparer.OrdinalIgnoreCase));
                        applyFile = files.FirstOrDefault(f => f != revertFile);

                        // If both are weird, just assign arbitrarily
                        if (applyFile == null) { applyFile = files[0]; revertFile = files[1]; }
                    }
                    else if (files.Count == 1)
                    {
                        applyFile = files[0];
                    }
                    else
                    {
                        // More than 2 files? Just take the first as apply for now.
                        applyFile = files.FirstOrDefault(f => !new[] { "Enable", "Revert", "Restore" }.Contains(f.Prefix, StringComparer.OrdinalIgnoreCase)) ?? files[0];
                        revertFile = files.FirstOrDefault(f => f != applyFile);
                    }

                    if (applyFile != null)
                    {
                        method.ExecutionPlan = new ExecutionPlan
                        {
                            Id = Guid.NewGuid(),
                            Operations = ImmutableList.Create(CreateOperation(applyFile.Path, applyFile.Extension))
                        };
                    }

                    if (revertFile != null)
                    {
                        method.RollbackPlan = new ExecutionPlan
                        {
                            Id = Guid.NewGuid(),
                            Operations = ImmutableList.Create(CreateOperation(revertFile.Path, revertFile.Extension))
                        };
                    }

                    if (applyFile != null || revertFile != null)
                    {
                        action.AvailableMethods.Add(method);
                    }
                }

                if (action.AvailableMethods.Any())
                {
                    action.SelectedMethod = action.AvailableMethods.First();
                    actions.Add(action);
                }
            }

            return actions.OrderBy(a => a.DisplayName).ToList();
        }

        private ExecutionOperation CreateOperation(string filePath, string extension)
        {
            switch (extension)
            {
                case ".ps1":
                    return new PowerShellOperation(new OperationId($"PowerShellExecutor.{Guid.NewGuid()}"))
                    {
                        Target = new ScriptTarget(filePath, Array.Empty<string>()),
                        Intent = new PowerShellIntent(RequireElevation: true, BypassExecutionPolicy: true)
                    };
                case ".bat":
                case ".cmd":
                    return new BatchOperation(new OperationId($"BatchExecutor.{Guid.NewGuid()}"))
                    {
                        Target = new ScriptTarget(filePath, Array.Empty<string>()),
                        Intent = new BatchIntent(RequireElevation: true)
                    };
                case ".reg":
                    return new RegFileOperation(new OperationId($"RegFileExecutor.{Guid.NewGuid()}"))
                    {
                        Target = new RegFileTarget(filePath),
                        Intent = new RegFileIntent(RequireElevation: true)
                    };
                case ".exe":
                    return new BatchOperation(new OperationId($"BatchExecutor.{Guid.NewGuid()}"))
                    {
                        Target = new ScriptTarget(filePath, Array.Empty<string>()),
                        Intent = new BatchIntent(RequireElevation: true)
                    };
                default:
                    return null;
            }
        }

        private class TweakGroup
        {
            public string Key { get; set; }
            public string Category { get; set; }
            public string Subject { get; set; }
            public List<TweakFile> Files { get; set; } = new List<TweakFile>();
        }

        private class TweakFile
        {
            public string Path { get; set; }
            public string Extension { get; set; }
            public string Prefix { get; set; }
            public string OriginalName { get; set; }
        }
    }
}
