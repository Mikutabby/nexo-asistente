.PHONY: test test-quick test-slow test-security test-integration lint typecheck clean

# Run all tests
test:
	python3 -m pytest tests/ -v

# Run quick tests only (no slow, no integration)
test-quick:
	python3 -m pytest tests/ -v -m "not slow and not integration"

# Run slow tests
test-slow:
	python3 -m pytest tests/ -v -m "slow"

# Run security tests
test-security:
	python3 -m pytest tests/test_identity.py tests/test_security.py -v

# Run integration tests (requires external services)
test-integration:
	python3 -m pytest tests/ -v -m "integration"

# Lint bash scripts with shellcheck
lint:
	@echo "=== Linting bash scripts ==="
	@command -v shellcheck >/dev/null 2>&1 || echo "shellcheck not installed, skipping"
	@command -v shellcheck >/dev/null 2>&1 && shellcheck -s bash core/identity/*.sh lib/*.sh tools/nexo-heal 2>/dev/null || true
	@echo "=== Linting Python ==="
	@command -v ruff >/dev/null 2>&1 && ruff check memory/nexo-graph tests/ || python3 -m py_compile memory/nexo-graph && echo "Python syntax OK"

# Type check Python
typecheck:
	@echo "=== Type checking Python ==="
	@command -v mypy >/dev/null 2>&1 && mypy memory/nexo-graph --ignore-missing-imports || echo "mypy not installed, skipping"

# Clean test artifacts
clean:
	rm -rf __pycache__ tests/__pycache__ .pytest_cache
	rm -rf /tmp/nexo-test-*
	find . -name "*.pyc" -delete

# Install test dependencies
deps:
	pip3 install pytest pytest-cov 2>/dev/null || pip3 install --break-system-packages pytest pytest-cov 2>/dev/null
