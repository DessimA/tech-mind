# Variáveis de Ambiente - TechMind

## Rails (Web App)

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `SECRET_KEY_BASE` | Sim | — | Chave para sessões criptografadas |
| `RAILS_MAX_THREADS` | Não | `1` | Threads do Puma (1 para economizar RAM) |
| `WEB_CONCURRENCY` | Não | `0` | Workers do Puma (0 = 1 worker) |
| `RAILS_ENV` | Não | `development` | Ambiente Rails |
| `RAILS_LOG_TO_STDOUT` | Não | `true` | Log no stdout |
| `SESSION_DRIVER` | Não | `cookie` | **Usar `cookie` no Render** (filesystem efêmero perde sessões em arquivo) |

## Supabase / PostgreSQL

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `DB_HOST` | Sim | `postgres` | Host do PostgreSQL |
| `DB_PORT` | Não | `5432` | Porta |
| `DB_USER` | Sim | `techmind` | Usuário |
| `DB_PASSWORD` | Sim | `techmind_dev` | Senha |
| `DB_NAME` | Sim | `techmind_dev` | Nome do banco |
| `DB_POOL` | Não | `1` | **Pool de conexões (1 para respeitar limite de 2 do Supabase Free)** |
| `DB_TIMEOUT` | Não | `3` | Timeout em segundos para chamadas ao banco |

## Valkey / Redis Cloud

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `REDIS_HOST` | Sim | `valkey` | Host do Redis |
| `REDIS_PORT` | Não | `6379` | Porta |
| `REDIS_PASSWORD` | Não | — | Senha |
| `REDIS_TIMEOUT` | Não | `2` | Timeout em segundos |

## ML Service (FastAPI)

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `ML_THRESHOLD` | Não | `0.5` | Threshold para fallback Groq |
| `MODEL_VERSION` | Não | `v4` | Versão esperada do modelo |

## Groq API

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `GROQ_API_KEY` | Sim | — | Chave da API Groq |
| `GROQ_MODEL` | Não | `llama-3.1-8b-instant` | Modelo Groq |
| `GROQ_TIMEOUT` | Não | `5` | Timeout em segundos para chamada à Groq |
| `GROQ_MAX_TOKENS` | Não | `1024` | Máximo de tokens na resposta |

## Timeouts (Chamadas entre Serviços)

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `ML_TIMEOUT` | Não | `8` | Timeout Rails → ML Service (/predict) |
| `ML_HOST` | Não | `ml` | Host do ML Service (nome do serviço no Docker Compose) |
| `ML_PORT` | Não | `8000` | Porta do ML Service |

## Rate Limiting

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `RATE_LIMIT_MAX` | Não | `100` | Requests/minuto (rotas gerais) |
| `RATE_LIMIT_PERIOD` | Não | `60` | Período em segundos |
| `RATE_LIMIT_LOGIN_MAX` | Não | `10` | Tentativas de login/minuto |
| `RATE_LIMIT_LOGIN_PERIOD` | Não | `60` | Período em segundos |

## Cache

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `CACHE_TTL` | Não | `300` | TTL do cache (segundos) |

## Testes

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `DB_TEST_NAME` | Não | `techmind_test` | Banco isolado para testes |
| `SECRET_KEY_BASE` | Sim (testes) | `test-secret-key` | Chave para sessão em teste |

> 🧪 **93 testes RSpec** no Rails + **25 testes Pytest** no FastAPI. Execute com:
> ```bash
> docker compose run --rm web-test   # RSpec
> docker compose run --rm ml pytest   # Pytest
> ```
