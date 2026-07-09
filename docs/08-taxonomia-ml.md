# Taxonomia de Categorias - ML TechMind

## Categorias e Exemplos

O modelo de classificação utilizará as seguintes 8 categorias para classificar conteúdos técnicos:

| # | Categoria | Descrição | Exemplos de conteúdo |
|---|---|---|---|
| 1 | **Backend** | Linguagens, frameworks, APIs, bancos de dados, servidores | Ruby, Rails, PHP, Laravel, Python, Django, Java, Spring, Node.js, PostgreSQL, Redis, REST, GraphQL |
| 2 | **Frontend** | Interfaces web, frameworks de UI, estilos, componentes | React, Vue.js, Angular, CSS, SASS, HTML, JavaScript, TypeScript, Tailwind, Bootstrap |
| 3 | **DevOps & Infraestrutura** | Cloud, containers, orquestração, CI/CD, automação | Docker, Kubernetes, Terraform, AWS, Azure, GitHub Actions, Ansible, Nginx, Linux |
| 4 | **Dados & ML** | Machine Learning, análise de dados, inteligência artificial | Python, Pandas, scikit-learn, TensorFlow, SQL, estatística, ETL, visualização de dados |
| 5 | **Mobile** | Aplicativos móveis, plataformas mobile | Android, Kotlin, iOS, Swift, React Native, Flutter, Ionic |
| 6 | **Segurança** | Proteção de sistemas, criptografia, autenticação | OWASP, JWT, OAuth, criptografia, firewall, pentest, LGPD |
| 7 | **Arquitetura & Design** | Padrões de projeto, arquitetura de software, boas práticas | Microserviços, Clean Architecture, SOLID, DDD, MVC, Design Patterns, UML |
| 8 | **Carreira & Soft Skills** | Desenvolvimento profissional, produtividade, gestão | Liderança, comunicação, agilidade, produtividade, code review, mentoria |

## Regras de Classificação

- O modelo Logistic Regression retornará uma probabilidade para cada categoria.
- A categoria escolhida será a de maior probabilidade, **desde que** a probabilidade seja >= 0.40 (threshold configurável).
- Se a maior probabilidade for inferior ao threshold, o conteúdo será classificado como **"Desconhecida"**, permitindo revisão manual futura.
- As palavras-chave retornadas em `informacoes_adicionais` serão os termos com maior peso no vetor TF-IDF para a categoria predita (top 5).

## Exemplo

```json
{
  "categoria": "Backend",
  "probabilidade": 0.87,
  "informacoes_adicionais": ["Ruby", "Rails", "API", "REST", "ActiveRecord"]
}
```

## Evolução Futura

- A taxonomia pode ser expandida com subcategorias conforme o volume de conteúdos crescer
- O threshold de 0.40 pode ser ajustado após validação com dados reais
- Novas categorias podem ser adicionadas sem retreinar todo o modelo (apenas as duas classes)
