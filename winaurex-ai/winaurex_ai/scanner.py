import os
import sys
import psutil
from .inference import WinAurexAiEngine

def run_live_scan():
    print("=" * 70)
    print("        WinAurex AI - Live System Neural Diagnostic Scanner           ")
    print("=" * 70)
    
    engine = WinAurexAiEngine()
    print(f"[*] Engine Initialized. Loaded {len(engine.vocab)} neural features across {len(engine.classes)} classes.")
    print("[*] Interrogating active processes and background daemons...\n")

    detections = []
    seen = set()

    for proc in psutil.process_iter(['pid', 'name', 'num_threads']):
        try:
            name = proc.info['name']
            if name in seen:
                continue
            seen.add(name)
            threads = proc.info.get('num_threads', 0)
            
            # Predict using neural engine
            pred = engine.predict(name)
            if pred["category"] != "Core_OS_Essential" and pred["is_safe_to_disable"]:
                detections.append({
                    "pid": proc.info['pid'],
                    "name": name,
                    "category": pred["category"],
                    "tier": pred["tier"],
                    "confidence": f"{pred['confidence'] * 100:.1f}%",
                    "threads": threads
                })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    print(f"{'Target Name':<30} | {'Category':<22} | {'Safety Tier':<16} | {'Confidence':<10}")
    print("-" * 86)
    for d in detections:
        print(f"{d['name']:<30} | {d['category']:<22} | {d['tier']:<16} | {d['confidence']:<10}")

    print("-" * 86)
    print(f"\n[AI SCAN COMPLETE] Found {len(detections)} potential optimization targets running in background.")

if __name__ == "__main__":
    run_live_scan()
