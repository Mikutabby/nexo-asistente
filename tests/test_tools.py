"""
test_tools.py — Tests para nexo-tools, nexo-skill, nexo-auto-model
"""
import os
import sys
import json
import subprocess
import pytest
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
TOOLS_DIR = PROJECT_ROOT / "tools"


def run_tool(script_name, args=None, env=None):
    """Run a tool script with args."""
    script = TOOLS_DIR / script_name
    result = subprocess.run(
        ["bash", str(script)] + (args or []),
        capture_output=True,
        text=True,
        env=env or os.environ.copy(),
        timeout=10,
    )
    return result


class TestNexoAutoModel:
    """Tests for nexo-auto-model (intent detection)."""

    def test_coding_intent(self):
        """Coding keywords detected."""
        r = run_tool("nexo-auto-model", ["arreglá el bug en el código"])
        data = json.loads(r.stdout)
        assert data["intent"] == "coding"

    def test_power_intent(self):
        """Power/reasoning keywords detected."""
        r = run_tool("nexo-auto-model", ["analizá este problema complejo"])
        data = json.loads(r.stdout)
        assert data["intent"] == "power"

    def test_fast_intent(self):
        """Urgency keywords detected."""
        r = run_tool("nexo-auto-model", ["hacelo rápido ya"])
        data = json.loads(r.stdout)
        assert data["intent"] == "fast"

    def test_casual_intent(self):
        """Casual greeting detected."""
        r = run_tool("nexo-auto-model", ["hola qué tal"])
        data = json.loads(r.stdout)
        assert data["intent"] == "casual"

    def test_system_intent(self):
        """System admin keywords detected."""
        r = run_tool("nexo-auto-model", ["instalá el servidor"])
        data = json.loads(r.stdout)
        assert data["intent"] == "system"

    def test_output_is_valid_json(self):
        """Output is always valid JSON."""
        r = run_tool("nexo-auto-model", ["test message"])
        data = json.loads(r.stdout)
        assert "intent" in data
        assert "suggested_model" in data
        assert "needs_switch" in data

    def test_model_mapping(self):
        """Each intent maps to a valid model (checks intent field, not exact model)."""
        valid_intents = ["coding", "power", "fast", "casual", "system", "multimodal", "creative", "math", "default"]
        for intent in ["coding", "power", "fast", "casual", "system"]:
            r = run_tool("nexo-auto-model", [f"test {intent}"])
            data = json.loads(r.stdout)
            assert data["intent"] in valid_intents
            assert "suggested_model" in data
            assert len(data["suggested_model"]) > 0


class TestNexoSkill:
    """Tests for nexo-skill (skill system)."""

    def test_list_empty(self, nexo_home):
        """List skills when none installed."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_tool("nexo-skill", ["list"], env)
        assert "Skills" in r.stdout or "skill" in r.stdout.lower()

    def test_create_skill(self, nexo_home):
        """Create a new skill."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_tool("nexo-skill", ["create", "test-skill"], env)
        assert r.returncode == 0
        skill_dir = nexo_home / ".nexo-skills" / "test-skill"
        assert skill_dir.exists()
        assert (skill_dir / "skill.json").exists()

    def test_skill_manifest_format(self, nexo_home):
        """Created skill has valid manifest."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_tool("nexo-skill", ["create", "test-skill2"], env)
        manifest = nexo_home / ".nexo-skills" / "test-skill2" / "skill.json"
        with open(manifest) as f:
            data = json.load(f)
        assert "name" in data
        assert "version" in data
        assert "commands" in data

    def test_help(self):
        """Help shows usage."""
        r = run_tool("nexo-skill", ["--help"])
        assert r.returncode == 0 or "NEXO SKILL" in r.stdout


class TestNexoTools:
    """Tests for nexo-tools (tool registry)."""

    def test_list_empty(self, nexo_home):
        """List tools when none registered."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        # nexo-tools needs nexo-graph to be installed
        if (Path(env["HOME"]) / ".local" / "bin" / "nexo-graph").exists():
            r = run_tool("nexo-tools", ["list"], env)
            assert "herramientas" in r.stdout.lower() or "tools" in r.stdout.lower() or "No" in r.stdout

    def test_help(self):
        """Help shows usage."""
        r = run_tool("nexo-tools", ["help"])
        assert "Nexo Tool Registry" in r.stdout or "Uso:" in r.stdout or "list" in r.stdout
