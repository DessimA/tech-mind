import os
import re

import nltk
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.model.loader import model

nltk.download("stopwords", quiet=True)
stopwords_pt = nltk.corpus.stopwords.words("portuguese")

app = FastAPI(title="TechMind ML Service", version="1.0.0")


class PredictRequest(BaseModel):
    texto: str = Field(..., min_length=10, max_length=5000)


class PredictResponse(BaseModel):
    categoria: str
    probabilidade: float
    informacoes_adicionais: list[str]


class HealthResponse(BaseModel):
    status: str
    modelo: str
    modelo_carregado: bool
    modelo_ok: bool
    categorias_disponiveis: list[str]


@app.on_event("startup")
def startup():
    model.load()


def preprocess(texto: str) -> str:
    texto = texto.lower()
    texto = re.sub(r"[^\w\s]", "", texto)
    texto = re.sub(r"\d+", "", texto)
    tokens = [t for t in texto.split() if t not in stopwords_pt and len(t) > 2]
    return " ".join(tokens)


def extract_keywords(texto_limpo: str, top_n: int = 5) -> list[str]:
    vectorizer = model.pipeline.named_steps["tfidf"]
    tfidf_matrix = vectorizer.transform([texto_limpo])
    feature_names = vectorizer.get_feature_names_out()
    sorted_idx = tfidf_matrix[0].toarray().argsort()[0, ::-1]
    return [feature_names[i] for i in sorted_idx[:top_n] if tfidf_matrix[0, i] > 0]


@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(
        status="ok",
        modelo=model.modelo,
        modelo_carregado=model.pipeline is not None,
        modelo_ok=model.version_ok,
        categorias_disponiveis=model.categorias,
    )


@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    if not model.version_ok:
        expected = os.environ.get("MODEL_VERSION", "v1")
        actual = "unknown"
        if model.metadata:
            actual = model.metadata.get("version", "unknown")
        raise HTTPException(
            status_code=503,
            detail={
                "error": "model_unavailable",
                "mensagem": f"Modelo indisponível ou versão incorreta. Esperado: {expected}, carregado: {actual}",
            },
        )

    threshold = float(os.environ.get("ML_THRESHOLD", "0.5"))
    texto_limpo = preprocess(req.texto)
    probs = model.pipeline.predict_proba([texto_limpo])[0]
    max_prob = float(probs.max())

    if max_prob < threshold:
        return PredictResponse(
            categoria="Desconhecida",
            probabilidade=max_prob,
            informacoes_adicionais=[],
        )

    classe = model.pipeline.classes_[probs.argmax()]
    keywords = extract_keywords(texto_limpo)
    return PredictResponse(
        categoria=classe,
        probabilidade=max_prob,
        informacoes_adicionais=keywords,
    )
