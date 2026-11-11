import json
import math
import os
import re

def tokenize(text):
    if not text:
        return []
    # Clean text and split into alphanumeric tokens
    tokens = re.findall(r'[a-zA-Z0-9]+', text.lower())
    # Also add character trigrams for robust substring matching
    trigrams = []
    clean = re.sub(r'[^a-zA-Z0-9]', '', text.lower())
    for i in range(len(clean) - 2):
        trigrams.append(f"tri_{clean[i:i+3]}")
    return tokens + trigrams

class WinAurexAiTrainer:
    def __init__(self):
        self.classes = [
            "Core_OS_Essential",
            "Telemetry_Tracking",
            "OEM_Bloatware",
            "ThirdParty_Updater",
            "Consumer_Bloatware",
            "High_Overhead_Task"
        ]
        self.vocab = {}
        self.class_word_counts = {c: {} for c in self.classes}
        self.class_totals = {c: 0 for c in self.classes}
        self.class_doc_counts = {c: 0 for c in self.classes}
        self.total_docs = 0

    def fit(self, dataset):
        self.total_docs = len(dataset)
        for item in dataset:
            cat = item["category"]
            self.class_doc_counts[cat] += 1
            text = f"{item['name']} {item.get('desc', '')} {item.get('vendor', '')}"
            tokens = tokenize(text)
            for token in tokens:
                if token not in self.vocab:
                    self.vocab[token] = len(self.vocab)
                self.class_word_counts[cat][token] = self.class_word_counts[cat].get(token, 0) + 1
                self.class_totals[cat] += 1

    def evaluate(self, dataset):
        correct = 0
        total = len(dataset)
        results = []
        for item in dataset:
            pred_cat, confidence = self.predict(item["name"], item.get("desc", ""), item.get("vendor", ""))
            is_correct = (pred_cat == item["category"])
            if is_correct:
                correct += 1
            results.append({
                "name": item["name"],
                "actual": item["category"],
                "predicted": pred_cat,
                "confidence": round(confidence * 100, 2),
                "correct": is_correct
            })
        acc = (correct / total) * 100 if total > 0 else 0
        return acc, results

    def predict(self, name, desc="", vendor=""):
        text = f"{name} {desc} {vendor}"
        tokens = tokenize(text)
        scores = {}
        vocab_size = len(self.vocab)
        
        # Keyword and rule booster overrides
        lower_name = name.lower()
        lower_desc = desc.lower()

        for c in self.classes:
            # Prior probability log(P(c))
            prior = math.log((self.class_doc_counts[c] + 1) / (self.total_docs + len(self.classes)))
            log_prob = prior
            total_words = self.class_totals[c] + vocab_size
            for token in tokens:
                count = self.class_word_counts[c].get(token, 0)
                # Laplace smoothing
                prob = (count + 1) / total_words
                log_prob += math.log(prob)
            scores[c] = log_prob

        # Convert log probabilities to normalized softmax probabilities
        max_log = max(scores.values())
        exp_scores = {c: math.exp(scores[c] - max_log) for c in scores}
        sum_exp = sum(exp_scores.values())
        probs = {c: exp_scores[c] / sum_exp for c in exp_scores}

        best_cat = max(probs, key=probs.get)
        confidence = probs[best_cat]
        return best_cat, confidence

    def export_model(self, out_path, dataset):
        # Calculate log-priors and log-likelihoods for export
        vocab_size = len(self.vocab)
        log_priors = {}
        log_likelihoods = {c: {} for c in self.classes}

        for c in self.classes:
            log_priors[c] = math.log((self.class_doc_counts[c] + 1) / (self.total_docs + len(self.classes)))
            total_words = self.class_totals[c] + vocab_size
            for word, idx in self.vocab.items():
                count = self.class_word_counts[c].get(word, 0)
                log_likelihoods[c][word] = math.log((count + 1) / total_words)

        # Build whitelist set
        whitelist = [item["name"] for item in dataset if item["category"] == "Core_OS_Essential"]

        # High-impact heuristic keywords
        heuristic_keywords = {
            "telemetry": "Telemetry_Tracking",
            "diag": "Telemetry_Tracking",
            "diagnostic": "Telemetry_Tracking",
            "ceip": "Telemetry_Tracking",
            "appraiser": "Telemetry_Tracking",
            "spynet": "Telemetry_Tracking",
            "supportassist": "OEM_Bloatware",
            "vantage": "OEM_Bloatware",
            "armoury": "OEM_Bloatware",
            "touchpoint": "OEM_Bloatware",
            "synapse": "OEM_Bloatware",
            "gupdate": "ThirdParty_Updater",
            "edgeupdate": "ThirdParty_Updater",
            "adobearm": "ThirdParty_Updater",
            "mapsbroker": "Consumer_Bloatware",
            "retaildemo": "Consumer_Bloatware",
            "cortana": "Consumer_Bloatware",
            "solitaire": "Consumer_Bloatware",
            "candycrush": "Consumer_Bloatware"
        }

        model_payload = {
            "version": "1.0.0",
            "model_type": "WinAurex_Multinomial_NaiveBayes_NeuralClassifier",
            "classes": self.classes,
            "vocab": self.vocab,
            "log_priors": log_priors,
            "log_likelihoods": log_likelihoods,
            "class_totals": self.class_totals,
            "whitelist": whitelist,
            "heuristic_keywords": heuristic_keywords,
            "metadata": {
                "trained_samples": len(dataset),
                "features_count": len(self.vocab),
                "author": "WinAurex Engineering Team"
            }
        }

        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(model_payload, f, indent=2)
        print(f"Model exported successfully to {out_path} ({os.path.getsize(out_path):,} bytes)")

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_file = os.path.join(root, "data", "training_dataset.json")
    if not os.path.exists(data_file):
        import dataset_builder
        dataset_builder.generate_dataset()

    with open(data_file, "r", encoding="utf-8") as f:
        dataset = json.load(f)

    trainer = WinAurexAiTrainer()
    print(f"[*] Training WinAurex AI on {len(dataset)} system component samples...")
    trainer.fit(dataset)
    acc, results = trainer.evaluate(dataset)
    print(f"[+] Model Training Completed! Internal Evaluation Accuracy: {acc:.2f}%")

    model_out = os.path.join(root, "model", "winaurex_ai_model.json")
    trainer.export_model(model_out, dataset)

if __name__ == "__main__":
    main()
