# Requisitos Não Funcionais - TechMind

## RNF01 - Ambiente Conteinerizado (desenvolvimento local)

**Descrição:** Em desenvolvimento local, todos os serviços rodam via Docker.

**Critérios de Aceitação:**
- `docker compose up` inicia todo o ecossistema
- Nenhuma instalação de Ruby, Python ou PostgreSQL na máquina host
- Volumes montados permitem hot reload

## RNF02 - Deploy em Cloud Gratuita (2 Serviços)

**Descrição:** O sistema usa exclusivamente free tiers, com apenas 2 serviços web.

**Critérios de Aceitação:**
- **Rails 8 full-stack** como web service no Render (512MB RAM, free tier)
- **FastAPI** como web service no Render (512MB RAM, free tier)
- PostgreSQL via Supabase (500MB gratuitos, sem expiração)
- Redis via Redis Cloud (30MB gratuitos) ou cache em memória
- Groq API gratuita para fallback de classificação
- Custo total de hospedagem: R$ 0/mês

## RNF03 - Observabilidade

**Descrição:** O sistema deve expor health checks e logs.

**Critérios de Aceitação:**
- Rails: `GET /health` com status do banco e Redis
- FastAPI: `GET /health` com status do modelo e Groq
- Logs em JSON em produção

## RNF04 - Performance e Cache

**Descrição:** Consultas frequentes otimizadas com cache.

**Critérios de Aceitação:**
- Listagens cacheadas (Redis ou memória)
- Cache invalidado ao cadastrar novo conteúdo
- Tempo de resposta cacheados < 50ms

## RNF05 - Resiliência

**Descrição:** Tolerância a falhas nos serviços.

**Critérios de Aceitação:**
- Se ML falha, conteúdo salvo como `failed` (dados não perdidos)
- Se Groq falha, ML retorna "Desconhecida"
- Se Redis falha, Rails usa cache em memória
- **Timeout ML: 8s** — não trava o request do usuário
- **Pool DB: 1** — respeita limite de 2 conexões do Supabase free tier

## RNF06 - Testes Automatizados

**Descrição:** Testes em cada serviço.

**Critérios de Aceitação:**
  - Rails: **93 testes RSpec** — models (User, Conteudo), requests (Web + API: CRUD completo + reclassify)
  - FastAPI: **25 testes Pytest** — predição, health check, fallback Groq, normalização de categoria
- FactoryBot para criação de dados de teste
- WebMock para stubs de chamadas HTTP externas (ML Service)
- `rails-i18n` para mensagens de validação em português

## RNF07 - Segurança

**Descrição:** Senhas hasheadas (bcrypt), sessão criptografada.

**Critérios de Aceitação:**
- Senhas com bcrypt via `has_secure_password`
- Sessão Rails em cookie criptografado (SESSION_DRIVER=cookie no Render)
- `SECRET_KEY_BASE` configurado como variável de ambiente
- Nenhuma credencial hardcoded
- Chave Groq API via `GROQ_API_KEY`

## RNF08 - Versionamento de API

**Descrição:** Endpoints da API prefixados com `/api/v1/` (para consumo interno e futuros clientes). Health check também disponível em `/v1/health`.

**Rotas versionadas:**

| Rota | Prefixo | Controller |
|---|---|---|
| `GET /api/v1/conteudos` | `/api/v1/` | `Api::V1::ConteudosController#index` |
| `GET /api/v1/conteudos/:id` | `/api/v1/` | `Api::V1::ConteudosController#show` |
| `POST /api/v1/conteudos` | `/api/v1/` | `Api::V1::ConteudosController#create` |
| `GET /v1/health` | `/v1/` | `HealthController#show` |

## RNF09 - Rate Limiting

**Descrição:** Proteção contra abuso.

**Critérios de Aceitação:**
- 100 requests/minuto para rotas de conteúdo
- **10 requests/minuto para login** (anti brute force)
- Configurável via variáveis de ambiente
- Resposta 429 Too Many Requests

## RNF10 - Resiliência Free Tier

**Descrição:** Operação resiliente dentro dos limites do free tier.

**Critérios de Aceitação:**
- **Timeouts configuráveis** em todas as chamadas HTTP
- **Pool PostgreSQL = 1** (respeitar limite de 2 conexões do Supabase)
- **1 worker/thread por serviço** (512MB RAM)
- **Degradação graciosa:** se ML falha, conteúdo vira `failed`
- **Sessão via cookie** (Render Free tem filesystem efêmero)
- **Blast radius:** falha do ML não derruba o Rails

> 📖 **Detalhes completos:** [`docs/11-responsabilidades-e-resiliencia.md`](11-responsabilidades-e-resiliencia.md)
