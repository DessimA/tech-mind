# Suporte ao TechMind

## Documentação

Consulte a documentação completa em [`docs/`](docs/):

| Documento | Descrição |
|---|---|---|
| [00-visao-geral.md](docs/00-visao-geral.md) | Visão geral, objetivos e critérios de sucesso |
| [01-requisitos-funcionais.md](docs/01-requisitos-funcionais.md) | 6 requisitos funcionais com diagramas |
| [02-requisitos-nao-funcionais.md](docs/02-requisitos-nao-funcionais.md) | 9 requisitos não funcionais |
| [03-arquitetura.md](docs/03-arquitetura.md) | Arquitetura C4 com diagramas Mermaid |
| [04-historias-de-usuario.md](docs/04-historias-de-usuario.md) | 6 histórias de usuário (INVEST) |
| [05-stacks-e-justificativas.md](docs/05-stacks-e-justificativas.md) | Stacks e justificativas das escolhas |
| [06-matriz-de-decisoes.md](docs/06-matriz-de-decisoes.md) | Matriz de decisões do projeto |
| [07-glossario.md](docs/07-glossario.md) | Glossário de termos técnicos |
| [08-taxonomia-ml.md](docs/08-taxonomia-ml.md) | Taxonomia de categorias do ML |
| [09-contratos-api.md](docs/09-contratos-api.md) | Contratos formais das APIs (request/response) |
| [10-modelo-de-dados.md](docs/10-modelo-de-dados.md) | Schema do banco, índices e estratégia de busca |
| [10-variaveis-de-ambiente.md](docs/10-variaveis-de-ambiente.md) | Variáveis de ambiente do projeto |

## Dúvidas Frequentes

### Ambiente Docker

**P: Preciso instalar Ruby/PHP/Python na minha máquina?**

R: Não. O projeto é 100% Docker. Execute `docker compose up -d` e tudo rodará nos containers.

**P: Como acesso o terminal de um serviço específico?**

R: `docker compose exec backend bash` (substitua `backend` pelo nome do serviço).

### API

**P: Como testar a API sem o frontend?**

R: Use a documentação interativa do FastAPI em `http://localhost:8000/docs` ou ferramentas como `curl`/Postman.

### LocalStack

**P: Preciso de uma conta AWS real?**

R: Não. O LocalStack Pro simula os serviços AWS localmente. É necessária apenas uma license key do LocalStack.

## Canais de Suporte

| Canal | Descrição |
|---|---|
| [Issues](https://github.com/DessimA/tech-mind/issues) | Reportar bugs e solicitar features |
| [Discussions](https://github.com/DessimA/tech-mind/discussions) | Dúvidas e discussões gerais |
| [Documentação](docs/) | Documentação completa do projeto |

## Reportando Problemas

Antes de abrir uma issue:

1. Verifique se o problema já foi reportado
2. Inclua logs do container relevante: `docker compose logs <servico>`
3. Informe sua versão do Docker e sistema operacional
4. Descreva passos para reproduzir o problema
