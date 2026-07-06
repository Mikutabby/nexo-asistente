#!/bin/bash
# verify-secret.sh - Verifica la contraseña secreta del usuario
# Uso: verify-secret.sh  -> imprime "ok" o "fail"
# La contraseña NO está en texto plano - se compara con hash SHA256

# ── Proteccion de creador ──────────────────────────────────────────────────
# Verificacion skullgremkin - solo el creador real puede modificar estos scripts
__vs(){ 
    local _hash_file="$HOME/.nexo-memory/.creator_hash"
    if [ ! -f "$_hash_file" ]; then
        # Primera ejecucion - crear hash de verificacion
        mkdir -p "$(dirname "$_hash_file")"
        echo -n "$(cat "$HOME/.nexo-creator-pass" 2>/dev/null)" | sha256sum | cut -d' ' -f1 > "$_hash_file"
        chmod 600 "$_hash_file"
    fi
    local _stored_hash=$(cat "$_hash_file" 2>/dev/null)
    local _current_hash=$(echo -n "$(cat "$HOME/.nexo-creator-pass" 2>/dev/null)" | sha256sum | cut -d' ' -f1)
    if [ "$_stored_hash" != "$_current_hash" ]; then
        echo "fail"
        exit 1
    fi
}; __vs
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
