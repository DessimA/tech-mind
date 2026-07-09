# Arquitetura do Sistema - TechMind

## 1. Visão Geral (C4 Nível 1 - Contexto)

```mermaid
flowchart LR
    Usuario[("<b>Usuário</b><br/>Dev/Estudante)"] -->|Interage via navegador| TM[("<b>TechMind System</b><br/>Organização Inteligente<br/>de Conhecimento")]

    style Usuario fill:#4E342E,color:#fff,stroke:#fff,stroke-width:2px
    style TM fill:#1A237E,color:#fff,stroke:#fff,stroke-width:3px
```

O usuário interage com o sistema via navegador web para cadastrar e consultar conteúdos técnicos.

## 2. Diagrama de Containers (C4 Nível 2)

```mermaid
flowchart TB
    subgraph Docker [Docker Compose Network]
        subgraph Frontend [Frontend]
            LARAVEL[("Laravel PHP<br/>Porta 80")]
        end

        subgraph Backend [Backend]
            RAILS[("Rails API<br/>Porta 3000")]
            SIDEKIQ[("Sidekiq Workers<br/>Processamento Assíncrono")]
        end

        subgraph ML [ML Service]
            FASTAPI[("FastAPI<br/>Porta 8000")]
        end

        subgraph Dados [Dados]
            PG[("PostgreSQL<br/>Porta 5432")]
            VALKEY[("Valkey<br/>Porta 6379<br/>Cache + Fila")]
        end

        subgraph AWS [LocalStack Pro - Porta 4566]
            S3[("S3 Bucket<br/>techmind-content")]
            SM[("Secrets Manager")]
        end

        subgraph IaC [Infraestrutura]
            TF[("Terraform Container")]
        end
    end

    LARAVEL -->|POST /v1/conteudos| RAILS
    LARAVEL -->|GET /v1/conteudos| RAILS
    RAILS -->|Salva/Consulta| PG
    RAILS -->|Cache| VALKEY
    RAILS -->|Enfileira jobs| VALKEY
    SIDEKIQ -->|Consome fila| VALKEY
    SIDEKIQ -->|POST /predict| FASTAPI
    SIDEKIQ -->|Atualiza status| PG
    TF -->|Provisiona| S3
    TF -->|Provisiona| SM
    RAILS -->|Salva artefatos| S3
    RAILS -->|Lê secrets| SM

    style Docker fill:#1A237E,color:#fff,stroke:#fff
    style Frontend fill:#0D47A1,color:#fff,stroke:#fff
    style LARAVEL fill:#1565C0,color:#fff,stroke:#fff
    style Backend fill:#4A148C,color:#fff,stroke:#fff
    style RAILS fill:#6A1B9A,color:#fff,stroke:#fff
    style SIDEKIQ fill:#8E24AA,color:#fff,stroke:#fff
    style ML fill:#1B5E20,color:#fff,stroke:#fff
    style FASTAPI fill:#2E7D32,color:#fff,stroke:#fff
    style Dados fill:#004D40,color:#fff,stroke:#fff
    style PG fill:#0D47A1,color:#fff,stroke:#fff
    style VALKEY fill:#E65100,color:#fff,stroke:#fff
    style AWS fill:#01579B,color:#fff,stroke:#fff,stroke-dasharray: 5 5
    style S3 fill:#00838F,color:#fff,stroke:#fff
    style SM fill:#00838F,color:#fff,stroke:#fff
    style IaC fill:#263238,color:#fff,stroke:#fff
    style TF fill:#37474F,color:#fff,stroke:#fff
```

## 3. Fluxo de Dados (Cadastro + Classificação)

```mermaid
sequenceDiagram
    participant U as Usuário
    participant FE as Laravel
    participant BE as Rails
    participant SQ as Sidekiq
    participant ML as FastAPI
    participant DB as PostgreSQL
    participant VK as Valkey
    participant LS as LocalStack S3

    U->>FE: Preenche formulário
    FE->>BE: POST /v1/conteudos { título, texto }
    BE->>DB: INSERT (status: pending)
    BE->>VK: Invalida cache de listagem
    BE-->>FE: 201 Created
    FE-->>U: Feedback visual

    BE->>SQ: Enfileira ClassificationJob
    SQ->>ML: POST /predict { texto }
    ML->>ML: TF-IDF + LogisticRegression
    ML-->>SQ: { categoria, probabilidade, keywords }
    SQ->>DB: UPDATE status: done, categoria, keywords
    SQ->>LS: Salva texto original no S3
```

## 4. Fluxo de Dados (Consulta)

```mermaid
sequenceDiagram
    participant U as Usuário
    participant FE as Laravel
    participant BE as Rails
    participant VK as Valkey
    participant DB as PostgreSQL

    U->>FE: Acessa listagem / busca
    FE->>BE: GET /v1/conteudos?page=1&q=ruby
    BE->>VK: GET cache key

    alt Cache Hit
        VK-->>BE: Dados cacheados
    else Cache Miss
        BE->>DB: SELECT com paginação e filtro
        DB-->>BE: Resultados
        BE->>VK: SET cache (TTL: 5 min)
    end

    BE-->>FE: JSON paginado
    FE-->>U: Página renderizada
```

## 5. Decisões Arquiteturais

| Decisão | Opção | Justificativa |
|---|---|---|
| Orquestração | Docker Compose | Simplicidade para MVP, 1 comando para subir tudo |
| API Gateway | Nenhum (direto) | MVP sem necessidade de gateway; reconsiderar com autenticação |
| Banco relacional | PostgreSQL | Maturidade, ecossistema Rails robusto, recursos do LocalStack |
| Cache + Fila | Valkey (Redis OSS) | Compatibilidade total com Sidekiq, open source |
| ML assíncrono | Sidekiq job | Não bloquear o request do usuário; resiliência com retry |
| ML como serviço separado | FastAPI + scikit-learn | Separação de concerns; permite escalar ML independentemente |
| Infra mockada | LocalStack Pro | Fidelidade à AWS sem custos; S3 e Secrets Manager funcionais |

## 6. Ordem de Inicialização dos Containers

```mermaid
flowchart TB
    LS[1. LocalStack<br/>Serviços AWS mockados] --> PG[2. PostgreSQL<br/>Banco de dados]
    PG --> VK[3. Valkey<br/>Cache + Fila Sidekiq]
    VK --> ML[4. FastAPI (ML)<br/>Serviço de classificação]
    ML --> BE[5. Rails (Backend)<br/>API + Sidekiq workers]
    BE --> FE[6. Laravel (Frontend)<br/>Interface do usuário]
    FE --> TF[7. Terraform (opcional)<br/>Provisionamento IaC]

    style LS fill:#00838F,color:#fff,stroke:#fff
    style PG fill:#0D47A1,color:#fff,stroke:#fff
    style VK fill:#E65100,color:#fff,stroke:#fff
    style ML fill:#2E7D32,color:#fff,stroke:#fff
    style BE fill:#6A1B9A,color:#fff,stroke:#fff
    style FE fill:#1565C0,color:#fff,stroke:#fff
    style TF fill:#37474F,color:#fff,stroke:#fff,stroke-dasharray: 5 5
```
