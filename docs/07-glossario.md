# Glossário - TechMind

| Termo | Definição |
|---|---|
| **bcrypt** | Algoritmo de hash de senhas, padrão no Rails (`has_secure_password`) |
| **Cold Start** | Atraso no primeiro request após inatividade no Render Free (~30-60s) |
| **Free Tier** | Camada gratuita de um serviço cloud com recursos limitados |
| **Groq API** | Plataforma de inferência LLM ultrarrápida via LPU |
| **has_secure_password** | Método do Rails para autenticação com bcrypt |
| **Hotwire** | Conjunto de ferramentas (Turbo + Stimulus) para criar aplicações HTML dinâmicas sem SPA |
| **importmap** | Sistema de gerenciamento de JavaScript sem bundlers (Node.js não necessário) |
| **LPU** | Language Processing Unit — hardware especializado da Groq |
| **MVP** | Minimum Viable Product |
| **Rails 8** | Framework full-stack Ruby: HTML, API, ORM, Cache, tudo num serviço só |
| **Stimulus** | Framework JavaScript minimalista do Hotwire para interações específicas |
| **Supabase** | Plataforma open source com PostgreSQL gratuito (500MB) |
| **TF-IDF** | Term Frequency-Inverse Document Frequency — técnica de vetorização de texto |
| **Turbo** | Conjunto de bibliotecas Hotwire (Drive + Frames + Streams) para navegação rápida |
| **Valkey** | Fork open source do Redis |
| **Vite** | Alternativa ao importmap (para projetos que precisam de bundler) |

## Relações entre Conceitos

```mermaid
flowchart TD
    Usuário[Usuário no navegador] --> RAILS[Rails 8 - Full-Stack]
    RAILS --> TURBO[Turbo Drive: navegação rápida]
    RAILS --> TURBO2[Turbo Frames: componentes]
    RAILS --> STIMULUS[Stimulus: JS interativo]
    RAILS --> DB[Supabase - PostgreSQL]
    RAILS --> CACHE[Redis Cloud - Cache]
    RAILS --> ML[FastAPI - ML Service]
    ML --> SKLEARN[scikit-learn - TF-IDF + LogReg]
    ML -.-> GROQ[Groq API - Fallback LLM]

    style Usuário fill:#4E342E,color:#fff
    style RAILS fill:#6A1B9A,color:#fff
    style TURBO fill:#FF6F00,color:#fff
    style TURBO2 fill:#FF6F00,color:#fff
    style STIMULUS fill:#FF6F00,color:#fff
    style DB fill:#0D47A1,color:#fff
    style CACHE fill:#E65100,color:#fff
    style ML fill:#2E7D32,color:#fff
    style SKLEARN fill:#37474F,color:#fff
    style GROQ fill:#F97316,color:#fff
```
