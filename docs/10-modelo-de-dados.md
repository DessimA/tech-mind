# Modelo de Dados - TechMind

## Tabela `conteudos`

Armazena os conteúdos técnicos cadastrados, sua classificação por ML e status do processamento.

### DDL

```sql
CREATE TYPE status_conteudo AS ENUM ('pending', 'processing', 'done', 'failed');

CREATE TABLE conteudos (
    id              BIGSERIAL       PRIMARY KEY,
    titulo          VARCHAR(200)    NOT NULL CHECK (char_length(titulo) >= 3),
    texto           TEXT            NOT NULL CHECK (char_length(texto) >= 10 AND char_length(texto) <= 5000),
    categoria       VARCHAR(50),
    probabilidade   DECIMAL(5,4),
    informacoes_adicionais  TEXT[],
    status          status_conteudo NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_conteudos_titulo ON conteudos USING btree (titulo);
CREATE INDEX idx_conteudos_informacoes_adicionais ON conteudos USING gin (informacoes_adicionais);
CREATE INDEX idx_conteudos_status ON conteudos USING btree (status);
CREATE INDEX idx_conteudos_created_at ON conteudos USING btree (created_at DESC);
CREATE INDEX idx_conteudos_categoria ON conteudos USING btree (categoria);
```

### Descrição das colunas

| Coluna | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `id` | `BIGSERIAL` | NOT NULL | auto | Chave primária |
| `titulo` | `VARCHAR(200)` | NOT NULL | — | Título do conteúdo (3-200 caracteres) |
| `texto` | `TEXT` | NOT NULL | — | Texto completo (10-5000 caracteres) |
| `categoria` | `VARCHAR(50)` | NULL | — | Categoria atribuída pelo ML ou `null` enquanto não classificado |
| `probabilidade` | `DECIMAL(5,4)` | NULL | — | Probabilidade da predição (0.0000 a 1.0000) ou `null` enquanto não classificado |
| `informacoes_adicionais` | `TEXT[]` | NULL | — | Array de palavras-chave extraídas pelo ML ou `null` enquanto não classificado |
| `status` | `status_conteudo` | NOT NULL | `'pending'` | Ciclo: `pending` → `processing` → `done` / `failed` |
| `created_at` | `TIMESTAMPTZ` | NOT NULL | `NOW()` | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL | `NOW()` | Data da última atualização |

### Mapeamento Rails (ActiveRecord)

```ruby
# db/migrate/20260708000001_create_conteudos.rb
class CreateConteudos < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      CREATE TYPE status_conteudo AS ENUM ('pending', 'processing', 'done', 'failed');
    SQL

    create_table :conteudos do |t|
      t.string   :titulo,             null: false, limit: 200
      t.text     :texto,              null: false
      t.string   :categoria,          limit: 50
      t.decimal  :probabilidade,      precision: 5, scale: 4
      t.text     :informacoes_adicionais, array: true
      t.enum     :status,             enum_type: :status_conteudo, default: 'pending', null: false
      t.timestamps
    end

    add_index :conteudos, :titulo
    add_index :conteudos, :informacoes_adicionais, using: :gin
    add_index :conteudos, :status
    add_index :conteudos, :created_at, order: { created_at: :desc }
    add_index :conteudos, :categoria
  end

  def down
    drop_table :conteudos
    execute <<-SQL
      DROP TYPE status_conteudo;
    SQL
  end
end
```

```ruby
# app/models/conteudo.rb
class Conteudo < ApplicationRecord
  enum :status, { pending: 'pending', processing: 'processing', done: 'done', failed: 'failed' }

  validates :titulo, presence: true, length: { minimum: 3, maximum: 200 }
  validates :texto,  presence: true, length: { minimum: 10, maximum: 5000 }
end
```

## Estratégia de Busca

### Por título

```sql
SELECT * FROM conteudos WHERE titulo ILIKE '%termo%';
```

Índice btree em `titulo` acelera a busca mesmo com `ILIKE` prefixado (o planner pode fazer scan paralelo). Para MVP com até 10K registros, o desempenho é aceitável sem índice GIN/trigram.

### Por palavra-chave (`informacoes_adicionais`)

```sql
SELECT * FROM conteudos WHERE 'termo' = ANY(informacoes_adicionais);
```

Índice **GIN** sobre o array `text[]` acelera a busca. A coluna é `TEXT[]` nativo do Postgres, permitindo uso direto do operador `ANY()` e do índice GIN.

### Na API (RF03 / US03)

O parâmetro `q` da `GET /v1/conteudos?q=termo` busca por título e palavras-chave simultaneamente:

```sql
SELECT * FROM conteudos
WHERE titulo ILIKE '%termo%'
   OR 'termo' = ANY(informacoes_adicionais)
ORDER BY created_at DESC;
```

### Cache

O resultado da busca é cacheadado no Valkey com TTL configurável (`CACHE_TTL`):

```
chave: conteudos:list:page:{page}:q:{q}:sort:{sort}
valor: JSON do response paginado
```

A cache é invalidada **apenas ao cadastrar novo conteúdo** (RF01). A janela de até 5 minutos de status desatualizado durante o processamento é aceita como trade-off para o MVP (ver decisão na matriz de decisões).

## Estados da coluna `categoria` e `informacoes_adicionais`

| `status` | `categoria` | `probabilidade` | `informacoes_adicionais` |
|---|---|---|---|
| `pending` | `null` | `null` | `null` |
| `processing` | `null` | `null` | `null` |
| `done` | Categoria predita (ex: `"Backend"`) | 0.0000 a 1.0000 | Array de palavras-chave |
| `failed` | `null` | `null` | `null` |

## Secret no Secrets Manager (LocalStack)

**Nome:** `techmind/db-credentials`

**Estrutura JSON:**

```json
{
  "host": "postgres",
  "port": "5432",
  "username": "techmind",
  "password": "techmind_dev",
  "dbname": "techmind_dev"
}
```

O Rails lê este secret no boot. Se o LocalStack estiver indisponível, faz fallback para variáveis de ambiente (ver `10-variaveis-de-ambiente.md`).

## Relacionamento com outros documentos

| Documento | Conexão |
|---|---|
| `01-requisitos-funcionais.md` (RF01-RF06) | Valida limites de campo e regras de negócio |
| `02-requisitos-nao-funcionais.md` (RNF07) | Secret do SM consumido no boot |
| `03-arquitetura.md` | Fluxo de dados entre serviços |
| `04-historias-de-usuario.md` (US01-US04) | Critérios de aceitação das US |
| `09-contratos-api.md` | Formato dos responses da API |
| `10-variaveis-de-ambiente.md` | Variáveis de ambiente e fallback |
