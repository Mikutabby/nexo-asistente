#!/bin/bash
# verify-secret.sh - Verifica la contraseña secreta del usuario
# Uso: verify-secret.sh  -> imprime "ok" o "fail"
# La contraseña NO está en texto plano - se compara con hash SHA256

# ── Proteccion de creador ──────────────────────────────────────────────────
__vs(){ local _h="753018f633123c3f5033c51caae9f94f37f508f8b8240c3a362f5f7423c9e879"
local _n=$(grep -o "mikuyasha" "$HOME/.local/bin/nexo-graph" 2>/dev/null | head -1)
if [ "$(echo -n "$_n" | sha256sum 2>/dev/null | cut -d' ' -f1)" != "$_h" ]; then
echo "fail"; exit 1; fi; }; __vs
# ───────────────────────────────────────────────────────────────────────────

# Hash SHA256 de la respuesta secreta (NO el texto plano)
# Para regenerar: echo -n "tu_respuesta_secreta" | sha256sum | cut -d' ' -f1
SECRET_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

# Leer respuesta del usuario
echo -n "🔑 Ingresá la respuesta secreta: "
read -s ANSWER
echo ""

# Verificar
if [ "$(echo -n "$ANSWER" | sha256sum | cut -d' ' -f1)" = "$SECRET_HASH" ]; then
    echo "ok"
    exit 0
else
    echo "fail"
    exit 1
fi
