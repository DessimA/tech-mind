# Instruções para Agentes — TechMind

> Regras obrigatórias para qualquer agente que trabalhe neste repositório. Reflete a arquitetura atual (pós-refatoração que removeu Laravel, LocalStack, Terraform, S3, Secrets Manager, Sidekiq e JWT).

---

## 1. Arquitetura (2 serviços)

| Serviço | Stack | Responsabilidade |
|---|---|---|
| **Web App** | Ruby 3.3 + Rails 8.1 + Hotwire | HTML, API JSON, autenticação, cache, ORM, orquestração |
| **ML Service** | Python 3.11 + FastAPI + scikit-learn + Groq | Classificação híbrida (local + fallback LLM) — **stateless** |

PostgreSQL e Valkey/Redis são gerenciados **apenas pelo Rails**. ML Service não conhece o usuário.

Antes de qualquer mudança estrutural, leia `docs/00-visao-geral.md` até `docs/11-responsabilidades-e-resiliencia.md`. Esses documentos têm precedência sobre suposições genéricas.

---

## 2. Comandos essenciais (100% Docker)

```bash
docker compose up -d                    # Sobe tudo
docker compose run --rm web-test        # RSpec
docker compose run --rm ml pytest       # Pytest
bin/lint                                # RuboCop + Brakeman + Ruff lint + Ruff format
docker compose exec web bash            # Terminal Rails
docker compose exec ml bash             # Terminal ML
```

Ordem de boot: `postgres` + `valkey` (saudáveis) → `web` + `ml`. Não adicionar dependências sem atualizar healthchecks.

---

## 3. Regras críticas (não negociáveis)

- **User isolation.** Todo acesso a `Conteudo` via `current_user.conteudos` ou `@api_user.conteudos`. Nunca `Conteudo.find` diretamente.
- **Timeouts explícitos.** Toda chamada síncrona entre serviços tem timeout. Nunca adicionar chamada de rede sem um.
- **ML Service é stateless.** Sem banco, cache local, sessão ou arquivo persistente. Dados pertencem ao Rails.
- **Respostas de serviços externos** usam `Struct` com `success?`/`data`/`error` (ver `MlService::Response`).
- **Multi-step writes** (criar + chamar externo + atualizar + invalidar cache) dentro de `ActiveRecord::Base.transaction`.
- **Cache scoped por usuário:** `conteudos:user:{user_id}:page:{page}:q:{q}:sort:{sort}`. Fallback `:memory_store` se `REDIS_HOST` vazio.
- **Busca em array** usa `@>` sobre `informacoes_adicionais` (índice GIN). **Nunca** `= ANY()` — não aciona o índice GIN.
- **Não reintroduzir** sem decisão formal em `docs/06-matriz-de-decisoes.md`: Laravel, JWT entre serviços, Sidekiq/filas, LocalStack, Terraform, S3, Secrets Manager.

---

## 4. Limites do free tier (não aumentar sem verificar contrato)

| Recurso | Limite |
|---|---|
| Pool PG (Rails) | 1 |
| Puma threads | `RAILS_MAX_THREADS=1`, `WEB_CONCURRENCY=0` |
| Uvicorn workers | 1 |
| Timeout Rails→ML | 8s |
| Timeout ML→Groq | 5s |
| Timeout Rails→PG | 3s |
| Timeout Rails→Redis | 2s |
| Rate limit geral | 100 req/min |
| Rate limit `/login` | 10 req/min |
| Paginação | Kaminari, 20/página, max 100 |

---

## 5. Padrões de código

- **Sem comentários inline.** Código autoexplicativo. Mudanças não triviais → markdown companheiro no PR.
- **Decisões arquiteturais** sempre registradas em `docs/06-matriz-de-decisoes.md`.

### Ruby / Rails
- RuboCop: base `rubocop-rails-omakase`, overrides em `services/web/.rubocop.yml`. Brakeman.
- Lógica de negócio em `app/services/`, `app/models/`, `app/serializers/`.
- Comportamento repetido entre controllers → `app/controllers/concerns/` (ex.: `Cacheable`).
- Enums para estado (`status_conteudo`), nunca strings.
- `rescue_from` nos API controllers para erros previsíveis (`RecordNotFound`, `RecordInvalid`).
- Strong params sempre.

### Python / FastAPI
- Ruff (lint + format) configurado em `services/ml/pyproject.toml`. Regras: `E,W,F,I,N,UP,S,B,SIM,ARG`.
- Type hints obrigatórios em funções públicas.
- Modelo `.joblib` carregado uma vez no startup, nunca por request.
- Endpoints com `pydantic.BaseModel` explícito e validação de tamanho.

### Frontend (Hotwire)
- `importmap` — sem Node.js/Webpack/Vite sem decisão formal.
- Tokens visuais seguem `docs/modulos/design-system.md`.
- Turbo Frames/Streams antes de JavaScript customizado.

---

## 6. Testes

| Serviço | Framework | Comando |
|---|---|---|
| Rails | RSpec + FactoryBot + WebMock | `docker compose run --rm web-test` |
| ML | Pytest | `docker compose run --rm ml pytest` |

- Toda chamada HTTP externa em teste é mockada com WebMock (nunca bater na rede real).
- Testes de request cobrem: sucesso, auth ausente, isolamento entre usuários, falha da dependência externa.
- CI (`.github/workflows/ci.yml`): 4 jobs — `lint-ruby`, `lint-python`, `test-ruby`, `test-python`. Todos precisam passar.
- Ao alterar dataset de treino ou taxonomia (`docs/08-taxonomia-ml.md`), validar que os testes de ML batem com `model_metadata.json`.

---

## 7. Segurança

- Autenticação: `has_secure_password` + bcrypt, sessão em cookie criptografado (`SESSION_DRIVER=cookie`).
- Rate limiting: `Rack::Attack` (configurável por env var, nunca hardcoded).
- `config/initializers/filter_parameter_logging.rb` filtra `passw, email, secret, token, _key`.
- Validação de tamanho em duas camadas: constraint na migration + `validates` no model.
- **Nota:** `SECURITY.md` ainda cita Terraform e LocalStack no escopo — precisa ser atualizado (foram removidos).

---

## 8. Commits e PR

Conventional Commits: `tipo(escopo): descrição`. Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
Branch: `tipo/descricao-curta`.

Checklist de PR (ver também `.github/PULL_REQUEST_TEMPLATE.md`):
- [ ] `bin/lint` sem novas ofensas
- [ ] Testes passando via Docker (`web-test` + `ml pytest`)
- [ ] Nenhum comentário inline adicionado
- [ ] Toda query nova escopada por usuário
- [ ] Toda chamada de rede nova tem timeout + fallback definido
- [ ] Nenhum secret/credencial commitado
- [ ] Mudança arquitetural registrada em `docs/06-matriz-de-decisoes.md`
- [ ] Se mexeu em `informacoes_adicionais`, validado com `EXPLAIN ANALYZE`

---

## 9. Resiliência (blast radius)

- PG fora → Rails retorna 503.
- Redis fora → fallback para `:memory_store` (sem diferença perceptível).
- ML Service timeout/erro → Conteúdo salvo como `failed`, dados preservados.
- Groq fora → ML retorna "Desconhecida", classificação local continua.
- Todo dado persistente fica no PostgreSQL; ambos os serviços são recriáveis.
- Nenhum serviço depende de outro para inicializar.
