"""
test_graph.py — Tests para nexo-graph (knowledge graph)
"""
import os
import sys
import json
import pytest
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "memory"))

# Import GraphStore from conftest (already loaded via exec)
from conftest import GraphStore


class TestGraphStore:
    """Tests for GraphStore initialization."""

    def test_creates_database(self, graph_db):
        """Graph creates SQLite database file."""
        assert graph_db.exists()

    def test_creates_branches(self, graph_db):
        """Graph initializes with 3 fixed branches."""
        store = GraphStore(str(graph_db))
        for branch_id in ("user", "directives", "world"):
            node = store.get_node(branch_id)
            assert node is not None
            assert node["id"] == branch_id
        store.close()

    def test_creates_root(self, graph_db):
        """Graph creates root node."""
        store = GraphStore(str(graph_db))
        root = store.get_node("root")
        assert root is not None
        assert root["id"] == "root"
        store.close()


class TestGraphNodeCRUD:
    """Tests for node CRUD operations."""

    def test_create_node(self, graph_db):
        """Create a node and retrieve it."""
        store = GraphStore(str(graph_db))
        nid = store.create_node("Test Node", data="test data", branch="user")
        node = store.get_node(nid)
        assert node is not None
        assert node["name"] == "Test Node"
        assert node["data"] == "test data"
        assert node["branch"] == "user"
        store.close()

    def test_create_node_with_parent(self, graph_db):
        """Create a node with a parent."""
        store = GraphStore(str(graph_db))
        nid = store.create_node("Child", data="child data", parent_id="user", branch="user")
        node = store.get_node(nid)
        assert node["parent_id"] == "user"
        store.close()

    def test_get_children(self, graph_db, sample_nodes):
        """Get children of a branch."""
        store = GraphStore(str(graph_db))
        children = store.get_children("user")
        assert len(children) >= 3
        names = [c["name"] for c in children]
        assert "Nombre" in names
        store.close()

    def test_update_node(self, graph_db):
        """Update node data."""
        store = GraphStore(str(graph_db))
        nid = store.create_node("ToUpdate", data="old", branch="world")
        store.update_node(nid, data="new")
        node = store.get_node(nid)
        assert node["data"] == "new"
        store.close()

    def test_delete_node(self, graph_db):
        """Delete a node (not a branch)."""
        store = GraphStore(str(graph_db))
        nid = store.create_node("ToDelete", data="bye", branch="world")
        assert store.delete_node(nid) is True
        assert store.get_node(nid) is None
        store.close()

    def test_cannot_delete_branch(self, graph_db):
        """Cannot delete fixed branches."""
        store = GraphStore(str(graph_db))
        assert store.delete_node("user") is False
        assert store.delete_node("directives") is False
        assert store.delete_node("world") is False
        store.close()

    def test_touch_node(self, graph_db):
        """Touch increments access count."""
        store = GraphStore(str(graph_db))
        nid = store.create_node("Touched", data="", branch="world")
        before = store.get_node(nid)["access_count"]
        store.touch_node(nid)
        after = store.get_node(nid)["access_count"]
        assert after > before
        store.close()


class TestGraphSearch:
    """Tests for search functionality."""

    def test_search_finds_match(self, graph_db, sample_nodes):
        """Search finds nodes matching keyword."""
        store = GraphStore(str(graph_db))
        results = store.search("Mikuyasha")
        assert len(results) > 0
        names = [r["name"] for r in results]
        assert "Nombre" in names
        store.close()

    def test_search_case_insensitive(self, graph_db, sample_nodes):
        """Search is case-insensitive."""
        store = GraphStore(str(graph_db))
        results = store.search("mikuyasha")
        assert len(results) > 0
        store.close()

    def test_search_no_results(self, graph_db, sample_nodes):
        """Search with no matches returns empty."""
        store = GraphStore(str(graph_db))
        results = store.search("zzzznonexistent")
        assert len(results) == 0
        store.close()

    def test_search_relevance_scoring(self, graph_db, sample_nodes):
        """Name matches score higher than data matches."""
        store = GraphStore(str(graph_db))
        # "Nombre" is a name, "Mikuyasha" is in data
        results = store.search("Nombre")
        assert len(results) > 0
        # First result should have high relevance
        assert results[0]["_relevance"] > 0
        store.close()

    def test_search_multi_keyword(self, graph_db, sample_nodes):
        """Multi-keyword search works."""
        store = GraphStore(str(graph_db))
        results = store.search("Mikuyasha tecnologia")
        # Should find nodes matching either keyword
        assert len(results) > 0
        store.close()

    def test_fts_search(self, graph_db, sample_nodes):
        """FTS5 search works."""
        store = GraphStore(str(graph_db))
        results = store.fts_search("Mikuyasha")
        assert len(results) > 0
        store.close()

    def test_recall_search(self, graph_db, sample_nodes):
        """Recall Gate (Jaccard) search works."""
        store = GraphStore(str(graph_db))
        results = store.recall_search("Mikuyasha")
        assert len(results) > 0
        assert "_jaccard" in results[0]
        store.close()


class TestGraphWarmProfile:
    """Tests for warm profile generation."""

    def test_warm_profile_user(self, graph_db, sample_nodes):
        """Warm profile includes user data."""
        store = GraphStore(str(graph_db))
        profile = store.warm_profile()
        assert "Mikuyasha" in profile["user"] or "tecnologia" in profile["user"]
        store.close()

    def test_warm_profile_directives(self, graph_db, sample_nodes):
        """Warm profile includes directives."""
        store = GraphStore(str(graph_db))
        profile = store.warm_profile()
        assert "informal" in profile["directives"] or "relajado" in profile["directives"]
        store.close()


class TestGraphStats:
    """Tests for statistics."""

    def test_stats_counts(self, graph_db, sample_nodes):
        """Stats returns correct counts."""
        store = GraphStore(str(graph_db))
        stats = store.get_stats()
        assert stats["total_nodes"] > 3  # root + 3 branches + sample nodes
        assert stats["user_facts"] >= 3
        assert stats["world_facts"] >= 2
        store.close()


class TestGraphTree:
    """Tests for tree display."""

    def test_tree_output(self, graph_db, sample_nodes):
        """Tree returns a non-empty string."""
        store = GraphStore(str(graph_db))
        tree = store.get_tree()
        assert len(tree) > 0
        assert "Root" in tree
        store.close()
