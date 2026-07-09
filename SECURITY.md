# Política de Segurança do TechMind

## Reportando Vulnerabilidades

Valorizamos a segurança do TechMind. Se você descobrir uma vulnerabilidade de segurança, por favor reporte de forma responsável.

**Não abra uma issue pública para vulnerabilidades de segurança.**

### Processo de Reporte

1. Abra uma issue de segurança no repositório ou entre em contato via [GitHub Security Advisories](https://github.com/DessimA/tech-mind/security/advisories)
2. Inclua uma descrição detalhada do problema
3. Inclua passos para reproduzir a vulnerabilidade
4. Inclua possível impacto e sugestão de correção (se aplicável)

### O que esperar

- Confirmação de recebimento em até 48 horas úteis
- Avaliação inicial em até 5 dias úteis
- Atualizações a cada 7 dias até a resolução
- Atribuição de crédito quando a vulnerabilidade for corrigida (se desejar)

## Política de Divulgação

Trabalhamos com divulgação coordenada. Após o patch ser disponibilizado, concedemos um período de 30 dias para que os usuários atualizem antes da divulgação pública.

## Escopo

Os seguintes itens estão dentro do escopo desta política:

- Código fonte nos repositórios oficiais
- Dependências gerenciadas via Bundler, Composer e Pip
- Configurações de Docker e Docker Compose
- Infraestrutura declarada via Terraform

## Fora do Escopo

- Serviços de terceiros (AWS, LocalStack)
- Dependências indiretas (transitivas)

## Práticas de Segurança do Projeto

- Secrets gerenciados via AWS Secrets Manager (LocalStack)
- Sem credenciais hardcoded
- Rede interna do Docker para comunicação entre serviços
- Rate limiting nos endpoints da API (100 req/min/IP)
- Health checks para detectar falhas precocemente
- Logs estruturados sem dados sensíveis

## Versões Suportadas

| Versão | Suporte |
|---|---|
| 1.x (MVP) | Correções de segurança |
| < 1.0 | Sem suporte |
