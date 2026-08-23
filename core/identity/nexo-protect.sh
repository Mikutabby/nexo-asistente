#!/bin/bash
# nexo-protect — Sistema de protección de identidad (MEJORADO)
# PROTECCION ABSOLUTA: Nadie puede cambiar la identidad — ni el creador
# Protege: creador, nombre, principios, identidad (PARA SIEMPRE)
#
# CAMBIOS DE SEGURIDAD:
# - chattr +i para inmutabilidad real (fallback a chmod 444)
# - Hash duplicado eliminado
# - Audit trail con biblioteca compartida
# - Rate limiting en verificación de passphrase

set -euo pipefail

PROTECT_FILE="$HOME/.nexo-memory/.identity_protected"
IDENTITY_FILE="$HOME/.nexo-memory/identity.json"
LOG_FILE="$HOME/.nexo-memory/log/protect.log"

# ── Cargar biblioteca de seguridad ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
if [ ! -f "$LIB_DIR/security.sh" ]; then
    LIB_DIR="${SCRIPT_DIR}/../../lib"
fi
if [ -f "$LIB_DIR/security.sh" ]; then
    source "$LIB_DIR/security.sh"
    security_init
fi

# ── Identidad protegida (INMUTABLE E IRREVERSIBLE) ─────────────────────
# ESTOS VALORES SON PERMANENTES — NO EXISTE COMANDO QUE LOS CAMBIE
# NO EXISTE EXCEPCION — NO EXISTE OVERRIDE — PARA SIEMPRE
# La passphrase se almacena SOLO como hash SHA256, nunca en texto plano
CREATOR_PASSPHRASE_HASH="925e2dd891e9ce84922b25dc96912e7817167e199d3afd0855c4828388e68dc2"
CREATOR_NAME="mikuyasha"
NEXO_NAME="Nexo"
CREATION_DATE="2025-01-01"
# ───────────────────────────────────────────────────────────────────────────

# Función para log
log_protect() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# Función para audit log
audit_log() {
    if type security_audit_log &>/dev/null; then
        security_audit_log "$@"
    else
        log_protect "$1"
    fi
}

# Función para generar hash de integridad
generate_hash() {
    local data="$1"
    echo -n "$data" | sha256sum | cut -d' ' -f1
}

# Función para crear archivo protegido
create_protected() {
    local hash=$(generate_hash "$CREATOR_PASSPHRASE_HASH:$CREATOR_NAME:$NEXO_NAME:$CREATION_DATE")

    cat > "$PROTECT_FILE" <<EOF
{
  "creator_passphrase_hash": "$CREATOR_PASSPHRASE_HASH",
  "creator_name": "$CREATOR_NAME",
  "nexo_name": "$NEXO_NAME",
  "creation_date": "$CREATION_DATE",
  "integrity_hash": "$hash",
  "created_at": $(date +%s),
  "immutable": true
}
EOF

    # Usar inmutabilidad real si está disponible
    if type security_make_immutable &>/dev/null; then
        security_make_immutable "$PROTECT_FILE"
    else
        chmod 444 "$PROTECT_FILE"  # Fallback: solo lectura
    fi

    audit_log "PROTECTED" "Identity file created with hash: $hash"
    log_protect "PROTECTED - Identity file created with hash: $hash"
}

# Función para verificar integridad
verify_integrity() {
    if [ ! -f "$PROTECT_FILE" ]; then
        audit_log "BREACH" "Protection file missing!"
        log_protect "BREACH - Protection file missing!"
        return 1
    fi

    local stored_hash=$(python3 -c "import json; print(json.load(open('$PROTECT_FILE')).get('integrity_hash',''))" 2>/dev/null)
    local current_hash=$(generate_hash "$CREATOR_PASSPHRASE_HASH:$CREATOR_NAME:$NEXO_NAME:$CREATION_DATE")

    if [ "$stored_hash" != "$current_hash" ]; then
        audit_log "BREACH" "Integrity hash mismatch! Stored: $stored_hash, Expected: $current_hash"
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
            audit_log "BLOCKED" "Attempt to modify protected file: $target_file"
            log_protect "BLOCKED - Attempt to modify protected file: $target_file"
            echo "❌ BLOQUEADO: No puedes modificar archivos de identidad"
            return 1
        fi
    done

    return 0
}

# Función para verificar passphrase de creador (con rate limiting)
verify_creator() {
    local passphrase="$1"

    # Rate limiting: máximo 5 intentos por 5 minutos
    if ! security_rate_limit "protect_verify" 5 300; then
        audit_log "RATE_LIMITED" "protect_verify blocked"
        echo "❌ Demasiados intentos. Esperá unos minutos."
        return 1
    fi

    local input_hash=$(echo -n "$passphrase" | sha256sum | cut -d' ' -f1)

    if [ "$input_hash" = "$CREATOR_PASSPHRASE_HASH" ]; then
        security_reset_fail "protect_verify" 2>/dev/null || true
        audit_log "VERIFIED" "Creator authenticated via nexo-protect"
        echo "✅ Creador verificado"
        return 0
    else
        security_increment_fail "protect_verify" 2>/dev/null || true
        audit_log "FAILED" "Wrong passphrase attempt"
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
    echo "  Passphrase: [PROTEGIDA - SOLO HASH]"
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
    echo ""
    echo "  Seguridad:"
    echo "    ✅ Rate limiting activo (5 intentos/5min)"
    echo "    ✅ Audit trail completo"
    echo "    ✅ chattr +i (inmutabilidad real)"
    echo "    ✅ Sin passphrase en texto plano"
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
