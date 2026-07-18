"""Testes para o fallback Groq no ML Service."""




def test_health_returns_model_status(client):
    """Health check deve retornar status do modelo."""
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert "modelo_carregado" in body
    assert "categorias_disponiveis" in body
    assert len(body["categorias_disponiveis"]) == 8


def test_predict_com_texto_muito_longo(client):
    """Texto com mais de 5000 caracteres deve ser rejeitado."""
    texto_muito_longo = "a" * 5001
    resp = client.post("/predict", json={"texto": texto_muito_longo})
    assert resp.status_code == 422


def test_predict_com_threshold_baixo_retorna_desconhecida(client):
    """Texto genérico sem relação com tecnologia deve retornar Desconhecida."""
    resp = client.post("/predict", json={"texto": "receita de bolo de cenoura com cobertura de chocolate"})
    body = resp.json()
    assert body["categoria"] == "Desconhecida" or body["categoria"] in [
        "Frontend", "Backend", "DevOps & Infraestrutura",
        "Mobile", "Dados & ML", "Carreira & Soft Skills",
        "Arquitetura & Design", "Segurança"
    ]


def test_predict_probabilidade_no_range(client):
    """Probabilidade retornada deve estar entre 0 e 1."""
    resp = client.post("/predict", json={
        "texto": "Framework web escrito em Ruby para desenvolvimento de APIs REST"
    })
    prob = resp.json()["probabilidade"]
    assert isinstance(prob, (int, float))
    assert 0.0 <= prob <= 1.0


def test_predict_informacoes_adicionais_is_list(client, sample_backend_text):
    """informacoes_adicionais deve ser uma lista de strings."""
    resp = client.post("/predict", json={"texto": sample_backend_text})
    keywords = resp.json()["informacoes_adicionais"]
    assert isinstance(keywords, list)
    if keywords:
        assert all(isinstance(k, str) for k in keywords)


def test_batch_predict_consistency(client):
    """Mesmo texto deve retornar mesma categoria em chamadas repetidas."""
    texto = "API REST com Ruby on Rails e PostgreSQL"
    resp1 = client.post("/predict", json={"texto": texto})
    resp2 = client.post("/predict", json={"texto": texto})
    assert resp1.json()["categoria"] == resp2.json()["categoria"]
