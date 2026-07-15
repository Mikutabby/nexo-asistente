#!/bin/bash
# verify-creator.sh - Sistema de verificacion de creador
# Uso: verify-creator.sh "respuesta del usuario"
# Retorna: 0 si es creator, 1 si no lo es

RESPONSE="${1:-}"
MEMORY_DIR="$HOME/.nexo-memory"
CREATOR_HASH="a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
LOG_FILE="$MEMORY_DIR/log/creator-verification.log"

# Funcion para log
log_verification() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# Normalizar respuesta (lowercase, trim)
NORMALIZED=$(echo "$RESPONSE" | tr '[:upper:]' '[:lower:]' | xargs)

# Verificar si la respuesta coincide con la passphrase del creador
CREATOR_PASS=$(cat "$HOME/.nexo-creator-pass" 2>/dev/null)
if [ "$NORMALIZED" = "$CREATOR_PASS" ]; then
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
        log_verification "SUCCESS - Creator verified"
        echo "creator"
        exit 0
    else
        log_verification "FAILED - No memory file"
        echo "no_memory"
        exit 1
    fi
else
    log_verification "FAILED - Wrong passphrase: '$NORMALIZED'"
    echo "not_creator"
    exit 1
fi
