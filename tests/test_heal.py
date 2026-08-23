"""
test_heal.py — Tests para nexo-heal (self-healing system)
"""
import os
import sys
import subprocess
import pytest
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
TOOLS_DIR = PROJECT_ROOT / "tools"


def run_heal(args, env=None):
    """Run nexo-heal with args."""
    script = TOOLS_DIR / "nexo-heal"
    result = subprocess.run(
        ["bash", str(script)] + args,
        capture_output=True,
        text=True,
        env=env or os.environ.copy(),
        timeout=10,
    )
    return result


class TestNexoHeal:
    """Tests for nexo-heal commands."""

    def test_help(self):
        """--help shows usage."""
        r = run_heal(["--help"])
        assert r.returncode == 0

    def test_version(self):
        """--version shows version."""
        r = run_heal(["--version"])
        assert "Nexo Heal" in r.stdout

    def test_status_empty(self, nexo_home):
        """Status works with no errors registered."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_heal(["status"], env)
        assert "Nexo Self-Healing System" in r.stdout

    def test_scan_no_logs(self, nexo_home):
        """Scan works when no log files exist."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_heal(["scan"], env)
        # Should not crash
        assert r.returncode in (0, 1)


class TestNexoHealWhitelist:
    """Tests for command whitelist security."""

    def test_no_eval_in_source(self):
        """nexo-heal source code does NOT contain eval."""
        heal_script = TOOLS_DIR / "nexo-heal"
        content = heal_script.read_text()
        # Should not have bare eval of user-controlled input
        assert 'eval "$fix_cmd"' not in content
        assert "execute_safe_command" in content

    def test_whitelist_exists(self):
        """Whitelist of allowed commands exists in source."""
        heal_script = TOOLS_DIR / "nexo-heal"
        content = heal_script.read_text()
        assert "ALLOWED_COMMANDS" in content
        assert "execute_safe_command" in content

    def test_no_dangerous_commands_in_whitelist(self):
        """Whitelist does not include extremely dangerous commands like 'dd' or 'mkfs'."""
        heal_script = TOOLS_DIR / "nexo-heal"
        content = heal_script.read_text()
        # Very dangerous commands should NOT be in the whitelist
        assert '"dd"' not in content
        assert '"mkfs"' not in content
        assert '"shutdown"' not in content
        # rm is allowed for cleanup, but is validated by the whitelist
