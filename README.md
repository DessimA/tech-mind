# TechMind - Organização Inteligente de Conhecimento

![Ruby](https://img.shields.io/badge/Ruby-3.3-CC342D?style=flat&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-D30001?style=flat&logo=rubyonrails&logoColor=white)
![RSpec](https://img.shields.io/badge/RSpec-60_passing-28A745?style=flat&logo=rubygems&logoColor=white)
![Pytest](https://img.shields.io/badge/Pytest-16_passing-28A745?style=flat&logo=pytest&logoColor=white)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo-FF6F00?style=flat&logo=hotwire&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![scikit--learn](https://img.shields.io/badge/scikit--learn-F7931E?style=flat&logo=scikitlearn&logoColor=white)
![Groq](https://img.shields.io/badge/Groq-LLM-F97316?style=flat&logo=groq&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat&logo=postgresql&logoColor=white)
![Valkey](https://img.shields.io/badge/Valkey-8-DC382D?style=flat&logo=valkey&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat&logo=docker&logoColor=white)
![Render](https://img.shields.io/badge/Render-Free-46E3B7?style=flat&logo=render&logoColor=white)

---

## Sobre o Projeto

O **TechMind** é um MVP de sistema de organização inteligente de conhecimento técnico. Construído com **Rails 8 full-stack** (HTML + Hotwire + API) e **FastAPI** para classificação ML híbrida — modelo local scikit-learn com fallback inteligente para **LLM via Groq API**.

```mermaid
flowchart LR
    A[Usuário] --> B["Rails 8 Full-Stack<br/>HTML + Hotwire + API<br/>Auth + Cache + ORM"]
    B --> C["FastAPI<br/>ML Service"]
    C --> D[scikit-learn<br/>TF-IDF + LogReg]
    C -.->|fallback| E[Groq API<br/>LLM Classifier]
    B --> F[PostgreSQL]
    B --> G[Valkey - Cache]

    style A fill:#4E342E,color:#fff,stroke:#fff
    style B fill:#6A1B9A,color:#fff,stroke:#fff
    style C fill:#2E7D32,color:#fff,stroke:#fff
    style D fill:#37474F,color:#fff,stroke:#fff
    style E fill:#F97316,color:#fff,stroke:#fff
    style F fill:#0D47A1,color:#fff,stroke:#fff
    style G fill:#E65100,color:#fff,stroke:#fff
```

---

## Arquitetura (2 Serviços)

| Componente | Tecnologia | Função |
|---|---|---|
| **Web App** | Ruby 3.3 + Rails 8.1 + Hotwire | Full-stack: HTML, API, Auth, Cache, ORM |
| **ML Service** | Python 3.11 + FastAPI + scikit-learn + Groq | Classificação híbrida (local + LLM fallback) |
| **Cache** | Valkey 8 / Redis Cloud | Cache de queries |
| **Banco** | PostgreSQL 16 (Supabase) | Persistência de dados |
| **Hospedagem** | Render + Supabase | Cloud gratuita (free tier) |

> 🎯 **Decisão arquitetural:** Em vez de manter dois frameworks web (Laravel + Rails), consolidamos tudo no **Rails 8 full-stack**. Rails entrega HTML com Hotwire (Turbo + Stimulus), provê API, autenticação e orquestração em um único serviço. Isso reduz o consumo de RAM de 1.5GB para 1GB, elimina latência de rede entre frontend/backend e simplifica a manutenção.

---

## Status dos Testes

| Serviço | Framework | Testes | Status |
|---|---|---|---|
| **Web (Rails)** | RSpec | **60 testes** (models + requests + auth) | ✅ Passando |
| **ML (FastAPI)** | Pytest | **16 testes** (predição + health + fallback Groq) | ✅ Passando |

---

## Como Executar (Desenvolvimento Local)

```bash
# 1. Clone e configure
git clone https://github.com/DessimA/tech-mind.git
cd tech-mind
cp .env.example .env

# 2. Edite .env e adicione as chaves necessárias
# GROQ_API_KEY=sua-chave-groq
# SECRET_KEY_BASE=$(rails secret)

# 3. Inicie os serviços
docker compose up -d

# 4. Acesse http://localhost:3000

# 5. Para rodar os testes:
docker compose run --rm web-test    # RSpec (60 testes)
docker compose run --rm ml pytest    # Pytest (16 testes)
```

---

## Documentação

Documentação completa em [`docs/`](docs/):

| Documento | Descrição |
|---|---|
| [00-visao-geral.md](docs/00-visao-geral.md) | Visão geral, objetivos e critérios de sucesso |
| [01-requisitos-funcionais.md](docs/01-requisitos-funcionais.md) | Requisitos funcionais (auth, conteúdo, classificação) |
| [02-requisitos-nao-funcionais.md](docs/02-requisitos-nao-funcionais.md) | Requisitos não funcionais + resiliência free tier |
| [03-arquitetura.md](docs/03-arquitetura.md) | Arquitetura C4: Rails full-stack + FastAPI |
| [04-historias-de-usuario.md](docs/04-historias-de-usuario.md) | Histórias de usuário |
| [05-stacks-e-justificativas.md](docs/05-stacks-e-justificativas.md) | Stacks e justificativas |
| [06-matriz-de-decisoes.md](docs/06-matriz-de-decisoes.md) | Matriz de decisões do projeto |
| [07-glossario.md](docs/07-glossario.md) | Glossário de termos técnicos |
| [08-taxonomia-ml.md](docs/08-taxonomia-ml.md) | Taxonomia de categorias + Groq fallback |
| [09-contratos-api.md](docs/09-contratos-api.md) | Contratos formais das APIs |
| [10-modelo-de-dados.md](docs/10-modelo-de-dados.md) | Schema do banco (users + conteudos) |
| [10-variaveis-de-ambiente.md](docs/10-variaveis-de-ambiente.md) | Variáveis de ambiente |
