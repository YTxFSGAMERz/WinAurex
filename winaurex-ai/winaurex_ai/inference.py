import json
import math
import os
import re

def tokenize(text):
    if not text:
        return []
    tokens = re.findall(r'[a-zA-Z0-9]+', text.lower())
    trigrams = []
    clean = re.sub(r'[^a-zA-Z0-9]', '', text.lower())
    for i in range(len(clean) - 2):
        trigrams.append(f"tri_{clean[i:i+3]}")
    return tokens + trigrams

class WinAurexAiEngine:
    def __init__(self, model_path=None):
        if model_path is None:
            base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            model_path = os.path.join(base, "model", "winaurex_ai_model.json")
        
        with open(model_path, "r", encoding="utf-8") as f:
            self.model = json.load(f)

        self.classes = self.model["classes"]
        self.vocab = self.model["vocab"]
        self.log_priors = self.model["log_priors"]
        self.log_likelihoods = self.model["log_likelihoods"]
        self.whitelist = set(self.model.get("whitelist", []))
        self.heuristic_keywords = self.model.get("heuristic_keywords", {})
        self.vocab_size = len(self.vocab)

    def predict(self, name, desc="", vendor=""):
        # 1. Whitelist Check (Tier 0 - Protected)
        if name in self.whitelist:
            return {
                "category": "Core_OS_Essential",
                "tier": "Tier 0 (Protected)",
                "confidence": 1.0,
                "is_safe_to_disable": False,
                "reason": "Cryptographically locked Core Windows component."
            }

        # 2. Extract tokens
        text = f"{name} {desc} {vendor}"
        tokens = tokenize(text)

        # 3. Log-likelihood accumulation
        scores = {}
        for c in self.classes:
            score = self.log_priors[c]
            word_probs = self.log_likelihoods[c]
            default_prob = math.log(1.0 / (self.model["class_totals"][c] + self.vocab_size))
            for t in tokens:
                score += word_probs.get(t, default_prob)
            scores[c] = score

        # 4. Softmax normalization
        max_log = max(scores.values())
        exp_scores = {c: math.exp(scores[c] - max_log) for c in scores}
        sum_exp = sum(exp_scores.values())
        probs = {c: exp_scores[c] / sum_exp for c in exp_scores}

        best_cat = max(probs, key=probs.get)
        confidence = probs[best_cat]

        # 5. Tier assignment
        if best_cat == "Core_OS_Essential":
            tier = "Tier 0 (Protected)"
            is_safe = False
        elif best_cat in ["Telemetry_Tracking", "OEM_Bloatware"]:
            tier = "Tier 1 (Safe)"
            is_safe = True
        elif best_cat in ["ThirdParty_Updater", "Consumer_Bloatware"]:
            tier = "Tier 1 (Safe)" if confidence > 0.85 else "Tier 2 (Recommended)"
            is_safe = True
        else:
            tier = "Tier 2 (Recommended)"
            is_safe = True

        return {
            "category": best_cat,
            "tier": tier,
            "confidence": round(confidence, 4),
            "is_safe_to_disable": is_safe,
            "all_probabilities": {c: round(p, 4) for c, p in probs.items()}
        }
