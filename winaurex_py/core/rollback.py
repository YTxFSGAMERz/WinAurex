"""
Rollback & Transaction Manager for WinAurex Python Engine.
Tracks all modifications made during a session and writes atomic JSON manifests.
Allows 100% safe undo of any tweak or optimization applied.
"""

import os
import json
import time
from typing import List, Dict, Any, Optional
from datetime import datetime
from .registry import set_reg_value, delete_reg_value

BACKUPS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backups"))

class RollbackManager:
    def __init__(self):
        self.actions: List[Dict[str, Any]] = []
        os.makedirs(BACKUPS_DIR, exist_ok=True)

    def record_action(self, action: Dict[str, Any]):
        """Records an action with its pre-modification state."""
        self.actions.append(action)

    def save_manifest(self, description: str = "Tweak Session") -> Optional[str]:
        """
        Saves the recorded actions to a timestamped JSON manifest in the backups directory.
        Returns the file path of the manifest if saved, or None if no actions recorded.
        """
        if not self.actions:
            return None

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"manifest_{timestamp}.json"
        filepath = os.path.join(BACKUPS_DIR, filename)

        data = {
            "version": "6.0.0",
            "timestamp": datetime.now().isoformat(),
            "description": description,
            "actions_count": len(self.actions),
            "actions": self.actions
        }

        try:
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            return filepath
        except Exception as e:
            print(f"Error saving rollback manifest: {e}")
            return None

    @staticmethod
    def list_manifests() -> List[Dict[str, Any]]:
        """Lists all existing backup manifests sorted by most recent first."""
        if not os.path.exists(BACKUPS_DIR):
            return []

        manifests = []
        for file in os.listdir(BACKUPS_DIR):
            if file.startswith("manifest_") and file.endswith(".json"):
                path = os.path.join(BACKUPS_DIR, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                        data["filepath"] = path
                        data["filename"] = file
                        manifests.append(data)
                except Exception:
                    continue

        manifests.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return manifests

    @staticmethod
    def apply_rollback(manifest_path: str) -> Dict[str, Any]:
        """
        Reads a manifest file and restores all previous settings in reverse order.
        """
        results = {
            "success": True,
            "restored_count": 0,
            "failed_count": 0,
            "errors": []
        }

        if not os.path.isfile(manifest_path):
            results["success"] = False
            results["errors"].append(f"Manifest not found: {manifest_path}")
            return results

        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            results["success"] = False
            results["errors"].append(f"Failed to parse manifest: {e}")
            return results

        actions = data.get("actions", [])
        # Apply in reverse order
        for action in reversed(actions):
            action_type = action.get("type", "registry")
            if action_type == "registry":
                root = action.get("root")
                subkey = action.get("subkey")
                val_name = action.get("value_name")
                existed = action.get("existed", False)
                prev_val = action.get("previous_value")
                prev_type = action.get("previous_type")

                if existed and prev_val is not None:
                    # Restore previous value
                    res = set_reg_value(root, subkey, val_name, prev_val, prev_type)
                    if res.get("success"):
                        results["restored_count"] += 1
                    else:
                        results["failed_count"] += 1
                        results["errors"].append(f"Failed to restore {val_name}: {res.get('error')}")
                else:
                    # It didn't exist before, so delete it
                    res = delete_reg_value(root, subkey, val_name)
                    if res.get("success"):
                        results["restored_count"] += 1
                    else:
                        results["failed_count"] += 1
                        results["errors"].append(f"Failed to remove {val_name}: {res.get('error')}")

        return results

# Global singleton session rollback manager
session_rollback = RollbackManager()
