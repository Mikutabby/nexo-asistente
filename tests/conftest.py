"""
conftest.py — Fixtures compartidos para tests de Nexo
"""
import os
import sys
import json
import shutil
import sqlite3
import tempfile
import types
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
sys.path.insert(0, str(PROJECT_ROOT / "memory"))

# Import GraphStore via exec (no .py extension on nexo-graph)
_nexo_graph_module = types.ModuleType("nexo_graph")
_nexo_graph_module.__file__ = str(PROJECT_ROOT / "memory" / "nexo-graph")
with open(PROJECT_ROOT / "memory" / "nexo-graph") as _f:
    exec(compile(_f.read(), str(PROJECT_ROOT / "memory" / "nexo-graph"), "exec"), _nexo_graph_module.__dict__)
GraphStore = _nexo_graph_module.GraphStore


@pytest.fixture
def tmp_dir():
    """Create a temporary directory for test isolation."""
    d = tempfile.mkdtemp(prefix="nexo-test-")
    yield d
    shutil.rmtree(d, ignore_errors=True)


@pytest.fixture
def nexo_home(tmp_dir):
    """Create a fake NEXO_HOME with required directory structure."""
    home = Path(tmp_dir)
    (home / ".nexo-memory").mkdir(parents=True)
    (home / ".nexo-memory" / "log").mkdir()
    (home / ".nexo-memory" / "log" / "audit").mkdir()
    (home / ".nexo-memory" / ".security").mkdir()
    (home / ".nexo-memory" / "learned").mkdir()
    (home / ".opencode" / "agents").mkdir(parents=True)
    return home


@pytest.fixture
def memory_json(nexo_home):
    """Create a minimal memory.json for testing."""
    data = {
        "version": 1,
        "last_updated": "2026-01-01T00:00:00",
        "nexo": {"name": "Nexo", "creator": "mikuyasha"},
        "user": {
            "name": "test_user",
            "user_hash": "",
            "is_creator": False,
            "preferences": {},
            "facts": ["fact1", "fact2", "fact3"],
        },
        "network": {"devices": {}},
        "learned_patterns": {
            "user_habits": [],
            "common_tasks": [],
            "errors_fixes": [],
            "improvements": [],
        },
        "pending_actions": [],
    }
    path = nexo_home / ".nexo-memory" / "memory.json"
    with open(path, "w") as f:
        json.dump(data, f)
    return path


@pytest.fixture
def graph_db(nexo_home):
    """Create a fresh graph.db for testing."""
    db_path = nexo_home / ".nexo-memory" / "graph.db"
    store = GraphStore(str(db_path))
    store.close()
    return db_path


@pytest.fixture
def mock_ollama():
    """Mock Ollama API for embedding tests."""
    with patch("urllib.request.urlopen") as mock:
        response = MagicMock()
        response.read.return_value = json.dumps(
            {"embeddings": [[0.1] * 384]}
        ).encode()
        response.__enter__ = lambda s: s
        response.__exit__ = MagicMock(return_value=False)
        mock.return_value = response
        yield mock


@pytest.fixture
def sample_nodes(graph_db):
    """Create sample nodes in the graph for testing."""
    store = GraphStore(str(graph_db))

    # User branch
    n1 = store.create_node("Nombre", data="Mikuyasha", branch="user")
    n2 = store.create_node("Gustos", data="Le gusta la tecnologia", branch="user")
    n3 = store.create_node("Idioma", data="Habla español", branch="user")

    # World branch
    n4 = store.create_node("Servidor", data="192.168.1.100", branch="world")
    n5 = store.create_node("WiFi", data="密码: miwifi123", branch="world")

    # Directives branch
    n6 = store.create_node("Tono", data="Habla informal y relajado", branch="directives")

    store.close()
    return {"user": [n1, n2, n3], "world": [n4, n5], "directives": [n6]}


@pytest.fixture
def identity_files(nexo_home):
    """Create identity files for testing."""
    identity_dir = nexo_home / ".nexo-memory"
    identity_file = identity_dir / "identity.json"
    protected_file = identity_dir / ".identity_protected"

    with open(identity_file, "w") as f:
        json.dump(
            {"identity": "unknown", "user": "test", "timestamp": 0}, f
        )

    with open(protected_file, "w") as f:
        json.dump(
            {
                "creator_name": "mikuyasha",
                "nexo_name": "Nexo",
                "creation_date": "2025-01-01",
                "immutable": True,
            },
            f,
        )

    return {"identity": identity_file, "protected": protected_file}


@pytest.fixture
def creator_hash_file(nexo_home):
    """Create creator passphrase hash file for testing."""
    import hashlib

    hash_file = nexo_home / ".nexo-memory" / ".creator_passphrase_hash"
    # Hash of "testpassphrase"
    test_hash = hashlib.sha256(b"testpassphrase").hexdigest()
    with open(hash_file, "w") as f:
        f.write(test_hash)
    return hash_file


@pytest.fixture
def audit_log_dir(nexo_home):
    """Ensure audit log directory exists."""
    audit_dir = nexo_home / ".nexo-memory" / "log" / "audit"
    audit_dir.mkdir(parents=True, exist_ok=True)
    return audit_dir
