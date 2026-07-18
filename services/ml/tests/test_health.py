def test_health_returns_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert body["modelo_ok"] is True
    assert body["modelo_carregado"] is True


def test_health_lists_categories(client):
    resp = client.get("/health")
    categorias = resp.json()["categorias_disponiveis"]
    assert len(categorias) == 8
    assert "Backend" in categorias
    assert "Frontend" in categorias
