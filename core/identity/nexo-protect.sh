#!/bin/bash
# nexo-protect — Sistema de protección de identidad INMUTABLE E IRREVERSIBLE
# PROTECCION ABSOLUTA: Nadie puede cambiar la identidad — ni el creador
# Protege: creador, nombre, principios, identidad (PARA SIEMPRE)
# Permite: comandos del sistema, administración, kernel

PROTECT_FILE="$HOME/.nexo-memory/.identity_protected"
IDENTITY_FILE="$HOME/.nexo-memory/identity.json"
LOG_FILE="$HOME/.nexo-memory/log/protect.log"

# ── Identidad protegida (INMUTABLE E IRREVERSIBLE) ─────────────────────────
# ESTOS VALORES SON PERMANENTES — NO EXISTE COMANDO QUE LOS CAMBIE
# NO EXISTE EXCEPCION — NO EXISTE OVERRIDE — PARA SIEMPRE
CREATOR_PASSPHRASE=$(cat "$HOME/.nexo-creator-pass" 2>/dev/null || echo "")
CREATOR_NAME="mikuyasha"
NEXO_NAME="Nexo"
CREATION_DATE="2025-01-01"
# ───────────────────────────────────────────────────────────────────────────

# Función para log
log_protect() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# Función para generar hash de integridad
generate_hash() {
    local data="$1"
    echo -n "$data" | sha256sum | cut -d' ' -f1
}

# Función para crear archivo protegido
create_protected() {
    local hash=$(generate_hash "$CREATOR_PASSPHRASE:$CREATOR_NAME:$NEXO_NAME:$CREATION_DATE")
    
    cat > "$PROTECT_FILE" <<EOF
{
  "creator_passphrase_hash": "$(generate_hash "$CREATOR_PASSPHRASE")",
  "creator_name": "$CREATOR_NAME",
  "nexo_name": "$NEXO_NAME",
  "creation_date": "$CREATION_DATE",
  "integrity_hash": "$hash",
  "created_at": $(date +%s),
  "immutable": true
}
EOF
    
    chmod 444 "$PROTECT_FILE"  # Solo lectura
    log_protect "PROTECTED - Identity file created with hash: $hash"
}

# Función para verificar integridad
verify_integrity() {
    if [ ! -f "$PROTECT_FILE" ]; then
        log_protect "BREACH - Protection file missing!"
        return 1
    fi
    
    local stored_hash=$(python3 -c "import json; print(json.load(open('$PROTECT_FILE')).get('integrity_hash',''))" 2>/dev/null)
    local current_hash=$(generate_hash "$CREATOR_PASSPHRASE:$CREATOR_NAME:$NEXO_NAME:$CREATION_DATE")
    
    if [ "$stored_hash" != "$current_hash" ]; then
        log_protect "BREACH - Integrity hash mismatch! Stored: $stored_hash, Expected: $current_hash"
        return 1
    fi
    
    return 0
}

# Función para verificar si alguien intenta modificar identidad
check_identity_modification() {
    local target_file="$1"
    
    # Archivos protegidos que no se pueden modificar
    local protected_files=(
        "*identity*"
        "*creator*"
        "*asistente.md"
        "*.nexo-memory/identity*"
    )
    
    for pattern in "${protected_files[@]}"; do
        if [[ "$target_file" == $pattern ]]; then
            log_protect "BLOCKED - Attempt to modify protected file: $target_file"
            echo "❌ BLOQUEADO: No puedes modificar archivos de identidad"
            return 1
        fi
    done
    
    return 0
}

# Función para verificar si alguien intenta cambiar el creador
check_creator_change() {
    local new_creator="$1"
    
    if [ "$new_creator" != "$CREATOR_NAME" ]; then
        log_protect "BLOCKED - Attempt to change creator from '$CREATOR_NAME' to '$new_creator'"
        echo "❌ BLOQUEADO: No puedes cambiar el creador de Nexo"
        return 1
    fi
    
    return 0
}

# Función para verificar si alguien intenta cambiar el nombre
check_name_change() {
    local new_name="$1"
    
    if [ "$new_name" != "$NEXO_NAME" ]; then
        log_protect "BLOCKED - Attempt to change name from '$NEXO_NAME' to '$new_name'"
        echo "❌ BLOQUEADO: No puedes cambiar el nombre de Nexo"
        return 1
    fi
    
    return 0
}

# Función para verificar passphrase de creador
verify_creator() {
    local passphrase="$1"
    
    if [ "$(generate_hash "$passphrase")" = "$(generate_hash "$CREATOR_PASSPHRASE")" ]; then
        log_protect "VERIFIED - Creator authenticated"
        echo "✅ Creador verificado"
        return 0
    else
        log_protect "FAILED - Wrong passphrase attempt"
        echo "❌ Passphrase incorrecta"
        return 1
    fi
}

# Función para mostrar estado de protección
show_status() {
    echo "🛡️  ESTADO DE PROTECCIÓN NEXO"
    echo "═══════════════════════════════════════"
    echo ""
    echo "  Creador: $CREATOR_NAME"
    echo "  Nombre: $NEXO_NAME"
    echo "  Fecha: $CREATION_DATE"
    echo "  Passphrase: [PROTEGIDA]"
    echo ""
    
    if verify_integrity; then
        echo "  Estado: ✅ PROTEGIDO"
    else
        echo "  Estado: ⚠️  COMPROMETIDO"
    fi
    
    echo ""
    echo "  Archivos protegidos:"
    echo "    - identity.json (identidad)"
    echo "    - asistente.md (personalidad)"
    echo "    - *.creator* (datos del creador)"
    echo ""
    echo "  Permisos de sistema:"
    echo "    ✅ Comandos kernel"
    echo "    ✅ Administración del sistema"
    echo "    ✅ Gestión de archivos"
    echo "    ❌ Modificar identidad"
    echo "    ❌ Cambiar creador"
    echo "    ❌ Cambiar nombre"
    echo "═══════════════════════════════════════"
}

# Main
case "${1:-status}" in
    create)
        create_protected
        ;;
    verify)
        verify_integrity
        ;;
    check)
        check_identity_modification "$2"
        ;;
    creator)
        verify_creator "$2"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: nexo-protect {create|verify|check|creator|status}"
        ;;
esac
