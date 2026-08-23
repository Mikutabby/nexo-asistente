"""
test_voice.py — Tests para voice preprocessing (say.sh text cleanup)
"""
import os
import sys
import subprocess
import pytest
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
VOICE_DIR = PROJECT_ROOT / "voice"

# Python code for text preprocessing (extracted from say.sh)
PREPROCESS_PY = r"""
import re, sys

text = sys.stdin.read().strip()
if not text:
    sys.exit(0)

# 1. URLs markdown
text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)',
    lambda m: 'Link a ' + m.group(1) if 'http' in m.group(2) else m.group(1), text)

# 2. URLs sueltas
text = re.sub(r'https?://([^\s<>\[\]()]+)',
    lambda m: m.group(1).replace('www.', '').rstrip('/').split('/')[0], text)

# 3. Bloques de codigo
text = re.sub(r'```\w*\n?([\s\S]*?)```', r'\1', text)

# 4. Codigo inline
text = re.sub(r'`([^`]+)`', r'\1', text)

# 5. Negrita
text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)

# 6. Headers
text = re.sub(r'^\s*#{1,6}\s+', '', text, flags=re.MULTILINE)

# 7. Lineas vacias multiples
text = re.sub(r'\n{3,}', '\n\n', text)

print(text.strip())
"""


def run_preprocessing(text):
    """Run the text preprocessing logic."""
    result = subprocess.run(
        ["python3", "-c", PREPROCESS_PY],
        input=text,
        capture_output=True,
        text=True,
        timeout=5,
    )
    return result.stdout.strip()


class TestTextPreprocessing:
    """Tests for text cleanup before TTS."""

    def test_strip_markdown_links(self):
        """Markdown links are converted to text."""
        result = run_preprocessing("Mirá [esta página](https://example.com)")
        assert "https://" not in result
        assert "esta" in result

    def test_strip_bold(self):
        """Bold markdown is stripped."""
        result = run_preprocessing("Texto **importante** aquí")
        assert "**" not in result
        assert "importante" in result

    def test_strip_headers(self):
        """Header markers are removed."""
        result = run_preprocessing("# Título\n## Subtítulo\nContenido")
        assert "#" not in result
        assert "Título" in result

    def test_strip_code_blocks(self):
        """Code blocks are stripped."""
        result = run_preprocessing("```\ncódigo\n```")
        assert "```" not in result
        assert "código" in result

    def test_strip_inline_code(self):
        """Inline code backticks are removed."""
        result = run_preprocessing("Usá `python3` para ejecutar")
        assert "`" not in result
        assert "python3" in result

    def test_urls_simplified(self):
        """Bare URLs are simplified to domain."""
        result = run_preprocessing("Visitá https://www.example.com/path")
        assert "https://" not in result
        assert "example.com" in result

    def test_empty_text(self):
        """Empty text returns empty."""
        result = run_preprocessing("")
        assert result == ""

    def test_preserves_plain_text(self):
        """Plain text is preserved unchanged."""
        result = run_preprocessing("Hola, ¿cómo estás?")
        assert result == "Hola, ¿cómo estás?"


class TestSayScript:
    """Tests for say.sh script structure."""

    def test_script_exists(self):
        """say.sh exists."""
        say_path = VOICE_DIR / "say.sh"
        assert say_path.exists()

    def test_script_has_tts_fallback(self):
        """say.sh has 3-tier TTS fallback."""
        content = (VOICE_DIR / "say.sh").read_text()
        assert "piper" in content.lower() or "PIPER" in content
        assert "gtts" in content.lower() or "gTTS" in content
        assert "espeak" in content.lower()

    def test_script_has_preprocessing(self):
        """say.sh includes text preprocessing."""
        content = (VOICE_DIR / "say.sh").read_text()
        assert "CLEAN_SCRIPT" in content or "re.sub" in content

    def test_voice_script_exists(self):
        """voice.sh exists."""
        voice_path = VOICE_DIR / "voice.sh"
        assert voice_path.exists()
