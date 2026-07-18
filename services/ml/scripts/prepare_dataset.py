"""
Script de preparação de dados reais para treino do modelo TechMind.

Baixa dados do Stack Overflow via Hugging Face datasets, mapeia as tags
para as 8 categorias do TechMind e gera um CSV limpo no formato esperado
pelo notebook de treinamento.

Uso:
    python scripts/prepare_dataset.py                         # usa Hugging Face (recommendado)
    python scripts/prepare_dataset.py --source kaggle         # usa Kaggle (requer kagglehub)
    python scripts/prepare_dataset.py --max-per-category 500  # limita exemplos por categoria

Saída:
    services/ml/data/train_real.csv  — dataset pronto para treino
    services/ml/data/train_real_stats.json  — estatísticas do dataset
"""

import argparse
import json
import os
import random
import sys
from pathlib import Path

import pandas as pd

# Adiciona o diretório raiz do script ao path para importar tag_mapping
sys.path.insert(0, str(Path(__file__).parent))
from tag_mapping import TAG_TO_CATEGORY, VALID_CATEGORIES, map_tags_to_category


DATA_DIR = Path(__file__).resolve().parent.parent / "data"
REAL_CSV_PATH = DATA_DIR / "train_real.csv"
STATS_PATH = DATA_DIR / "train_real_stats.json"

SEED = 42
random.seed(SEED)


def load_from_huggingface(max_per_category: int | None = None) -> pd.DataFrame:
    """Baixa dados do Stack Overflow do Hugging Face datasets."""
    try:
        from datasets import load_dataset
    except ImportError:
        print("Erro: biblioteca 'datasets' não instalada.")
        print("Instale com: pip install datasets")
        sys.exit(1)

    print("📦 Baixando dataset do Hugging Face (c17hawke/stackoverflow-dataset)...")
    ds = load_dataset("c17hawke/stackoverflow-dataset", split="train", trust_remote_code=True)
    print(f"   Total de registros baixados: {len(ds)}")

    rows = []
    skipped_no_tag = 0
    skipped_unmapped = 0

    for i, example in enumerate(ds):
        if i % 50000 == 0 and i > 0:
            print(f"   Processados: {i}...")

        # O dataset tem colunas: id, title, body, tags (lista de strings)
        title = example.get("title", "") or ""
        body = example.get("body", "") or ""
        tags = example.get("tags", []) or []

        if not tags:
            skipped_no_tag += 1
            continue

        categoria = map_tags_to_category(tags)
        if categoria is None:
            skipped_unmapped += 1
            continue

        # Concatena título + corpo para formar o texto de entrada
        texto = f"{title}. {body}".strip()
        if len(texto) < 20:
            continue

        rows.append({"texto": texto, "categoria": categoria})

    print(f"\n   ✅ Registros mapeados: {len(rows)}")
    print(f"   ⏭️  Sem tags: {skipped_no_tag}")
    print(f"   ⏭️  Tags não mapeadas: {skipped_unmapped}")

    df = pd.DataFrame(rows)

    if max_per_category:
        df = _balance_dataset(df, max_per_category)

    return df


def load_from_kaggle(max_per_category: int | None = None) -> pd.DataFrame:
    """Baixa dados do Kaggle (requer kagglehub)."""
    try:
        import kagglehub
    except ImportError:
        print("Erro: biblioteca 'kagglehub' não instalada.")
        print("Instale com: pip install kagglehub")
        sys.exit(1)

    print("📦 Baixando dataset do Kaggle (facebook-recruiting-iii-keyword-extraction)...")
    path = kagglehub.competition_download("facebook-recruiting-iii-keyword-extraction")
    csv_path = os.path.join(path, "Train.csv")

    if not os.path.exists(csv_path):
        print(f"   Arquivo não encontrado: {csv_path}")
        print("   Certifique-se de ter aceito os termos da competição no Kaggle.")
        sys.exit(1)

    print(f"   Carregando: {csv_path}")
    df_raw = pd.read_csv(csv_path, encoding="ISO-8859-1")

    rows = []
    for _, row in df_raw.iterrows():
        title = str(row.get("Title", ""))
        body = str(row.get("Body", ""))
        tags_str = str(row.get("Tags", ""))

        if not tags_str.strip():
            continue

        tags = [t.strip() for t in tags_str.split() if t.strip()]
        categoria = map_tags_to_category(tags)
        if categoria is None:
            continue

        texto = f"{title}. {body}".strip()
        if len(texto) < 20:
            continue

        rows.append({"texto": texto, "categoria": categoria})

    print(f"\n   ✅ Registros mapeados: {len(rows)}")
    df = pd.DataFrame(rows)

    if max_per_category:
        df = _balance_dataset(df, max_per_category)

    return df


