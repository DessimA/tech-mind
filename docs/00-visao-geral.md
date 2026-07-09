# Visão Geral do Projeto - TechMind

## 1. Propósito

O **TechMind** é um MVP de sistema de organização inteligente de conhecimento técnico. Ele permite que usuários cadastrem, classifiquem e consultem conteúdos técnicos (artigos, documentações, anotações de estudo, tutoriais) de forma automatizada, utilizando Machine Learning para categorização e extração de palavras-chave.

## 2. Contexto

Profissionais de tecnologia consomem e produzem grande volume de conteúdo técnico diariamente. Sem uma ferramenta de organização inteligente, esse conhecimento fica disperso em arquivos soltos, bookmarks e anotações desconectadas. O TechMind resolve esse problema oferecendo:

- Cadastro centralizado de conteúdos
- Classificação automática por categoria via ML
- Extração de palavras-chave relevantes
- Consulta e reutilização facilitadas

## 3. Objetivos

- Fornecer uma plataforma funcional (MVP) de organização de conhecimento
- Demonstrar integração entre microsserviços (PHP, Ruby, Python)
- Provisionar infraestrutura cloud simulada via IaC (Terraform + LocalStack)
- Utilizar Docker para ambiente 100% conteinerizado, sem dependências locais

## 4. Fluxo Principal do Sistema

```mermaid
flowchart LR
    A[Usuário] --> B[Laravel<br/>Frontend]
    B --> C[Rails API<br/>Backend]
    C --> D[FastAPI<br/>ML Service]
    C --> E[PostgreSQL]
    C --> F[Valkey<br/>Cache + Fila]
    D --> G[Modelo ML<br/>Logistic Regression + TF-IDF]

    B --> H[Listagem<br/>Consultas]
    H --> F
    H --> E

    style A fill:#4E342E,color:#fff,stroke:#fff,stroke-width:2px
    style B fill:#1565C0,color:#fff,stroke:#fff
    style C fill:#6A1B9A,color:#fff,stroke:#fff
    style D fill:#2E7D32,color:#fff,stroke:#fff
    style E fill:#0D47A1,color:#fff,stroke:#fff
    style F fill:#E65100,color:#fff,stroke:#fff
    style G fill:#37474F,color:#fff,stroke:#fff
    style H fill:#00838F,color:#fff,stroke:#fff
```

## 5. Público-Alvo

- Desenvolvedores de software
- Estudantes de tecnologia
- Profissionais de TI que consomem conteúdo técnico regularmente

## 6. Restrições de Escopo (MVP)

- Sem autenticação de usuário (adiada para pós-MVP)
- Processamento assíncrono via Sidekiq
- Cache com Valkey para otimização de consultas
- Modelo ML: Logistic Regression + TF-IDF
- Ambiente 100% Docker

## 7. Critérios de Sucesso

```mermaid
flowchart LR
    S1[Fluxo cadastro -> classificação -> consulta funcionando] --> OK((MVP OK))
    S2[Infra via Terraform em segundos] --> OK
    S3[Testes passando em todos serviços] --> OK
    S4[Documentação clara docker compose up] --> OK

    style S1 fill:#37474F,color:#fff,stroke:#fff
    style S2 fill:#37474F,color:#fff,stroke:#fff
    style S3 fill:#37474F,color:#fff,stroke:#fff
    style S4 fill:#37474F,color:#fff,stroke:#fff
    style OK fill:#1B5E20,color:#fff,stroke:#fff,stroke-width:3px
```
