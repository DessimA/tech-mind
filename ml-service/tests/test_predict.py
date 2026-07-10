def test_predict_returns_category(client, sample_backend_text):
    resp = client.post("/predict", json={"texto": sample_backend_text})
    assert resp.status_code == 200
    body = resp.json()
    assert body["categoria"] == "Backend"
    assert body["probabilidade"] > 0
    assert isinstance(body["informacoes_adicionais"], list)


def test_predict_returns_keywords(client, sample_backend_text):
    resp = client.post("/predict", json={"texto": sample_backend_text})
    keywords = resp.json()["informacoes_adicionais"]
    assert len(keywords) > 0
    assert any("ruby" in kw.lower() for kw in keywords)


def test_predict_with_frontend_text(client, sample_frontend_text):
    resp = client.post("/predict", json={"texto": sample_frontend_text})
    assert resp.status_code == 200
    assert resp.json()["categoria"] == "Frontend"


def test_predict_with_devops_text(client):
    texto = "Pipeline CI/CD com GitHub Actions para deploy automatizado em Kubernetes"
    resp = client.post("/predict", json={"texto": texto})
    assert resp.status_code == 200
    assert resp.json()["categoria"] == "DevOps & Infraestrutura"


def test_predict_rejects_short_text(client):
    resp = client.post("/predict", json={"texto": "curto"})
    assert resp.status_code == 422


def test_predict_rejects_empty_text(client):
    resp = client.post("/predict", json={"texto": ""})
    assert resp.status_code == 422


def test_predict_probabilidade_is_float(client, sample_backend_text):
    resp = client.post("/predict", json={"texto": sample_backend_text})
    prob = resp.json()["probabilidade"]
    assert isinstance(prob, float)
    assert 0.0 <= prob <= 1.0


def test_predict_returns_valid_category(client):
    texto = "texto completamente aleatorio sem relacao com tecnologia"
    resp = client.post("/predict", json={"texto": texto})
    body = resp.json()
    assert body["categoria"] in [
        "Desconhecida", "Frontend", "Backend", "DevOps & Infraestrutura",
        "Mobile", "Dados & ML", "Carreira & Soft Skills", "Arquitetura & Design",
        "Segurança"
    ]