def _balance_dataset(df: pd.DataFrame, max_per_category: int) -> pd.DataFrame:
    """Balanceia o dataset limitando o número de exemplos por categoria."""
    balanced = []
    for cat in VALID_CATEGORIES:
        subset = df[df["categoria"] == cat]
        if len(subset) > max_per_category:
            subset = subset.sample(n=max_per_category, random_state=SEED)
        balanced.append(subset)

    result = pd.concat(balanced, ignore_index=True)
    print(f"   ⚖️  Dataset balanceado: {max_per_category} máx por categoria")
    return result


def save_dataset(df: pd.DataFrame) -> None:
    """Salva o dataset e estatísticas."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # Embaralha
    df = df.sample(frac=1, random_state=SEED).reset_index(drop=True)

    df.to_csv(REAL_CSV_PATH, index=False)
    print(f"\n💾 Dataset salvo: {REAL_CSV_PATH}")
    print(f"   Total de exemplos: {len(df)}")

    # Estatísticas
    counts = df["categoria"].value_counts().to_dict()
    stats = {
        "fonte": "Stack Overflow (Hugging Face)",
        "total_exemplos": len(df),
        "categorias": len(counts),
        "exemplos_por_categoria": counts,
        "distribuicao": {
            cat: round(count / len(df) * 100, 1) for cat, count in counts.items()
        },
    }

    with open(STATS_PATH, "w", encoding="utf-8") as f:
        json.dump(stats, f, indent=2, ensure_ascii=False)

    print(f"📊 Estatísticas salvas: {STATS_PATH}")
    print(json.dumps(stats, indent=2, ensure_ascii=False))


def print_category_summary(df: pd.DataFrame) -> None:
    """Exibe resumo das categorias."""
    print("\n📋 Distribuição por categoria:")
    print(f"{'Categoria':<30} {'Exemplos':>10} {'%':>8}")
    print("-" * 50)
    for cat, count in df["categoria"].value_counts().items():
        pct = count / len(df) * 100
        print(f"{cat:<30} {count:>10} {pct:>7.1f}%")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepara dataset real do Stack Overflow para o TechMind")
    parser.add_argument(
        "--source",
        choices=["huggingface", "kaggle"],
        default="huggingface",
        help="Fonte dos dados (default: huggingface)",
    )
    parser.add_argument(
        "--max-per-category",
        type=int,
        default=None,
        help="Limite de exemplos por categoria (default: sem limite)",
    )
    parser.add_argument(
        "--print-mapping",
        action="store_true",
        help="Exibe o mapeamento tag → categoria",
    )

    args = parser.parse_args()

    if args.print_mapping:
        print("\n📌 Mapeamento Tag → Categoria TechMind")
        print("=" * 60)
        for cat in sorted(VALID_CATEGORIES):
            tags = [t for t, c in TAG_TO_CATEGORY.items() if c == cat]
            print(f"\n{cat}:")
            for tag in sorted(tags):
                print(f"  - {tag}")
        sys.exit(0)

    print(f"🔧 Preparando dataset TechMind (fonte: {args.source})")
    print(f"   Categorias: {len(VALID_CATEGORIES)}")
    print(f"   Tags mapeadas: {len(TAG_TO_CATEGORY)}")

    if args.source == "huggingface":
        df = load_from_huggingface(args.max_per_category)
    else:
        df = load_from_kaggle(args.max_per_category)

    if df.empty:
        print("\n❌ Nenhum dado foi mapeado. Verifique as tags e tente novamente.")
        sys.exit(1)

    print_category_summary(df)
    save_dataset(df)

    print("\n✅ Pronto! Agora execute o notebook techmind_ml.ipynb")
    print("   com DATA_PATH = '../data/train_real.csv' para treinar")
    print("   o modelo com dados reais do Stack Overflow.")
