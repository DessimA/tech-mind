# Contribuindo para o TechMind

Obrigado por considerar contribuir com o TechMind! Este documento define as diretrizes para contribuições.

## Código de Conduta

Ao participar deste projeto, você concorda em seguir o [Código de Conduta](CODE_OF_CONDUCT.md). Denuncie comportamentos inaceitáveis para os mantenedores.

## Como Contribuir

### Reportando Bugs

1. Verifique se o bug já não foi reportado nas [issues](https://github.com/DessimA/tech-mind/issues)
2. Abra uma nova issue usando o template de bug report
3. Inclua passos para reproduzir, comportamento esperado e observado
4. Informe o ambiente (Docker version, OS)

### Sugerindo Melhorias

1. Abra uma issue com o template de feature request
2. Descreva a melhoria, o problema que resolve e exemplos de uso
3. Marque com a label `enhancement`

### Enviando Pull Requests

1. Fork o repositório
2. Crie uma branch descritiva: `git checkout -b feat/minha-feature`
3. Siga o estilo de código do projeto (sem comentários, código limpo)
4. Adicione testes para sua alteração
5. Execute os testes localmente via Docker:
   ```bash
   docker compose --profile test up --abort-on-container-exit
   ```
6. Commit com mensagem clara e concisa:
   ```
   tipo(escopo): descrição resumida

   Exemplos:
   feat(backend): adiciona endpoint GET /v1/conteudos
   fix(ml-service): corrige encoding no pré-processamento
   docs(readme): atualiza badges das stacks
   ```
7. Push para sua branch: `git push origin feat/minha-feature`
8. Abra um Pull Request contra a branch `main`

### Padrão de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `style`: Formatação, estilos (sem mudança de código)
- `refactor`: Refatoração (sem mudança de funcionalidade)
- `test`: Adição ou correção de testes
- `chore`: Manutenção, build, dependências

## Ambiente de Desenvolvimento

O projeto é 100% Docker. Nenhuma dependência local é necessária:

```bash
docker compose up -d
```

Para testes:
```bash
docker compose --profile test up --abort-on-container-exit
```

## Estrutura do Projeto

Veja o [README](README.md#estrutura-do-projeto) para a estrutura de diretórios.

## Dúvidas?

Abra uma [discussion](https://github.com/DessimA/tech-mind/discussions) ou consulte a [documentação](docs/).
