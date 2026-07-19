# Contratos de API - TechMind

A comunicação entre serviços é:
- **Navegador → Rails:** HTML (Hotwire) para o usuário. API REST para chamadas AJAX.
- **Rails → FastAPI:** API REST (interna, rede Docker ou Render).

---

## 1. Rails → FastAPI (ML Service)

Chamada interna do Rails para o microsserviço de ML (síncrona, sem autenticação).

### POST /predict

Classifica um texto e retorna categoria, probabilidade e palavras-chave.

**Request:**

```json
{
  "texto": "Neste artigo são apresentados os conceitos básicos para criação de APIs REST utilizando a linguagem Ruby e o framework Rails."
}
```

**Response (200 OK — Classificação local):**

```json
{
  "categoria": "Backend",
  "probabilidade": 0.87,
  "informacoes_adicionais": ["Ruby", "Rails", "API", "REST", "ActiveRecord"]
}
```

**Response (200 OK — Fallback Groq, probabilidade 0.0):**

```json
{
  "categoria": "Dados & ML",
  "probabilidade": 0.0,
  "informacoes_adicionais": ["machine learning", "dados"]
}
```

**Response (200 OK — Sem categoria identificada):**

```json
{
  "categoria": "Desconhecida",
  "probabilidade": 0.32,
  "informacoes_adicionais": []
}
```

**Response (503 — Modelo indisponível):**

```json
{
  "error": "model_unavailable",
  "mensagem": "Modelo indisponível ou versão incorreta. Esperado: v1, carregado: v0"
}
```

### GET /health

Health check do ML Service.

**Response (200 OK):**

```json
{
  "status": "ok",
  "modelo": "logistic_regression_v2",
  "modelo_carregado": true,
  "modelo_ok": true,
  "categorias_disponiveis": ["Backend", "Frontend", "DevOps & Infraestrutura", "Dados & ML", "Mobile", "Segurança", "Arquitetura & Design", "Carreira & Soft Skills"]
}
```

---

## 2. Rails (Health Check)

### GET /health

Health check do Rails.

**Response (200 OK):**

```json
{
  "status": "ok",
  "database": "ok",
  "cache": "redis",
  "uptime": 3600
}
```

---

## 3. Status do Processamento (Conteúdos)

O campo `status` no banco segue:

| Status | Significado |
|---|---|
| `processing` | Rails está processando a classificação |
| `done` | Classificação concluída (ML local ou Groq) |
| `failed` | Falha na classificação |

Quando `status = "done"`, campos de classificação estão preenchidos.
Quando `status = "failed"`, campos de classificação retornam `null`.

---

## 4. CRUD de Conteúdos — Web (HTML)

### GET /conteudos/:id/edit
Formulário para editar título e texto de um conteúdo.

### PATCH /conteudos/:id
Atualiza título/texto e reclassifica o conteúdo.

**Redirect:** para `show` do conteúdo (sucesso) ou re-render `edit` (falha de validação).

### DELETE /conteudos/:id
Remove o conteúdo.

**Redirect:** para `index` com notice.

### POST /conteudos/:id/reclassify
Reclassifica o conteúdo com o texto atual (útil quando o modelo foi retreinado).

**Redirect:** para `show` do conteúdo com notice.

---

## 5. CRUD de Conteúdos — API (JSON)

### PATCH /api/v1/conteudos/:id
Atualiza título/texto e reclassifica o conteúdo.

**Request:**
```json
{
  "titulo": "Novo Título",
  "texto": "Novo texto técnico com mais de 10 caracteres"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "titulo": "Novo Título",
  "categoria": "Backend",
  "probabilidade": 0.87,
  "informacoes_adicionais": ["ruby", "rails", "api"],
  "status": "done",
  "created_at": "2026-07-19T01:00:00Z",
  "updated_at": "2026-07-19T02:00:00Z"
}
```

**Response (401):** `{ "error": "unauthorized", "mensagem": "Autenticação necessária" }`

### DELETE /api/v1/conteudos/:id
Remove o conteúdo.

**Response:** `204 No Content`

### POST /api/v1/conteudos/:id/reclassify
Reclassifica o conteúdo com o texto atual.

**Response (200 OK):** Mesmo schema do `PATCH` response.
