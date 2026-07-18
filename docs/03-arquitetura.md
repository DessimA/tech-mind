# Arquitetura do Sistema - TechMind

## 1. Visão Geral (C4 Nível 1)

```mermaid
flowchart LR
    Usuario[("<b>Usuário</b><br/>Dev/Estudante\")] -->|Interage via navegador| TM[("<b>TechMind System</b><br/>Organização Inteligente<br/>de Conhecimento\")]

    style Usuario fill:#4E342E,color:#fff,stroke:#fff,stroke-width:2px
    style TM fill:#1A237E,color:#fff,stroke:#fff,stroke-width:3px
```

## 2. Diagrama de Containers (C4 Nível 2) — 2 Serviços

```mermaid
flowchart TB
    subgraph Render["Render Cloud - 2 Web Services Free"]
        RAILS["Rails 8 Full-Stack<br/>Porta 3000<br/>• HTML + Hotwire/Turbo<br/>• Auth (sessão)<br/>• CRUD Conteúdos<br/>• Cache (Redis/memória)<br/>• Pool DB: 1<br/>• 1 worker Puma"]
        ML["FastAPI ML Service<br/>Porta 8000<br/>• TF-IDF + LogReg<br/>• Groq fallback<br/>• 1 worker Uvicorn"]
    end

    subgraph Supabase["Supabase Cloud"]
        PG[("PostgreSQL<br/>500MB Free")]
    end

    subgraph RedisCloud["Redis Cloud / Valkey"]
        RC[("Redis / Valkey<br/>30MB Free")]
    end

    subgraph GroqCloud["Groq Cloud"]
        GROQ[("Groq API<br/>LLM Inference")]
    end

    RAILS -->|TCP :5432<br/>Pool: 1<br/>Timeout: 3s| PG
    RAILS -->|TCP :6379<br/>Timeout: 2s| RC
    RAILS -->|HTTP :8000<br/>POST /predict<br/>Timeout: 8s| ML
    ML -->|HTTPS<br/>Timeout: 5s| GROQ

    style RAILS fill:#6A1B9A,color:#fff,stroke:#fff,stroke-width:3px
    style ML fill:#2E7D32,color:#fff,stroke:#fff
    style PG fill:#0D47A1,color:#fff,stroke:#fff
    style RC fill:#E65100,color:#fff,stroke:#fff
    style GROQ fill:#F97316,color:#fff,stroke:#fff
    style Render fill:#1A237E,color:#fff,stroke:#diff
```

### Por que apenas 2 serviços?

| Motivo | Explicação |
|---|---|
| **Rails faz tudo** | HTML views (Hotwire), API JSON, auth (sessão), cache, ORM. Tudo num processo só. |
| **Sem Laravel** | Elimina redundância: dois frameworks web fazendo a mesma coisa. |
| **1 deploy vs 3** | Antes eram 3 web services (Laravel + Rails + FastAPI). Agora 2. |
| **Menos RAM** | 1GB vs 1.5GB de consumo no free tier. |
| **Menos latência** | Zero hops HTTP entre frontend e backend (mesmo processo). |
| **Menos complexidade** | Uma codebase, um ecossistema de gems, uma pipeline. |

## 3. Fluxo de Autenticação (Sessão Rails)

```mermaid
sequenceDiagram
    participant U as Usuário
    participant Rails as Rails (Full-Stack)
    participant DB as PostgreSQL

    Note over U,DB: Cadastro
    U->>Rails: Acessa /register
    Rails-->>U: Formulário HTML
    U->>Rails: POST /register
    Rails->>DB: INSERT user (bcrypt)
    Rails->>Rails: Sessão criada (cookie)
    Rails-->>U: Redirect /conteudos

    Note over U,DB: Login
    U->>Rails: Acessa /login
    Rails-->>U: Formulário HTML
    U->>Rails: POST /login
    Rails->>DB: Verifica bcrypt
    Rails->>Rails: Sessão criada (cookie)
    Rails-->>U: Redirect /conteudos
```

## 4. Fluxo de Classificação (Cadastro de Conteúdo)

```mermaid
sequenceDiagram
    participant U as Usuário
    participant Rails as Rails (Full-Stack)
    participant ML as FastAPI
    participant Groq as Groq API
    participant DB as PostgreSQL

    U->>Rails: POST /conteudos { titulo, texto }<br/>(sessão autenticada)
    Rails->>DB: INSERT (user_id, status: processing)
    
    Rails->>ML: POST /predict { texto }<br/>Timeout: 8s
    
    ML->>ML: TF-IDF + LogisticRegression
    
    alt Probabilidade >= threshold
        ML-->>Rails: { categoria, probabilidade, informacoes_adicionais }
    else Probabilidade < threshold
        ML->>Groq: Classifica via LLM<br/>Timeout: 5s
        Groq-->>ML: Categoria via LLM
        ML-->>Rails: { categoria, probabilidade: 0.0, informacoes_adicionais }
    else ML Service indisponível
        ML-->>Rails: Timeout/503
    end
    
    Rails->>DB: UPDATE status: done/failed
    Rails-->>U: Página com resultado
```

## 5. Limites de Recursos (Free Tier)

| Serviço | RAM | Workers | Pool DB | Timeouts |
|---|---|---|---|---|
| **Rails** | 512 MB | 1 Puma (1 thread) | **1 conexão** | DB: 3s / Redis: 2s / ML: 8s |
| **FastAPI** | 512 MB | 1 Uvicorn | Stateless | Groq: 5s |

> ⚠️ Supabase free tier limita a **2 conexões simultâneas**. Pool do Rails = 1 para nunca estourar.

## 6. Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---|---|---|
| Framework web | **Rails 8 full-stack** | HTML + API + Auth + ORM em 1 serviço |
| Frontend | **Hotwire (Turbo + Stimulus)** | SPA-like sem JavaScript pesado; convention over configuration |
| ML Service | **FastAPI + scikit-learn** | Python é padrão para ML; FastAPI é leve |
| Processamento | **Síncrono** | ML leve; sem filas (Render free não tem workers) |
| Autenticação | **Sessão Rails + bcrypt** | Nativo do Rails; sem JWT, sem complexidade |
| Banco | **Supabase PostgreSQL** | 500MB grátis, sem expiração |
| Cache | **Redis Cloud / memória** | 30MB grátis; fallback para cache em memória |
| Orquestração (dev) | **Docker Compose** | Simples, 1 comando para subir tudo |
