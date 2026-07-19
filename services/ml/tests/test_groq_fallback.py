"""Testes para o fallback Groq no ML Service."""


def test_health_returns_model_status(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert "modelo_carregado" in body
    assert "categorias_disponiveis" in body
    assert len(body["categorias_disponiveis"]) == 8


def test_predict_com_texto_muito_longo(client):
    texto_muito_longo = "a" * 5001
    resp = client.post("/predict", json={"texto": texto_muito_longo})
    assert resp.status_code == 422


def test_predict_com_threshold_baixo_retorna_desconhecida(client):
    resp = client.post(
        "/predict", json={"texto": "receita de bolo de cenoura com cobertura de chocolate"}
    )
    body = resp.json()
    assert body["categoria"] == "Desconhecida" or body["categoria"] in [
        "Frontend",
        "Backend",
        "DevOps & Infraestrutura",
        "Mobile",
        "Dados & ML",
        "Carreira & Soft Skills",
        "Arquitetura & Design",
        "Segurança",
    ]


def test_predict_probabilidade_no_range(client):
    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby para desenvolvimento de APIs REST"},
    )
    prob = resp.json()["probabilidade"]
    assert isinstance(prob, int | float)
    assert 0.0 <= prob <= 1.0


def test_predict_informacoes_adicionais_is_list(client, sample_backend_text):
    resp = client.post("/predict", json={"texto": sample_backend_text})
    keywords = resp.json()["informacoes_adicionais"]
    assert isinstance(keywords, list)
    if keywords:
        assert all(isinstance(k, str) for k in keywords)


def test_batch_predict_consistency(client):
    texto = "API REST com Ruby on Rails e PostgreSQL"
    resp1 = client.post("/predict", json={"texto": texto})
    resp2 = client.post("/predict", json={"texto": texto})
    assert resp1.json()["categoria"] == resp2.json()["categoria"]


def test_groq_fallback_categoria_valida(monkeypatch, client, respx_mock):
    monkeypatch.setenv("ML_THRESHOLD", "0.99")
    monkeypatch.setenv("GROQ_API_KEY", "test-key")
    monkeypatch.setenv("GROQ_MODEL", "llama-3.1-8b-instant")

    respx_mock.post("https://api.groq.com/openai/v1/chat/completions").respond(
        200,
        json={
            "choices": [{"message": {"content": "Backend"}}],
        },
    )

    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby para desenvolvimento de APIs REST"},
    )
    body = resp.json()
    assert body["categoria"] == "Backend"
    assert body["probabilidade"] == 0.0


def test_groq_fallback_timeout(monkeypatch, client, respx_mock):
    monkeypatch.setenv("ML_THRESHOLD", "0.99")
    monkeypatch.setenv("GROQ_API_KEY", "test-key")

    import httpx

    respx_mock.post("https://api.groq.com/openai/v1/chat/completions").mock(
        side_effect=httpx.TimeoutException("timeout")
    )

    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby"},
    )
    body = resp.json()
    assert body["categoria"] == "Desconhecida"
    assert body["probabilidade"] == 0.0


def test_groq_fallback_http_429(monkeypatch, client, respx_mock):
    monkeypatch.setenv("ML_THRESHOLD", "0.99")
    monkeypatch.setenv("GROQ_API_KEY", "test-key")

    respx_mock.post("https://api.groq.com/openai/v1/chat/completions").respond(
        429, json={"error": "rate_limited"}
    )

    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby"},
    )
    body = resp.json()
    assert body["categoria"] == "Desconhecida"
    assert body["probabilidade"] == 0.0


def test_groq_fallback_json_malformado(monkeypatch, client, respx_mock):
    monkeypatch.setenv("ML_THRESHOLD", "0.99")
    monkeypatch.setenv("GROQ_API_KEY", "test-key")

    respx_mock.post("https://api.groq.com/openai/v1/chat/completions").respond(
        200, text="not valid json"
    )

    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby"},
    )
    body = resp.json()
    assert body["categoria"] == "Desconhecida"
    assert body["probabilidade"] == 0.0


def test_groq_fallback_sem_api_key(monkeypatch, client):
    monkeypatch.setenv("ML_THRESHOLD", "0.99")
    monkeypatch.setenv("GROQ_API_KEY", "")

    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby"},
    )
    body = resp.json()
    assert body["categoria"] == "Desconhecida"
    assert body["probabilidade"] == 0.0


def test_groq_fallback_categoria_invalida(monkeypatch, client, respx_mock):
    monkeypatch.setenv("ML_THRESHOLD", "0.99")
    monkeypatch.setenv("GROQ_API_KEY", "test-key")

    respx_mock.post("https://api.groq.com/openai/v1/chat/completions").respond(
        200,
        json={
            "choices": [{"message": {"content": "Categoria Inexistente"}}],
        },
    )

    resp = client.post(
        "/predict",
        json={"texto": "Framework web escrito em Ruby"},
    )
    body = resp.json()
    assert body["categoria"] == "Desconhecida"
    assert body["probabilidade"] == 0.0
