import json
import os
from pathlib import Path

import joblib
from sklearn.pipeline import Pipeline

BASE_DIR = Path(__file__).resolve().parent.parent.parent
MODEL_PATH = BASE_DIR / "model.joblib"
METADATA_PATH = BASE_DIR / "model_metadata.json"


class ModelWrapper:
    def __init__(self):
        self.pipeline: Pipeline | None = None
        self.metadata: dict | None = None
        self.version_ok: bool = False

    def load(self) -> None:
        expected_version = os.environ.get("MODEL_VERSION", "v1")

        if not MODEL_PATH.exists():
            self.version_ok = False
            return

        self.pipeline = joblib.load(MODEL_PATH)

        if METADATA_PATH.exists():
            with open(METADATA_PATH) as f:
                self.metadata = json.load(f)
            actual_version = self.metadata.get("version", "unknown")
            self.version_ok = actual_version == expected_version
        else:
            self.version_ok = False

    @property
    def modelo(self) -> str:
        return f"logistic_regression_{os.environ.get('MODEL_VERSION', 'v1')}"

    @property
    def categorias(self) -> list[str]:
        if self.pipeline is not None:
            return list(self.pipeline.classes_)
        if self.metadata:
            return self.metadata.get("categories", [])
        return []


model = ModelWrapper()
