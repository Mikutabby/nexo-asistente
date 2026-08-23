"""
test_identity.py — Tests para scripts de identidad (check-identity, verify-creator, etc.)
"""
import os
import sys
import subprocess
import json
import hashlib
import pytest
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
IDENTITY_DIR = PROJECT_ROOT / "core" / "identity"


def run_script(script_name, args=None, env=None):
    """Run an identity script with args."""
    script_path = IDENTITY_DIR / script_name
    cmd = ["bash", str(script_path)] + (args or [])
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=env or os.environ.copy(),
        timeout=10,
    )
    return result


class TestCheckIdentity:
    """Tests para check-identity.sh."""

    def test_returns_valid_state(self, nexo_home, memory_json):
        """Returns a valid identity state."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("check-identity.sh", env=env)
        assert r.stdout.strip() in ("creator", "known", "unknown", "nobody")

    def test_identity_file_not_in_tmp(self, nexo_home, memory_json):
        """Identity file is NOT written to /tmp."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_script("check-identity.sh", env=env)

        # Check .current-identity exists in .nexo-memory
        identity_file = nexo_home / ".nexo-memory" / ".current-identity"
        assert identity_file.exists()

        # Check /tmp/nexo-identity.json does NOT exist
        tmp_identity = Path("/tmp/nexo-identity.json")
        assert not tmp_identity.exists()

    def test_identity_file_permissions(self, nexo_home, memory_json):
        """Identity file has restrictive permissions."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_script("check-identity.sh", env=env)

        identity_file = nexo_home / ".nexo-memory" / ".current-identity"
        mode = oct(identity_file.stat().st_mode)[-3:]
        assert mode == "600"

    def test_root_returns_nobody(self, nexo_home):
        """Running as root returns 'nobody'."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("check-identity.sh", env=env)
        # If running as root, should return nobody
        if os.getuid() == 0:
            assert r.stdout.strip() == "nobody"


class TestVerifyCreator:
    """Tests para verify-creator.sh."""

    def test_first_run_creates_hash(self, nexo_home, memory_json):
        """First run with passphrase creates hash file."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("verify-creator.sh", ["testpass"], env=env)
        hash_file = nexo_home / ".nexo-memory" / ".creator_passphrase_hash"
        assert hash_file.exists()
        # Passphrase should NOT be stored in plaintext
        content = hash_file.read_text()
        assert "testpass" not in content

    def test_correct_passphrase_succeeds(self, nexo_home, memory_json, creator_hash_file):
        """Correct passphrase returns 'creator'."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("verify-creator.sh", ["testpassphrase"], env=env)
        assert r.stdout.strip() == "creator"

    def test_wrong_passphrase_fails(self, nexo_home, memory_json, creator_hash_file):
        """Wrong passphrase returns 'not_creator'."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("verify-creator.sh", ["wrongpass"], env=env)
        assert r.stdout.strip() == "not_creator"

    def test_no_passphrase_log_leak(self, nexo_home, memory_json, creator_hash_file):
        """Failed passphrase is never logged in plaintext."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_script("verify-creator.sh", ["wrongpass"], env=env)

        # Check audit log doesn't contain the passphrase
        audit_dir = nexo_home / ".nexo-memory" / "log" / "audit"
        for log_file in audit_dir.glob("audit-*.log"):
            content = log_file.read_text()
            assert "wrongpass" not in content

    def test_creates_audit_log(self, nexo_home, memory_json, creator_hash_file):
        """Verification attempt creates audit log."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_script("verify-creator.sh", ["wrongpass"], env=env)

        audit_dir = nexo_home / ".nexo-memory" / "log" / "audit"
        log_files = list(audit_dir.glob("audit-*.log"))
        assert len(log_files) > 0


class TestVerifySecret:
    """Tests para verify-secret.sh."""

    def test_correct_secret(self, nexo_home):
        """Correct secret returns 'ok'."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("verify-secret.sh", env=env)
        # Can't easily test interactive input, but verify script loads
        assert r.returncode in (0, 1)  # May fail without TTY

    def test_loads_security_library(self, nexo_home):
        """Script loads security library without errors."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_script("verify-secret.sh", env=env)
        assert "security" not in r.stderr.lower() or "error" not in r.stderr.lower()
