# Contratos de API - TechMind

## 1. Laravel → Rails (server-side)

Todas as chamadas do Laravel para o Rails são feitas via HTTP server-side (PHP faz a requisição). Sem CORS.

### POST /v1/conteudos

Registra um novo conteúdo técnico e dispara a classificação assíncrona.

**Request:**

```json
{
  "titulo": "Introdução ao Ruby on Rails",
  "texto": "Neste artigo são apresentados os conceitos básicos..."
}
```

**Response (201 Created):**

```json
{
  "id": 42,
  "titulo": "Introdução ao Ruby on Rails",
  "status": "pending",
  "created_at": "2026-07-08T21:00:00Z"
}
```

### GET /v1/conteudos

Lista conteúdos cadastrados com paginação e busca opcional.

**Query params:**

| Parâmetro | Tipo | Default | Descrição |
|---|---|---|---|
| `page` | integer | 1 | Número da página |
| `per_page` | integer | 20 | Itens por página (max 100) |
| `q` | string | opcional | Busca por título ou palavras-chave |
| `sort` | string | `created_at_desc` | Ordenação (`created_at_desc`, `created_at_asc`, `titulo_asc`) |

**Response (200 OK):**

```json
{
  "data": [
    {
      "id": 42,
      "titulo": "Introdução ao Ruby on Rails",
      "categoria": "Backend",
      "probabilidade": 0.87,
      "informacoes_adicionais": ["Ruby", "Rails", "API"],
      "status": "done",
      "created_at": "2026-07-08T21:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

### GET /v1/conteudos/:id

Detalhes completos de um conteúdo.

**Response (200 OK):**

```json
{
  "id": 42,
  "titulo": "Introdução ao Ruby on Rails",
  "texto": "Neste artigo são apresentados os conceitos básicos...",
  "categoria": "Backend",
  "probabilidade": 0.87,
  "informacoes_adicionais": ["Ruby", "Rails", "API"],
  "status": "done",
  "created_at": "2026-07-08T21:00:00Z",
  "updated_at": "2026-07-08T21:00:30Z"
}
```

### Erros

Todas as APIs Rails retornam erros no formato padronizado abaixo.

**Response (404 Not Found):**

```json
{
  "error": "not_found",
  "mensagem": "Conteúdo não encontrado"
}
```

**Response (422 Unprocessable Entity):**

```json
{
  "error": "validation_failed",
  "mensagem": "Título é obrigatório",
  "detalhes": {
    "titulo": ["não pode ficar em branco"]
  }
}
```

### GET /v1/health

Health check do Rails + dependências.

**Response (200 OK):**

```json
{
  "status": "ok",
  "database": "ok",
  "sidekiq": "ok",
  "uptime": 3600
}
```

---

## 2. Rails → FastAPI (ML)

Chamada interna do Sidekiq worker para o microsserviço de ML.

### POST /predict

Classifica um texto e retorna categoria, probabilidade e palavras-chave.

**Request:**

```json
{
  "texto": "Neste artigo são apresentados os conceitos básicos para criação de APIs REST utilizando a linguagem Ruby e o framework Rails."
}
```

**Response (200 OK):**

```json
{
  "categoria": "Backend",
  "probabilidade": 0.87,
  "informacoes_adicionais": ["Ruby", "Rails", "API", "REST", "ActiveRecord"]
}
```

**Response - Threshold não atingido:**

```json
{
  "categoria": "Desconhecida",
  "probabilidade": 0.32,
  "informacoes_adicionais": []
}
```

### GET /health

Health check do FastAPI + modelo.

**Response (200 OK):**

```json
{
  "status": "ok",
  "modelo": "logistic_regression_v1",
  "modelo_carregado": true,
  "categorias_disponiveis": ["Backend", "Frontend", "DevOps & Infraestrutura", "Dados & ML", "Mobile", "Segurança", "Arquitetura & Design", "Carreira & Soft Skills"]
}
```

---

## 3. Laravel (Frontend)

### GET /health

Health check do Laravel.

**Response (200 OK):**

```json
{
  "status": "ok"
}
```

---

## 4. Status do Processamento

O campo `status` no banco e nas respostas da API segue este ciclo:

| Status | Significado |
|---|---|
| `pending` | Conteúdo cadastrado, aguardando classificação |
| `processing` | Sidekiq worker está processando |
| `done` | Classificação concluída com sucesso |
| `failed` | Falha após 3 tentativas de classificação |

Quando `status = "failed"`, os campos `categoria` e `informacoes_adicionais` retornam valores padrão:

```json
{
  "categoria": null,
  "probabilidade": null,
  "informacoes_adicionais": []
}
```
