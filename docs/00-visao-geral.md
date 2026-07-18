# Visão Geral do Projeto - TechMind

## 1. Propósito

O **TechMind** é um sistema de organização inteligente de conhecimento técnico. Construído com **Rails 8 full-stack** (HTML + Hotwire + API) e **FastAPI** (ML Service), ele permite que usuários se cadastrem, cadastrem conteúdos técnicos e os classifiquem automaticamente via Machine Learning híbrido (scikit-learn + Groq API fallback).

## 2. Contexto

Profissionais de tecnologia consomem e produzem grande volume de conteúdo técnico diariamente. Sem uma ferramenta de organização inteligente, esse conhecimento fica disperso em arquivos soltos, bookmarks e anotações desconectadas.

O TechMind resolve isso oferecendo:
- Cadastro centralizado de conteúdos (associado ao usuário logado)
- Classificação automática por categoria via ML (modelo local + LLM fallback)
- Extração de palavras-chave relevantes
- Autenticação por sessão (Rails nativa, sem JWT)
- Hospedagem 100% gratuita (free tiers)

## 3. Objetivos

- Fornecer uma plataforma funcional (MVP) de organização de conhecimento
- **Arquitetura enxuta:** 2 serviços apenas (Rails full-stack + FastAPI ML)
- Classificação híbrida: scikit-learn (rápido e leve) + Groq API (fallback inteligente)
- Hospedar em serviços cloud gratuitos (Render + Supabase)
- Utilizar Docker para ambiente de desenvolvimento local

## 4. Fluxo Principal do Sistema

```mermaid
flowchart LR
    A[Usuário] -->|HTML + Turbo| B["Rails 8 Full-Stack<br/>Porta 3000"]
    B -->|POST /predict| C["FastAPI<br/>ML Service"]
    C --> D[Modelo ML<br/>Logistic Regression + TF-IDF]
    C -.->|fallback<br/>baixa confiança| E[Groq API<br/>LLM Classifier]
    B --> F[PostgreSQL<br/>Supabase]
    B --> G[Valkey / Redis<br/>Cache]

    style A fill:#4E342E,color:#fff,stroke:#fff,stroke-width:2px
    style B fill:#6A1B9A,color:#fff,stroke:#fff
    style C fill:#2E7D32,color:#fff,stroke:#fff
    style D fill:#37474F,color:#fff,stroke:#fff
    style E fill:#F97316,color:#fff,stroke:#fff
    style F fill:#0D47A1,color:#fff,stroke:#fff
    style G fill:#E65100,color:#fff,stroke:#fff
```

## 5. Público-Alvo

- Desenvolvedores de software
- Estudantes de tecnologia
- Profissionais de TI que consomem conteúdo técnico regularmente

## 6. Restrições de Escopo (MVP)

- **Arquitetura de 2 serviços:** Rails 8 full-stack + FastAPI ML
- Autenticação por sessão Rails (`has_secure_password`)
- Cada conteúdo é associado a um usuário (`user_id`)
- Processamento síncrono da classificação (ML leve, sem filas)
- Cache com Valkey/Redis (fallback para memória)
- Modelo ML: Logistic Regression + TF-IDF com **fallback para Groq API**
- Hospedagem gratuita em Render + Supabase

## 7. Princípios de Arquitetura

| Princípio | Descrição |
|---|---|
| **Enxuto** | Apenas 2 serviços web (Rails + FastAPI). Nada de Laravel ou frameworks extras. |
| **Full-Stack Rails** | Um único framework cuida de HTML, API, auth, cache e ORM. |
| **Stateless** | Nenhum serviço armazena estado interno que não possa ser recriado. |
| **Fail Fast** | Chamadas entre serviços têm timeout; se exceder, falha rápido. |
| **Degradação Graciosa** | Se o ML cai, o conteúdo é salvo como `failed` — o usuário não perde dados. |

> 📖 **Detalhes completos:** [`docs/11-responsabilidades-e-resiliencia.md`](docs/11-responsabilidades-e-resiliencia.md)

## 8. Critérios de Sucesso

```mermaid
flowchart LR
    S1[Fluxo cadastro -> classificação -> consulta funcionando] --> OK((MVP OK))
    S2[Autenticação protegendo os dados] --> OK
    S3[Custo de hospedagem = R$ 0/mês] --> OK
    S4[Testes passando em todos serviços] --> OK
    S5[Documentação clara deploy gratuito] --> OK

    style S1 fill:#37474F,color:#fff,stroke:#fff
    style S2 fill:#6A1B9A,color:#fff,stroke:#fff
    style S3 fill:#37474F,color:#fff,stroke:#fff
    style S4 fill:#37474F,color:#fff,stroke:#fff
    style S5 fill:#37474F,color:#fff,stroke:#fff
    style OK fill:#1B5E20,color:#fff,stroke:#fff,stroke-width:3px
```
