import csv
import re
import sys
import time
from datetime import datetime
from pathlib import Path

import requests
from bs4 import BeautifulSoup

sys.path.insert(0, str(Path(__file__).parent))
from tag_mapping import TAG_TO_CATEGORY

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
REAL_CSV_PATH = DATA_DIR / "train_real.csv"
STATS_PATH = DATA_DIR / "train_real_stats.json"

CATEGORY_TAGS = {
    "Backend": [
        "ruby-on-rails",
        "python",
        "java",
        "node.js",
        "django",
        "spring-boot",
        "go",
        "rust",
        "postgresql",
        "mongodb",
        "graphql",
        "rabbitmq",
        "redis",
    ],
    "Frontend": [
        "reactjs",
        "angular",
        "vue.js",
        "svelte",
        "next.js",
        "css",
        "typescript",
        "tailwind-css",
        "redux",
        "webpack",
        "jest",
        "storybook",
    ],
    "DevOps & Infraestrutura": [
        "docker",
        "kubernetes",
        "terraform",
        "jenkins",
        "ansible",
        "aws",
        "nginx",
        "linux",
        "prometheus",
        "github-actions",
        "helm",
        "elasticsearch",
    ],
    "Dados & ML": [
        "machine-learning",
        "deep-learning",
        "tensorflow",
        "pytorch",
        "scikit-learn",
        "pandas",
        "nlp",
        "data-science",
        "apache-spark",
        "xgboost",
        "langchain",
        "llm",
    ],
    "Mobile": [
        "android",
        "ios",
        "swift",
        "kotlin",
        "react-native",
        "flutter",
        "swiftui",
        "jetpack-compose",
        "firebase",
    ],
    "Segurança": [
        "security",
        "authentication",
        "oauth",
        "encryption",
        "jwt",
        "csrf",
        "xss",
        "sql-injection",
        "owasp",
    ],
    "Arquitetura & Design": [
        "microservices",
        "design-patterns",
        "domain-driven-design",
        "system-design",
        "software-architecture",
        "clean-architecture",
        "solid",
        "cqrs",
        "event-sourcing",
        "serverless",
    ],
    "Carreira & Soft Skills": [
        "agile",
        "scrum",
        "code-review",
        "technical-debt",
        "productivity",
        "open-source",
        "remote-work",
    ],
}

PAGE_SIZE = 100
MAX_PER_TAG = 100
DELAY = 0.6


API_KEY_PATTERN = re.compile(r"sk-[a-zA-Z0-9]{20,}")


def sanitize(text: str) -> str:
    return API_KEY_PATTERN.sub("sk-REDACTED", text)


def strip_html(html: str) -> str:
    if not html:
        return ""
    soup = BeautifulSoup(html, "lxml")
    for code in soup.find_all("code"):
        code.replace_with(f" {code.get_text()} ")
    text = soup.get_text(separator=" ")
    text = re.sub(r"\s+", " ", text).strip()
    return text


def fetch_questions(tag: str, pagesize: int = 100, max_total: int = 100) -> list[dict]:
    questions = []
    page = 1

    while len(questions) < max_total:
        params = {
            "pagesize": min(pagesize, max_total - len(questions)),
            "page": page,
            "order": "desc",
            "sort": "votes",
            "tagged": tag,
            "site": "stackoverflow",
            "filter": "withbody",
        }

        try:
            r = requests.get(
                "https://api.stackexchange.com/2.3/questions",
                params=params,
                timeout=15,
            )
            r.raise_for_status()
            data = r.json()

            quota = data.get("quota_remaining", 0)
            if quota < 10:
                print(f"   ⚠️  Quota baixa: {quota}")
        except Exception as e:
            print(f"   ⚠️  Erro na API: {e}")
            break

        items = data.get("items", [])
        if not items:
            break

        for q in items:
            title = q.get("title", "").strip()
            body = strip_html(q.get("body", ""))
            tags = q.get("tags", [])

            if len(title) < 10 and len(body) < 50:
                continue

            texto = f"{title}. {body}"[:5000]
            texto = sanitize(texto)
            if len(texto) < 30:
                continue

            questions.append({"texto": texto, "tags": tags, "score": q.get("score", 0)})

        if not data.get("has_more"):
            break

        page += 1
        time.sleep(DELAY)

    return questions[:max_total]


def main():
    print("=== Fetch Real Data: Stack Overflow → TechMind ===\n")

    output_tags = set()
    for tags in CATEGORY_TAGS.values():
        output_tags.update(tags)
    print(f"Tags selecionadas: {len(output_tags)}")
    print(f"Categorias: {len(CATEGORY_TAGS)}")

    all_rows = []
    stats = {}

    for categoria, tags in CATEGORY_TAGS.items():
        print(f"\n--- {categoria} ({len(tags)} tags) ---")
        cat_rows = []

        for tag in tags:
            qs = fetch_questions(tag, PAGE_SIZE, MAX_PER_TAG)

            for q in qs:
                mapped = TAG_TO_CATEGORY.get(tag)
                if mapped == categoria:
                    cat_rows.append(
                        {
                            "texto": q["texto"],
                            "categoria": categoria,
                            "tag_fonte": tag,
                        }
                    )

            print(f"  {tag:25s} → {len(qs)} questoes", flush=True)

        all_rows.extend(cat_rows)
        stats[categoria] = len(cat_rows)
        print(f"  TOTAL {categoria}: {len(cat_rows)}")

    print("\n=== Resumo ===")
    total = sum(stats.values())
    for cat, count in stats.items():
        pct = count / total * 100 if total else 0
        print(f"  {cat:30s} {count:5d} ({pct:5.1f}%)")
    print(f"  {'TOTAL':30s} {total:5d}")

    if not all_rows:
        print("\n❌ Nenhum dado baixado. Verifique a conexão e tente novamente.")
        sys.exit(1)

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(REAL_CSV_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["texto", "categoria"])
        writer.writeheader()
        for row in all_rows:
            writer.writerow({"texto": row["texto"], "categoria": row["categoria"]})

    print(f"\n💾 Salvo: {REAL_CSV_PATH}")
    print(f"📊 Total de exemplos: {total}")

    import json

    stats_data = {
        "fonte": "Stack Exchange API",
        "baixado_em": datetime.now().isoformat(),
        "total_exemplos": total,
        "exemplos_por_categoria": stats,
    }
    with open(STATS_PATH, "w", encoding="utf-8") as f:
        json.dump(stats_data, f, indent=2, ensure_ascii=False)
    print(f"📊 Estatisticas: {STATS_PATH}")


if __name__ == "__main__":
    main()
