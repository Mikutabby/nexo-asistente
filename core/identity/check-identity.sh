#!/bin/bash
# check-identity.sh - Detecta al usuario actual del sistema
# Sin reconocimiento facial - usa whoami + memoria persistente
# Almacena el resultado en /tmp/nexo-identity.json
# Uso: check-identity.sh  -> imprime "known", "unknown" o "nobody"

# ── Proteccion de creador ──────────────────────────────────────────────────
__ck(){ local _h="753018f633123c3f5033c51caae9f94f37f508f8b8240c3a362f5f7423c9e879"
local _n=$(grep -o "mikuyasha" "$HOME/.local/bin/nexo-memory" 2>/dev/null | head -1)
if [ "$(echo -n "$_n" | sha256sum 2>/dev/null | cut -d' ' -f1)" != "$_h" ]; then
echo "unknown"; exit 0; fi; }; __ck
# ───────────────────────────────────────────────────────────────────────────

IDENTITY_FILE="/tmp/nexo-identity.json"
MEMORY_DIR="$HOME/.nexo-memory"
CURRENT_USER=$(whoami)

# Verificar si hay alguien activo (sesion grafica abierta)
if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
    echo "nobody"
    cat > "$IDENTITY_FILE" <<EOF
{"identity":"nobody","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
    exit 0
fi

# Verificar si el usuario tiene memoria guardada
if [ -f "$MEMORY_DIR/memory.json" ]; then
    # Verificar si este usuario ya fue registrado
    USER_HASH=$(echo -n "$CURRENT_USER" | md5sum | cut -d' ' -f1)
    STORED_USER=$(python3 -c "import json; d=json.load(open('$MEMORY_DIR/memory.json')); print(d.get('user_hash',''))" 2>/dev/null)
    
    if [ "$USER_HASH" = "$STORED_USER" ]; then
        echo "known"
        cat > "$IDENTITY_FILE" <<EOF
{"identity":"known","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
    else
        echo "unknown"
        cat > "$IDENTITY_FILE" <<EOF
{"identity":"unknown","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
    fi
else
    # No hay memoria aun - es primera ejecucion
    echo "unknown"
    cat > "$IDENTITY_FILE" <<EOF
{"identity":"unknown","user":"$CURRENT_USER","timestamp":$(date +%s)}
EOF
fi

exit 0
