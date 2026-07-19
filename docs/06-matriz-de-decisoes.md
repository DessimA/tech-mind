# Matriz de Decisões - TechMind

| # | Decisão | Escolha | Status | Justificativa |
|---|---|---|---|---|
| 1 | **Framework web** | **Rails 8 full-stack** | Fechada | HTML + API + Auth + ORM em 1 serviço. **Laravel removido** — eliminou redundância. |
| 2 | Frontend | Hotwire (Turbo + Stimulus) | Fechada | SPA-like sem bundlers; padrão Rails 8; 0 dependências npm |
| 3 | Autenticação | Sessão Rails + bcrypt | Fechada | Nativa do Rails, sem JWT, sem complexidade extra |
| 4 | ML Service | FastAPI + scikit-learn + Groq | Fechada | Python para ML; FastAPI leve; Groq como fallback gratuito |
| 5 | Processamento | Síncrono (sem filas) | Fechada | ML leve (~ms); Render free não tem background workers |
| 6 | Cache | Redis Cloud 30MB / memória | Fechada | Cache rápido; fallback para cache em memória do Rails |
| 7 | Banco | Supabase (500MB grátis) | Fechada | PostgreSQL sem expiração para MVP |
| 8 | Hospedagem | Render (2 web services) | Fechada | Rails + FastAPI = 2 serviços apenas |
| 9 | Secrets | Variáveis de ambiente | Fechada | Render gerencia env vars nativamente |
| 10 | Testes | RSpec / Pytest | Fechada | Frameworks padrão de cada ecossistema |
| 11 | Versionamento API | `/v1/` prefixo | Fechada | Boa prática para evolução da API |
| 12 | Rate Limiting | 100 req/min (geral) + 10 req/min (login) | Fechada | Proteção contra abuso e brute force |
| 13 | Sessão | Cookie criptografado | Fechada | Sobrevive a restarts do Render (filesystem efêmero) |
| 14 | Pool DB | 1 conexão | Fechada | Respeita limite de 2 do Supabase free tier |
| 15 | Workers | 1 worker/thread por serviço | Fechada | 512MB RAM é insuficiente para mais |

### Decisões removidas (sobras da arquitetura anterior)

| Decisão | Status Anterior | Motivo da Remoção |
|---|---|---|
| Laravel como frontend | Removida | Rails full-stack substitui |
| JWT entre Laravel e Rails | Removida | Sessão Rails nativa elimina necessidade |
| Sidekiq / Workers assíncronos | Removida | ML síncrono é suficiente e mais simples |
| LocalStack / Terraform | Removida | Sem AWS; secrets via env vars |
| S3 (armazenamento de textos) | Removida | Texto já está no PostgreSQL |
| credentials.yml.enc / master.key | Removida | App usa SECRET_KEY_BASE via env var; Rails credentials system era resquício do template |

### Decisões Postergadas (Pós-MVP)

| Decisão | Motivo do Adiamento |
|---|---|
| CI/CD (GitHub Actions) | Quando houver testes estáveis e deploy definido |
| Frontend SPA (React/Vue) | Hotwire é suficiente para MVP |
| Monitoramento avançado (Grafana) | Logs JSON + health checks são suficientes |
| Pipeline de retreinamento de ML | Modelo treinado no notebook; retreinamento com dados reais depois |
