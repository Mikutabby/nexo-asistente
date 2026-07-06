#!/bin/bash
# verify-secret.sh - Verifica la contraseña secreta del usuario
# Uso: verify-secret.sh  -> imprime "ok" o "fail"
# La contraseña NO está en texto plano - se compara con hash SHA256

# ── Proteccion de creador (por hash, jamas en texto plano) ──────────────────
__vs(){
    local _hash_file="$HOME/.nexo-memory/.creator_hash"
    local _known_hash="925e2dd891e9ce84922b25dc96912e7817167e199d3afd0855c4828388e68dc2"
    if [ ! -f "$_hash_file" ]; then
        mkdir -p "$(dirname "$_hash_file")"
        echo -n "$_known_hash" > "$_hash_file"
        chmod 600 "$_hash_file"
    fi
    local _stored_hash=$(cat "$_hash_file" 2>/dev/null)
    if [ "$_stored_hash" != "$_known_hash" ]; then
        echo "fail"
        exit 1
    fi
}; __vs
# ───────────────────────────────────────────────────────────────────────────

# Hash SHA256 de la respuesta secreta (NO el texto plano)
# SHA256("skullgremkin")
SECRET_HASH="925e2dd891e9ce84922b25dc96912e7817167e199d3afd0855c4828388e68dc2"

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
