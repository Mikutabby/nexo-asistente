"""
test_security.py — Tests para lib/security.sh (rate limiting, audit log, hash)
"""
import os
import sys
import subprocess
import tempfile
import pytest
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
SECURITY_SH = PROJECT_ROOT / "lib" / "security.sh"


def run_security_cmd(cmd, env=None):
    """Run a security.sh function via bash."""
    script = f"""
source "{SECURITY_SH}"
security_init
{cmd}
"""
    result = subprocess.run(
        ["bash", "-c", script],
        capture_output=True,
        text=True,
        env=env or os.environ.copy(),
    )
    return result


class TestSecurityHash:
    """Tests para security_hash."""

    def test_hash_deterministic(self):
        """Same input always produces same hash."""
        r1 = run_security_cmd('security_hash "hello"')
        r2 = run_security_cmd('security_hash "hello"')
        assert r1.stdout.strip() == r2.stdout.strip()

    def test_hash_different_inputs(self):
        """Different inputs produce different hashes."""
        r1 = run_security_cmd('security_hash "hello"')
        r2 = run_security_cmd('security_hash "world"')
        assert r1.stdout.strip() != r2.stdout.strip()

    def test_hash_is_sha256(self):
        """Hash is 64 hex characters (SHA-256)."""
        r = run_security_cmd('security_hash "test"')
        h = r.stdout.strip()
        assert len(h) == 64
        assert all(c in "0123456789abcdef" for c in h)

    def test_hash_with_salt(self):
        """Salt changes the hash."""
        r1 = run_security_cmd('security_hash "hello" "salt1"')
        r2 = run_security_cmd('security_hash "hello" "salt2"')
        assert r1.stdout.strip() != r2.stdout.strip()

    def test_verify_hash_correct(self):
        """Verify hash matches."""
        r = run_security_cmd("""
hash=$(security_hash "mypassword")
if security_verify_hash "mypassword" "$hash"; then
    echo "MATCH"
else
    echo "NOMATCH"
fi
""")
        assert "MATCH" in r.stdout

    def test_verify_hash_incorrect(self):
        """Verify hash doesn't match wrong password."""
        r = run_security_cmd("""
hash=$(security_hash "correct")
if security_verify_hash "wrong" "$hash"; then
    echo "MATCH"
else
    echo "NOMATCH"
fi
""")
        assert "NOMATCH" in r.stdout


class TestSecurityRateLimit:
    """Tests para rate limiting."""

    def test_rate_limit_allows_first_attempt(self, nexo_home):
        """First attempt should be allowed."""
        env = os.environ.copy()
        env["NEXO_SECURITY_DIR"] = str(nexo_home / ".nexo-memory" / ".security")
        r = run_security_cmd('security_rate_limit "test_rl" 3 60; echo $?', env)
        assert r.stdout.strip().endswith("0")

    def test_rate_limit_blocks_after_max(self, nexo_home):
        """Blocks after max attempts."""
        env = os.environ.copy()
        env["NEXO_SECURITY_DIR"] = str(nexo_home / ".nexo-memory" / ".security")

        # Exhaust attempts
        for _ in range(3):
            run_security_cmd('security_rate_limit "test_rl2" 3 60', env)
            run_security_cmd('security_increment_fail "test_rl2"', env)

        # Next attempt should be blocked
        r = run_security_cmd('security_rate_limit "test_rl2" 3 60; echo $?', env)
        assert "1" in r.stdout.strip()


class TestSecurityAuditLog:
    """Tests para audit logging."""

    def test_audit_log_creates_file(self, nexo_home):
        """Audit log creates a log file."""
        env = os.environ.copy()
        env["NEXO_AUDIT_DIR"] = str(nexo_home / ".nexo-memory" / "log" / "audit")
        run_security_cmd('security_audit_log "TEST_EVENT" "test details"', env)

        audit_dir = nexo_home / ".nexo-memory" / "log" / "audit"
        log_files = list(audit_dir.glob("audit-*.log"))
        assert len(log_files) > 0

    def test_audit_log_content(self, nexo_home):
        """Audit log contains event data."""
        env = os.environ.copy()
        env["NEXO_AUDIT_DIR"] = str(nexo_home / ".nexo-memory" / "log" / "audit")
        run_security_cmd('security_audit_log "LOGIN" "user=admin"', env)

        audit_dir = nexo_home / ".nexo-memory" / "log" / "audit"
        log_file = list(audit_dir.glob("audit-*.log"))[0]
        content = log_file.read_text()
        assert "LOGIN" in content
        assert "user=admin" in content


class TestSecurityIdentityFile:
    """Tests para identity file (fuera de /tmp)."""

    def test_identity_file_not_in_tmp(self, nexo_home):
        """Identity file is NOT in /tmp/nexo-identity.json (old insecure location)."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        r = run_security_cmd('security_get_identity_file', env)
        identity_path = r.stdout.strip()
        # The path should NOT be the old insecure /tmp/nexo-identity.json
        assert identity_path != "/tmp/nexo-identity.json"
        # It should be under .nexo-memory
        assert ".nexo-memory" in identity_path

    def test_write_and_read_identity(self, nexo_home):
        """Write identity, then read it back."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_security_cmd('security_write_identity "creator" "mikuyasha"', env)
        r = run_security_cmd('security_read_identity', env)
        assert "creator" in r.stdout
        assert "mikuyasha" in r.stdout

    def test_identity_file_permissions(self, nexo_home):
        """Identity file has restrictive permissions (600)."""
        env = os.environ.copy()
        env["HOME"] = str(nexo_home)
        run_security_cmd('security_write_identity "test" "user"', env)
        r = run_security_cmd('security_get_identity_file', env)
        identity_path = r.stdout.strip()
        mode = oct(os.stat(identity_path).st_mode)[-3:]
        assert mode == "600"
