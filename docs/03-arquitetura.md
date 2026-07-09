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

    LARAVEL -->|HTTP server-side<br/>POST /v1/conteudos| RAILS
    LARAVEL -->|HTTP server-side<br/>GET /v1/conteudos| RAILS
    RAILS -->|env vars diretas| PG
    RAILS -->|env vars diretas| VALKEY
    RAILS -->|Enfileira jobs| VALKEY
    SIDEKIQ -->|Consome fila| VALKEY
    SIDEKIQ -->|POST /predict| FASTAPI
    SIDEKIQ -->|Atualiza status| PG
    SIDEKIQ -.->|Só após TF<br/>service_completed_successfully| S3
    TF -->|Provisiona| S3
    TF -->|Provisiona| SM

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

### Observações importantes

- **Rails e Laravel usam variáveis de ambiente** do `docker-compose.yml` para conectar em PostgreSQL e Valkey. Nenhum serviço crítico depende do Secrets Manager ou do LocalStack para subir.
- **Laravel chama Rails via HTTP server-side** (PHP faz a requisição HTTP para o backend). Sem CORS, sem chamadas diretas do navegador para a API.
- **Apenas o Sidekiq worker depende do Terraform** (via `depends_on: terraform: condition: service_completed_successfully`), pois é ele quem salva artefatos no S3.
- **Rails não salva no S3 nem lê do Secrets Manager durante o boot.** Toda interação com AWS é feita exclusivamente pelo Sidekiq.

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
    ML-->>SQ: { categoria, probabilidade, informacoes_adicionais }
    SQ->>DB: UPDATE status: done, categoria, informacoes_adicionais
    SQ->>LS: Salva texto original no S3 (após TF concluído)
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
| Boot sem depender de Secrets Manager | env vars diretas para DB/Valkey | Remove dependência de ordem; serviços críticos sobem sem Terraform |
| Sidekiq espera Terraform | `service_completed_successfully` | Uma linha de config no docker-compose, sem lógica extra |
| Laravel → Rails | HTTP server-side (sem CORS) | Mais simples que chamadas diretas do navegador; sem configurar CORS |
| Quem salva no S3 | Apenas Sidekiq | Rails não precisa de credenciais AWS no boot; responsabilidade única |
| Nome do campo de saída | `informacoes_adicionais` | Nome descritivo para as palavras-chave extraídas pelo ML |

## 6. Ordem de Inicialização dos Containers

```mermaid
flowchart TB
    subgraph Critico [Caminho crítico de boot - sobe rápido]
        PG[1. PostgreSQL<br/>Banco de dados] --> RAILS[3. Rails API<br/>env vars diretas]
        VK[2. Valkey<br/>Cache + Fila] --> RAILS
        RAILS --> FE[4. Laravel<br/>HTTP server-side para Rails]
    end

    subgraph Provisionamento [Provisionamento de infra - pode levar tempo]
        LS[a. LocalStack<br/>Serviços AWS mockados] --> TF[b. Terraform apply<br/>cria bucket S3 + secrets]
    end

    TF -.->|service_completed_successfully| SQ[5. Sidekiq worker<br/>só ele precisa do S3]
    PG --> SQ
    VK --> SQ
    ML --> SQ

    style Critico fill:#1B5E20,color:#fff,stroke:#fff
    style PG fill:#0D47A1,color:#fff,stroke:#fff
    style VK fill:#E65100,color:#fff,stroke:#fff
    style RAILS fill:#6A1B9A,color:#fff,stroke:#fff
    style FE fill:#1565C0,color:#fff,stroke:#fff
    style Provisionamento fill:#4A148C,color:#fff,stroke:#fff
    style LS fill:#00838F,color:#fff,stroke:#fff
    style TF fill:#37474F,color:#fff,stroke:#fff
    style SQ fill:#8E24AA,color:#fff,stroke:#fff
    style ML fill:#2E7D32,color:#fff,stroke:#fff
```
