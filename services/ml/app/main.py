import logging
import os
import re

import httpx
import nltk
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.model.loader import model

logger = logging.getLogger(__name__)

nltk.download("stopwords", quiet=True)
stopwords_pt = nltk.corpus.stopwords.words("portuguese")

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

CATEGORIAS_VALIDAS = [
    "Arquitetura & Design",
    "Backend",
    "Carreira & Soft Skills",
    "Dados & ML",
    "DevOps & Infraestrutura",
    "Frontend",
    "Mobile",
    "Segurança",
    "Desconhecida",
]

CATEGORIAS_NORMALIZADAS = {re.sub(r"[^a-z0-9]", "", c.lower()): c for c in CATEGORIAS_VALIDAS}


def normalizar_categoria(resposta: str) -> str:
    resposta = resposta.strip().rstrip(".,;!?")
    if resposta in CATEGORIAS_VALIDAS:
        return resposta
    chave = re.sub(r"[^a-z0-9]", "", resposta.lower())
    return CATEGORIAS_NORMALIZADAS.get(chave, "Desconhecida")


GROQ_SYSTEM_PROMPT = """Você é um classificador de conteúdo técnico. Classifique o texto fornecido em exatamente uma das seguintes categorias:

- Arquitetura & Design
- Backend
- Carreira & Soft Skills
- Dados & ML
- DevOps & Infraestrutura
- Frontend
- Mobile
- Segurança

Responda APENAS com o nome da categoria. Não adicione explicações, pontuação ou formatação extra. Se o texto não se encaixar em nenhuma categoria, responda: Desconhecida"""

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
    threshold: float


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


def groq_fallback(texto: str, texto_limpo: str) -> dict:
    api_key = os.environ.get("GROQ_API_KEY", "")
    if not api_key:
        return {"categoria": "Desconhecida", "probabilidade": 0.0, "informacoes_adicionais": []}

    model_name = os.environ.get("GROQ_MODEL", "llama-3.1-8b-instant")
    max_tokens = int(os.environ.get("GROQ_MAX_TOKENS", "1024"))
    timeout = int(os.environ.get("GROQ_TIMEOUT", "5"))

    try:
        with httpx.Client(timeout=timeout) as client:
            resp = client.post(
                GROQ_API_URL,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model_name,
                    "messages": [
                        {"role": "system", "content": GROQ_SYSTEM_PROMPT},
                        {"role": "user", "content": texto},
                    ],
                    "max_tokens": max_tokens,
                    "temperature": 0.0,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            raw = data["choices"][0]["message"]["content"]
            categoria = normalizar_categoria(raw)

            keywords = extract_keywords(texto_limpo) if texto_limpo else []

            logger.info("groq_fallback ok: raw=%s -> categoria=%s", raw, categoria)

            return {
                "categoria": categoria,
                "probabilidade": 0.0,
                "informacoes_adicionais": keywords,
            }
    except Exception as e:
        logger.warning("groq_fallback erro: %s: %s", type(e).__name__, e)
        return {"categoria": "Desconhecida", "probabilidade": 0.0, "informacoes_adicionais": []}


@app.get("/health", response_model=HealthResponse)
def health():
    threshold_meta = model.metadata.get("threshold_recommended") if model.metadata else None
    default_threshold = str(threshold_meta) if threshold_meta else "0.5"
    raw = os.environ.get("ML_THRESHOLD", "")
    effective = float(raw) if raw.strip() else float(default_threshold)
    return HealthResponse(
        status="ok",
        modelo=model.modelo,
        modelo_carregado=model.pipeline is not None,
        modelo_ok=model.version_ok,
        categorias_disponiveis=model.categorias,
        threshold=effective,
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

    threshold_meta = model.metadata.get("threshold_recommended") if model.metadata else None
    default_threshold = str(threshold_meta) if threshold_meta else "0.5"
    raw = os.environ.get("ML_THRESHOLD", "")
    threshold = float(raw) if raw.strip() else float(default_threshold)
    texto_limpo = preprocess(req.texto)
    probs = model.pipeline.predict_proba([texto_limpo])[0]
    max_prob = float(probs.max())

    if max_prob < threshold:
        resultado = groq_fallback(req.texto, texto_limpo)
        return PredictResponse(**resultado)

    classe = model.pipeline.classes_[probs.argmax()]
    keywords = extract_keywords(texto_limpo)
    return PredictResponse(
        categoria=classe,
        probabilidade=max_prob,
        informacoes_adicionais=keywords,
    )
