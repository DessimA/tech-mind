import os
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

os.environ["ML_THRESHOLD"] = "0.01"
os.environ.setdefault("MODEL_VERSION", "v1")


@pytest.fixture
def client():
    from app.main import app
    from app.model.loader import model

    model.load()

    from fastapi.testclient import TestClient
    with TestClient(app) as c:
        yield c


@pytest.fixture
def sample_backend_text():
    return "Framework web escrito em Ruby para desenvolvimento de APIs REST"


@pytest.fixture
def sample_frontend_text():
    return "Criando componentes reutilizaveis com React e TypeScript"


@pytest.fixture
def sample_devops_text():
    return "Guia completo sobre containers Docker e orquestracao com Kubernetes"
