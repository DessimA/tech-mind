# Modelo de Dados - TechMind

## Tabela `users`

Armazena os usuários do sistema. Autenticação via sessão Rails nativa com senhas hasheadas (bcrypt).

### DDL

```sql
CREATE TABLE users (
    id              BIGSERIAL       PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL,
    password_digest VARCHAR(255)    NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Índices
CREATE UNIQUE INDEX idx_users_email ON users USING btree (email);
```

### Descrição das colunas

| Coluna | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `id` | `BIGSERIAL` | NOT NULL | auto | Chave primária |
| `nome` | `VARCHAR(100)` | NOT NULL | — | Nome completo do usuário |
| `email` | `VARCHAR(255)` | NOT NULL | — | Email único para login |
| `password_digest` | `VARCHAR(255)` | NOT NULL | — | Hash bcrypt da senha |
| `created_at` | `TIMESTAMPTZ` | NOT NULL | `NOW()` | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL | `NOW()` | Data da última atualização |

---

## Tabela `conteudos` (atualizada)

Armazena os conteúdos técnicos cadastrados, associados a um usuário.

### DDL (adicional)

```sql
ALTER TABLE conteudos ADD COLUMN user_id BIGINT NOT NULL REFERENCES users(id);
CREATE INDEX idx_conteudos_user_id ON conteudos USING btree (user_id);
```

### Coluna adicional

| Coluna | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `user_id` | `BIGINT` | NOT NULL | — | FK → users.id — dono do conteúdo |

### DDL Completa

```sql
CREATE TYPE status_conteudo AS ENUM ('pending', 'processing', 'done', 'failed');

CREATE TABLE conteudos (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL REFERENCES users(id),
    titulo          VARCHAR(200)    NOT NULL CHECK (char_length(titulo) >= 3),
    texto           TEXT            NOT NULL CHECK (char_length(texto) >= 10 AND char_length(texto) <= 5000),
    categoria       VARCHAR(50),
    probabilidade   DECIMAL(5,4)    CHECK (probabilidade IS NULL OR (probabilidade >= 0 AND probabilidade <= 1)),
    informacoes_adicionais  TEXT[],
    status          status_conteudo NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_conteudos_user_id ON conteudos USING btree (user_id);
CREATE INDEX idx_conteudos_titulo ON conteudos USING btree (titulo);
CREATE INDEX idx_conteudos_informacoes_adicionais ON conteudos USING gin (informacoes_adicionais);
CREATE INDEX idx_conteudos_status ON conteudos USING btree (status);
CREATE INDEX idx_conteudos_created_at ON conteudos USING btree (created_at DESC);
CREATE INDEX idx_conteudos_categoria ON conteudos USING btree (categoria);
```

---

## Estratégia de Busca (com user_id)

### Por título (do usuário logado)

```sql
SELECT * FROM conteudos
WHERE user_id = ? AND titulo ILIKE '%termo%';
```

### Por palavra-chave (do usuário logado)

```sql
SELECT * FROM conteudos
WHERE user_id = ? AND informacoes_adicionais @> ARRAY['termo']::text[];
```

### Busca combinada (API)

```sql
SELECT * FROM conteudos
WHERE user_id = ?
  AND (titulo ILIKE '%termo%'
    OR informacoes_adicionais @> ARRAY['termo']::text[])
ORDER BY created_at DESC;
```

### Cache

O cache é específico por usuário e query:

```
chave: conteudos:user:{user_id}:page:{page}:q:{q}:sort:{sort}
```

O cache é invalidado ao cadastrar novo conteúdo (invalida apenas as chaves do usuário).

---

## Relacionamentos

```
User (1) ──── has_many ──── (N) Conteudo
```

- `User` `has_many :conteudos, dependent: :destroy`
- `Conteudo` `belongs_to :user`
- Ao deletar um usuário, seus conteúdos são removidos em cascata

---

## Estados da coluna `categoria` e `informacoes_adicionais`

| `status` | `categoria` | `probabilidade` | `informacoes_adicionais` | Origem |
|---|---|---|---|---|
| `pending` | `null` | `null` | `null` | — |
| `processing` | `null` | `null` | `null` | — |
| `done` (ML local) | Categoria predita | 0.0000 a 1.0000 | Array de palavras-chave | scikit-learn |
| `done` (Groq fallback) | Categoria predita | `0.0` | Array de palavras-chave ou vazio | Groq API |
| `done` (sem categoria) | `"Desconhecida"` | 0.0000 | `[]` | Nenhum |
| `failed` | `null` | `null` | `null` | — |

---

## Relacionamento com outros documentos

| Documento | Conexão |
|---|---|
| `01-requisitos-funcionais.md` (RF01-RF07) | Valida limites de campo e regras de negócio |
| `02-requisitos-nao-funcionais.md` (RNF07) | Credenciais e JWT via variáveis de ambiente |
| `03-arquitetura.md` | Fluxo de autenticação e dados |
| `04-historias-de-usuario.md` (US01-US08) | Critérios de aceitação das US |
| `08-taxonomia-ml.md` | Estratégia de classificação híbrida |
| `09-contratos-api.md` | Formato dos responses da API (incluindo auth) |
| `10-variaveis-de-ambiente.md` | Variáveis de ambiente |
