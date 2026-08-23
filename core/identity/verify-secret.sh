#!/bin/bash
# verify-secret.sh - Verifica la contraseña secreta del usuario (SEGURO)
# Uso: verify-secret.sh  -> imprime "ok" o "fail"
# La contraseña NO está en texto plano - se compara con hash SHA256
#
# CAMBIOS DE SEGURIDAD:
# - Rate limiting tras intentos fallidos
# - Nunca loggea passphrase (ni correcta ni incorrecta)
# - Audit trail completo
# - Timeout de sesión

set -euo pipefail

# ── Cargar biblioteca de seguridad ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
if [ ! -f "$LIB_DIR/security.sh" ]; then
    LIB_DIR="${SCRIPT_DIR}/../../lib"
fi
if [ -f "$LIB_DIR/security.sh" ]; then
    source "$LIB_DIR/security.sh"
    security_init
else
    # Fallback: funciones mínimas
    security_audit_log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') | $1 | $2" >> "$HOME/.nexo-memory/log/audit/audit-$(date +%Y-%m-%d).log"; }
    security_hash() { echo -n "$1" | sha256sum | cut -d' ' -f1; }
    NEXO_SECURITY_DIR="$HOME/.nexo-memory/.security"
    mkdir -p "$NEXO_SECURITY_DIR"
fi

# ── Proteccion de creador (por hash, jamas en texto plano) ──────────────
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
        security_audit_log "INTEGRITY_FAIL" "Creator hash mismatch in verify-secret"
        echo "fail"
        exit 1
    fi
}; __vs
# ───────────────────────────────────────────────────────────────────────────

# ── Rate limiting: máximo 5 intentos por 5 minutos ─────────────────────
if ! security_lockout_check "verify_secret" 300; then
    security_audit_log "LOCKOUT" "verify_secret blocked due to rate limit"
    echo "fail"
    exit 1
fi

if ! security_rate_limit "verify_secret" 5 300; then
    security_increment_fail "verify_secret"
    security_audit_log "RATE_LIMITED" "verify_secret"
    echo "fail"
    exit 1
fi

# Hash SHA256 de la respuesta secreta (NO el texto plano)
SECRET_HASH="925e2dd891e9ce84922b25dc96912e7817167e199d3afd0855c4828388e68dc2"

# Leer respuesta del usuario
echo -n "🔑 Ingresá la respuesta secreta: "
read -s ANSWER
echo ""

# Verificar (comparar hashes, NUNCA texto plano)
INPUT_HASH=$(security_hash "$ANSWER")

if [ "$INPUT_HASH" = "$SECRET_HASH" ]; then
    # ÉXITO: resetear contador
    security_reset_fail "verify_secret"
    security_audit_log "VERIFIED" "Secret verified successfully"
    echo "ok"
    exit 0
else
    # FALLO: incrementar contador, loggear SIN passphrase
    security_increment_fail "verify_secret"
    security_audit_log "FAILED" "Wrong secret (attempt #$(cat "$NEXO_SECURITY_DIR/fail_verify_secret" 2>/dev/null | cut -d: -f1 || echo '?'))"
    echo "fail"
    exit 1
fi
