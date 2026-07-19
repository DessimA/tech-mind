# ruff: noqa: N806

import json
import os
import re
from datetime import datetime
from pathlib import Path

import joblib
import nltk
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.pipeline import Pipeline

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "model.joblib"
METADATA_PATH = BASE_DIR / "model_metadata.json"
HISTORY_PATH = BASE_DIR / "data" / "training_history.json"

nltk.download("stopwords", quiet=True)
stopwords_pt = nltk.corpus.stopwords.words("portuguese")


def preprocess(texto: str) -> str:
    texto = texto.lower()
    texto = re.sub(r"[^\w\s]", "", texto)
    texto = re.sub(r"\d+", "", texto)
    tokens = texto.split()
    tokens = [t for t in tokens if t not in stopwords_pt and len(t) > 2]
    return " ".join(tokens)


def load_datasets(*paths: str) -> pd.DataFrame:
    frames = []
    for path in paths:
        df = pd.read_csv(path)
        frames.append(df)
        print(f"  {path}: {len(df)} exemplos")
    merged = pd.concat(frames, ignore_index=True)
    merged = merged.drop_duplicates(subset=["texto"])
    merged = merged.sample(frac=1, random_state=42).reset_index(drop=True)
    print(f"  Total (deduplicado): {len(merged)} exemplos")
    return merged


def compute_recommended_threshold(pipeline, df: pd.DataFrame, percentile: float = 0.10) -> float:
    probs = pipeline.predict_proba(list(df["texto_limpo"]))
    max_probs = probs.max(axis=1)
    preds = pipeline.classes_[probs.argmax(axis=1)]
    acertos = preds == df["categoria"].values
    conf_acertos = pd.Series(max_probs[acertos])
    return round(float(conf_acertos.quantile(percentile)), 4)


def main():
    real = os.environ.get("REAL_PATH", str(BASE_DIR / "data" / "train_real.csv"))
    original = os.environ.get("ORIGINAL_PATH", str(BASE_DIR / "data" / "train.csv"))

    print("Carregando datasets...")
    df = load_datasets(original, real)
    print(f"\nDistribuição:\n{df['categoria'].value_counts().to_string()}")

    print("\nPré-processando textos...")
    df["texto_limpo"] = df["texto"].apply(preprocess)

    X_train, X_test, y_train, y_test = train_test_split(
        df["texto_limpo"], df["categoria"], test_size=0.2, random_state=42, stratify=df["categoria"]
    )
    print(f"Treino: {len(X_train)} | Teste: {len(X_test)}")

    print("\nTreinando modelo...")
    pipeline = Pipeline(
        [
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), max_features=5000)),
            (
                "clf",
                LogisticRegression(max_iter=1000, C=1.0, solver="lbfgs", class_weight="balanced"),
            ),
        ]
    )
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"\nAcurácia no holdout: {acc:.4f}")
    print(classification_report(y_test, y_pred))

    scores = cross_val_score(pipeline, df["texto_limpo"], df["categoria"], cv=5)
    print(f"Cross-validation: {scores}")
    print(f"Média: {scores.mean():.4f} ± {scores.std():.4f}")

    print("\nAnalisando confiança do modelo...")
    recommended = compute_recommended_threshold(pipeline, df)
    print(f"Threshold recomendado (P10 dos acertos): {recommended}")

    model_version = os.environ.get("MODEL_VERSION", "v2")
    raw_threshold = os.environ.get("ML_THRESHOLD", "")
    ml_threshold = float(raw_threshold) if raw_threshold.strip() else float(recommended)

    probs_test = pipeline.predict_proba(list(X_test))
    max_probs_test = probs_test.max(axis=1)
    preds_test = pipeline.classes_[probs_test.argmax(axis=1)]
    acertos_test = preds_test == y_test.reset_index(drop=True)
    conf_acertos_test = pd.Series(max_probs_test[acertos_test])

    metadata = {
        "version": model_version,
        "trained_at": datetime.now().isoformat(),
        "categories": list(pipeline.classes_),
        "threshold": ml_threshold,
        "threshold_recommended": recommended,
        "accuracy_holdout": round(acc, 4),
        "cv_mean": round(scores.mean(), 4),
        "cv_std": round(scores.std(), 4),
        "confidence_mean": round(float(conf_acertos_test.mean()), 4),
        "confidence_median": round(float(conf_acertos_test.median()), 4),
        "confidence_p10": round(float(conf_acertos_test.quantile(0.10)), 4),
        "dataset": "train.csv + train_real.csv",
        "n_examples": len(df),
    }

    HISTORY_PATH.parent.mkdir(parents=True, exist_ok=True)
    history = []
    if HISTORY_PATH.exists():
        with open(HISTORY_PATH) as f:
            history = json.load(f)
    history.append(metadata)
    with open(HISTORY_PATH, "w") as f:
        json.dump(history, f, indent=2, ensure_ascii=False)

    with open(METADATA_PATH, "w") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    joblib.dump(pipeline, MODEL_PATH)

    print(f"\nModelo salvo: {MODEL_PATH}")
    print(f"Metadata: {METADATA_PATH}")
    print(f"Versão: {model_version}")
    print(f"Threshold: {ml_threshold}")
    print("Pronto!")


if __name__ == "__main__":
    main()
