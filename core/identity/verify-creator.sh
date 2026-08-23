#!/bin/bash
# verify-creator.sh - Sistema de verificacion de creador (SEGURO)
# Uso: verify-creator.sh "respuesta del usuario"
# Retorna: 0 si es creator, 1 si no lo es
#
# CAMBIOS DE SEGURIDAD:
# - NO almacena passphrase en texto plano (solo hash)
# - Rate limiting exponencial tras intentos fallidos
# - Nunca loggea passphrase fallida (solo loggea intento)
# - Audit trail completo

set -euo pipefail

RESPONSE="${1:-}"
MEMORY_DIR="$HOME/.nexo-memory"
HASH_FILE="$MEMORY_DIR/.creator_passphrase_hash"
LOG_FILE="$MEMORY_DIR/log/creator-verification.log"

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
    # Fallback: funciones mínimas si no existe la lib
    security_audit_log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') | $1 | $2" >> "$LOG_FILE"; }
    security_hash() { echo -n "$1" | sha256sum | cut -d' ' -f1; }
    NEXO_SECURITY_DIR="$MEMORY_DIR/.security"
    mkdir -p "$NEXO_SECURITY_DIR"
fi

# ── Rate limiting: máximo 5 intentos por 5 minutos ─────────────────────
if ! security_lockout_check "verify_creator" 300; then
    security_audit_log "LOCKOUT" "verify_creator blocked due to rate limit"
    echo "not_creator"
    exit 1
fi

if ! security_rate_limit "verify_creator" 5 300; then
    security_increment_fail "verify_creator"
    security_audit_log "RATE_LIMITED" "verify_creator"
    echo "not_creator"
    exit 1
fi

# ── Verificar hash del passphrase ──────────────────────────────────────
# El passphrase NUNCA se almacena en texto plano.
# Se compara el hash SHA256 del input contra el hash guardado.

if [ ! -f "$HASH_FILE" ]; then
    # Primer uso: guardar hash del passphrase proporcionado
    # NOTA: La primera vez que se ejecuta, el usuario debe pasar la passphrase
    # y se guarda SOLO el hash, nunca el texto plano.
    if [ -n "$RESPONSE" ]; then
        mkdir -p "$(dirname "$HASH_FILE")"
        security_hash "$RESPONSE" > "$HASH_FILE"
        chmod 600 "$HASH_FILE"
        security_audit_log "HASH_CREATED" "Creator passphrase hash initialized"
        echo "creator"
        exit 0
    else
        security_audit_log "NO_HASH_FILE" "No passphrase hash found and no input provided"
        echo "no_memory"
        exit 1
    fi
fi

# Normalizar respuesta (lowercase, trim)
NORMALIZED=$(echo "$RESPONSE" | tr '[:upper:]' '[:lower:]' | xargs)

# Comparar hash
STORED_HASH=$(cat "$HASH_FILE" 2>/dev/null)
INPUT_HASH=$(security_hash "$NORMALIZED")

if [ "$INPUT_HASH" = "$STORED_HASH" ]; then
    # ÉXITO: resetear contador de intentos
    security_reset_fail "verify_creator"
    security_audit_log "VERIFIED" "Creator authenticated successfully"

    # Marcar usuario como creador en memoria
    if [ -f "$MEMORY_DIR/memory.json" ]; then
        python3 -c "
import json
with open('$MEMORY_DIR/memory.json', 'r') as f:
    data = json.load(f)
data['is_creator'] = True
data['creator_verified_at'] = $(date +%s)
with open('$MEMORY_DIR/memory.json', 'w') as f:
    json.dump(data, f, indent=2)
"
        echo "creator"
        exit 0
    else
        security_audit_log "NO_MEMORY" "Memory file missing after verification"
        echo "no_memory"
        exit 1
    fi
else
    # FALLO: incrementar contador, loggear sin passphrase
    security_increment_fail "verify_creator"
    security_audit_log "FAILED" "Wrong passphrase (attempt #$(cat "$NEXO_SECURITY_DIR/fail_verify_creator" 2>/dev/null | cut -d: -f1 || echo '?'))"
    echo "not_creator"
    exit 1
fi
