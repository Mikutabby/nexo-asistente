#!/bin/bash
# check-identity.sh - Detecta al usuario actual del sistema
# Uso: check-identity.sh  -> imprime "creator", "known", "unknown" o "nobody"

# ── Hash de verificacion del creador ────────────────────────────────────────
_CREATOR_HASH="925e2dd891e9ce84922b25dc96912e7817167e199d3afd0855c4828388e68dc2"
# ───────────────────────────────────────────────────────────────────────────

IDENTITY_FILE="/tmp/nexo-identity.json"
MEMORY_DIR="$HOME/.nexo-memory"
CURRENT_USER=$(whoami)
LOG_FILE="$MEMORY_DIR/log/identity-checks.log"

# Funcion para log
log_check() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1 | user: $CURRENT_USER" >> "$LOG_FILE"
}

# Verificar si hay alguien activo (sesion grafica abierta)
if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
    echo "nobody"
    cat > "$IDENTITY_FILE" <<EOF
{"identity":"nobody","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
    log_check "nobody - no user or root"
    exit 0
fi

# Verificar si el usuario tiene memoria guardada
if [ -f "$MEMORY_DIR/memory.json" ]; then
    # Verificar si este usuario ya fue registrado
    USER_HASH=$(echo -n "$CURRENT_USER" | sha256sum | cut -d' ' -f1)
    STORED_USER=$(python3 -c "import json; d=json.load(open('$MEMORY_DIR/memory.json')); print(d.get('user_hash',''))" 2>/dev/null)
    
    if [ "$USER_HASH" = "$STORED_USER" ]; then
        # Verificar si es el creador (tiene la passphrase autorizada)
        CREATOR_STATUS=$(python3 -c "import json; d=json.load(open('$MEMORY_DIR/memory.json')); print(d.get('is_creator', False))" 2>/dev/null)
        
        if [ "$CREATOR_STATUS" = "True" ]; then
            echo "creator"
            cat > "$IDENTITY_FILE" <<EOF
{"identity":"creator","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
            log_check "creator - verified"
        else
            echo "known"
            cat > "$IDENTITY_FILE" <<EOF
{"identity":"known","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
            log_check "known - user with memory"
        fi
    else
        echo "unknown"
        cat > "$IDENTITY_FILE" <<EOF
{"identity":"unknown","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
        log_check "unknown - new user"
    fi
else
    # No hay memoria aun - es primera ejecucion
    echo "unknown"
    cat > "$IDENTITY_FILE" <<EOF
{"identity":"unknown","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
    log_check "unknown - first run"
fi

exit 0
