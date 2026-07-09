# Variáveis de Ambiente - TechMind

Todas as variáveis de ambiente do projeto, agrupadas por serviço. O arquivo `.env.example` na raiz do repositório contém os valores padrão.

---

## LocalStack

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `LOCALSTACK_AUTH_TOKEN` | Sim | — | Token de autenticação do LocalStack Pro |
| `AWS_ENDPOINT` | Não | `http://localstack:4566` | Endpoint interno do LocalStack na rede Docker |
| `AWS_REGION` | Não | `us-east-1` | Região AWS mockada |

## PostgreSQL

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `DB_HOST` | Sim | `postgres` | Host do PostgreSQL |
| `DB_PORT` | Não | `5432` | Porta do PostgreSQL |
| `DB_USER` | Sim | `techmind` | Usuário do banco |
| `DB_PASSWORD` | Sim | `techmind_dev` | Senha do banco |
| `DB_NAME` | Sim | `techmind_dev` | Nome do banco de dados |

O Rails lê essas credenciais prioritariamente do **Secrets Manager** (secret `techmind/db-credentials`). Se o LocalStack estiver indisponível, faz fallback para estas variáveis de ambiente. O Laravel sempre usa variáveis de ambiente diretamente.

## Valkey (Redis OSS)

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `REDIS_HOST` | Sim | `valkey` | Host do Valkey |
| `REDIS_PORT` | Não | `6379` | Porta do Valkey |

## Rails

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `SECRET_KEY_BASE` | Sim | — | Chave para sessões criptografadas e `Credentials` |
| `RAILS_MAX_THREADS` | Não | `5` | Threads do Puma |
| `RAILS_ENV` | Não | `development` | Ambiente Rails |
| `RAILS_LOG_TO_STDOUT` | Não | `true` | Log no stdout (container) |

## ML Service (FastAPI)

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `ML_THRESHOLD` | Não | `0.5` | Threshold mínimo de probabilidade para classificar; abaixo disso retorna `"Desconhecida"` |
| `MODEL_VERSION` | Não | `v1` | Versão esperada do modelo `.joblib`; validada no health check |

## Rate Limiting

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `RATE_LIMIT_MAX` | Não | `100` | Número máximo de requests por período |
| `RATE_LIMIT_PERIOD` | Não | `60` | Período em segundos para o rate limit |

## Cache

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `CACHE_TTL` | Não | `300` | TTL do cache da listagem no Valkey (em segundos) |

## Sidekiq

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `SIDEKIQ_RETRY_MAX` | Não | `3` | Número máximo de tentativas antes de marcar como `failed` |
| `SIDEKIQ_CONCURRENCY` | Não | `5` | Número de threads concorrentes do Sidekiq |

## Testes

| Variável | Obrigatória | Valor Padrão | Descrição |
|---|---|---|---|
| `DB_TEST_NAME` | Não | `techmind_test` | Nome do banco isolado para testes (profile `test`) |

---

## Relacionamento com outros documentos

| Documento | Conexão |
|---|---|
| `.env.example` | Arquivo com valores padrão versionado no repositório |
| `10-modelo-de-dados.md` | Secret no SM usa as mesmas chaves das variáveis de ambiente |
| `02-requisitos-nao-funcionais.md` (RNF07, RNF09) | Secrets e rate limiting |
