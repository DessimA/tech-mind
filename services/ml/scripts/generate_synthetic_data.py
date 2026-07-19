import argparse
import csv
import os
import time

import httpx

CATEGORIAS = [
    "Arquitetura & Design",
    "Backend",
    "Carreira & Soft Skills",
    "Dados & ML",
    "DevOps & Infraestrutura",
    "Frontend",
    "Mobile",
    "Segurança",
]

SYSTEM_PROMPT = """Você é um gerador de dados sintéticos para treinar um classificador de texto.
Gere perguntas técnicas (em português) sobre desenvolvimento de software no formato de título + descrição curta.
Cada pergunta deve ser REALISTA, como algo que um desenvolvedor perguntaria no Stack Overflow em português.
Responda APENAS com o texto da pergunta, uma por linha, sem numeração e sem explicações."""


def generate(
    groq_api_key: str, categoria: str, n: int, model: str = "llama-3.1-8b-instant"
) -> list[str]:
    prompt = f"""Gere {n} perguntas técnicas em português sobre "{categoria}".
Cada pergunta deve ter um título curto seguido de uma descrição de 1-2 frases.
As perguntas devem ser DIVERSAS e cobrir subtópicos diferentes dentro de {categoria}.
Responda APENAS com as perguntas, uma por linha."""

    with httpx.Client(timeout=30) as client:
        resp = client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {groq_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": prompt},
                ],
                "max_tokens": 4096,
                "temperature": 0.8,
            },
        )
        resp.raise_for_status()
        data = resp.json()
        content = data["choices"][0]["message"]["content"]
        lines = [line.strip() for line in content.split("\n") if line.strip()]
        return lines


def save_csv(rows: list[dict], output_path: str) -> None:
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["texto", "categoria"])
        writer.writeheader()
        writer.writerows(rows)
    print(f"Salvo: {output_path} ({len(rows)} exemplos)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Gera dados sintéticos de treino usando Groq")
    parser.add_argument(
        "--output", default="data/train_synthetic.csv", help="Caminho do CSV de saída"
    )
    parser.add_argument("--per-category", type=int, default=50, help="Exemplos por categoria")
    parser.add_argument("--batch", type=int, default=25, help="Exemplos por chamada de API")
    args = parser.parse_args()

    api_key = os.environ.get("GROQ_API_KEY", "")
    if not api_key:
        print("ERRO: defina GROQ_API_KEY no ambiente")
        exit(1)

    all_rows = []
    for categoria in CATEGORIAS:
        print(f"\nGerando {args.per_category} exemplos para: {categoria}")
        generated = 0
        while generated < args.per_category:
            batch_size = min(args.batch, args.per_category - generated)
            try:
                lines = generate(api_key, categoria, batch_size)
                for line in lines:
                    all_rows.append({"texto": line, "categoria": categoria})
                    generated += 1
                print(f"  → {generated}/{args.per_category}")
                time.sleep(0.5)
            except Exception as e:
                print(f"  ⚠️  Erro: {e}, tentando novamente em 5s...")
                time.sleep(5)

    save_csv(all_rows, args.output)
    print("Pronto! Agora mescle com train.csv e retreine o modelo.")
