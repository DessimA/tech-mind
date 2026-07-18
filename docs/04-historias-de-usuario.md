# Histórias de Usuário - TechMind

---

## US01 - Cadastro de Usuário

**Como** novo usuário
**Quero** me cadastrar com nome, email e senha
**Para** criar minha conta no TechMind

**Critérios de Aceitação:**
- Página de cadastro com campos nome, email e senha (mín. 6 caracteres)
- Senha armazenada com bcrypt
- Após cadastro, redirecionado para listagem (já autenticado)
- Email duplicado retorna erro "Email já cadastrado"

**Prioridade:** Alta | **Estimativa:** P

---

## US02 - Login de Usuário

**Como** usuário do sistema
**Quero** fazer login com email e senha
**Para** acessar meus conteúdos

**Critérios de Aceitação:**
- Página de login com campos email e senha
- Sessão Rails nativa (cookie criptografado)
- Credenciais inválidas mostram erro
- Rate limit de 10 tentativas/minuto

**Prioridade:** Alta | **Estimativa:** P

---

## US03 - Cadastro de Conteúdo

**Como** usuário autenticado
**Quero** cadastrar um conteúdo técnico
**Para** que ele seja classificado e armazenado

**Critérios de Aceitação:**
- Formulário com campos `titulo` e `texto`
- Título: 3-200 caracteres, obrigatório
- Texto: 10-5000 caracteres, obrigatório
- Classificação ocorre **sincronamente** durante o cadastro
- Resultado visível imediatamente na página de detalhes
- Se ML falhar (timeout), conteúdo salvo como `failed`

**Prioridade:** Alta | **Estimativa:** M

---

## US04 - Listagem de Conteúdos

**Como** usuário autenticado
**Quero** ver meus conteúdos cadastrados
**Para** consultar categoria e palavras-chave

**Critérios de Aceitação:**
- Listagem paginada (20/página)
- Filtrada por `user_id` (apenas meus conteúdos)
- Colunas: título, categoria, status, data
- Ordenação: mais recentes, mais antigos, título A-Z
- Resultados cacheados

**Prioridade:** Alta | **Estimativa:** P

---

## US05 - Busca de Conteúdo

**Como** usuário autenticado
**Quero** pesquisar meus conteúdos por título ou palavra-chave
**Para** encontrar conhecimento rapidamente

**Critérios de Aceitação:**
- Campo de busca na listagem
- Busca por título (ILIKE) e palavras-chave (GIN)
- Resultados paginados e cacheados

**Prioridade:** Média | **Estimativa:** M

---

## US06 - Detalhes do Conteúdo

**Como** usuário autenticado
**Quero** ver detalhes completos de um conteúdo
**Para** ler o texto e ver a classificação

**Critérios de Aceitação:**
- Página com título, texto completo, categoria, probabilidade e palavras-chave
- Se classificação usou Groq, mostra indicador
- Apenas o dono do conteúdo pode visualizar

**Prioridade:** Média | **Estimativa:** P

---

## US07 - Classificação Híbrida (ML + Groq)

**Como** desenvolvedor
**Quero** que o FastAPI classifique com modelo local e fallback Groq
**Para** garantir alta acurácia mesmo em casos ambíguos

**Critérios de Aceitação:**
- Modelo local TF-IDF + LogReg tenta primeiro
- Se probabilidade < threshold, chama Groq API
- Se Groq falhar, retorna "Desconhecida"
- ML Service é stateless (sem banco)

**Prioridade:** Alta | **Estimativa:** G

---

## US08 - Deploy Gratuito

**Como** desenvolvedor
**Quero** fazer deploy de 2 serviços no Render free tier
**Para** manter custo zero

**Critérios de Aceitação:**
- Rails full-stack como 1 web service Render
- FastAPI como 1 web service Render
- PostgreSQL via Supabase
- Redis via Redis Cloud (ou cache em memória)

**Prioridade:** Alta | **Estimativa:** P
