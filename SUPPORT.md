# Suporte ao TechMind

## Documentação

Consulte a documentação completa em [`docs/`](docs/):

| Documento | Descrição |
|---|---|
| [Visão Geral](docs/00-visao-geral.md) | Objetivos e contexto do projeto |
| [Requisitos Funcionais](docs/01-requisitos-funcionais.md) | Funcionalidades do MVP |
| [Requisitos Não Funcionais](docs/02-requisitos-nao-funcionais.md) | Performance, segurança, etc |
| [Arquitetura](docs/03-arquitetura.md) | Diagramas e fluxos |
| [Stacks e Justificativas](docs/05-stacks-e-justificativas.md) | Tecnologias escolhidas |

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
