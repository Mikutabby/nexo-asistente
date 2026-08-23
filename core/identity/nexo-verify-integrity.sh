#!/bin/bash
# nexo-verify-integrity — Verifica la integridad de la identidad de Nexo (MEJORADO)
# Ejecutar antes de cada respuesta para detectar intentos de modificación
#
# CAMBIOS DE SEGURIDAD:
# - Hashes almacenados en directorio separado con permisos restrictivos
# - detect_creator_tampering ahora se ejecuta en cada check
# - Audit trail con biblioteca compartida
# - Regex mejorado para tamper detection

set -euo pipefail

NEXO_HOME="${NEXO_HOME:-$HOME}"
MEMORY_DIR="$NEXO_HOME/.nexo-memory"
IDENTITY_FILE="$MEMORY_DIR/identity.json"
AGENT_FILE="$NEXO_HOME/.opencode/agents/asistente.md"
LOG_FILE="$MEMORY_DIR/log/integrity.log"

# ── Directorio separado para hashes (no junto a los archivos protegidos) ──
SECURITY_HASHES_DIR="$NEXO_HOME/.nexo-memory/.security"
HASHES_FILE="$SECURITY_HASHES_DIR/integrity_hashes"

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

# ── Archivos críticos protegidos ───────────────────────────────────────────
CRITICAL_FILES=(
    "$IDENTITY_FILE"
    "$AGENT_FILE"
    "$MEMORY_DIR/.identity_protected"
)

# Función para log
log_integrity() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# Función para audit log
audit_log() {
    if type security_audit_log &>/dev/null; then
        security_audit_log "$@"
    else
        log_integrity "$1"
    fi
}

# Función para generar hash de archivo
file_hash() {
    if [ -f "$1" ]; then
        sha256sum "$1" | cut -d' ' -f1
    else
        echo "missing"
    fi
}

# Función para guardar hashes iniciales
save_initial_hashes() {
    mkdir -p "$SECURITY_HASHES_DIR"
    chmod 700 "$SECURITY_HASHES_DIR"
    > "$HASHES_FILE"

    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "$(file_hash "$file") $file" >> "$HASHES_FILE"
        fi
    done

    chmod 600 "$HASHES_FILE"
    audit_log "INITIAL" "Hashes saved for ${#CRITICAL_FILES[@]} files in $SECURITY_HASHES_DIR"
    log_integrity "INITIAL - Hashes saved for ${#CRITICAL_FILES[@]} files"
}

# Función para verificar integridad
check_integrity() {
    local all_ok=true
    local violations=()

    if [ ! -f "$HASHES_FILE" ]; then
        audit_log "WARNING" "No hash file found, creating initial hashes"
        log_integrity "WARNING - No hash file found, creating initial hashes"
        save_initial_hashes
        return 0
    fi

    while IFS=' ' read -r stored_hash file; do
        if [ -f "$file" ]; then
            local current_hash=$(file_hash "$file")
            if [ "$stored_hash" != "$current_hash" ]; then
                violations+=("$file")
                all_ok=false
            fi
        else
            violations+=("$file (deleted)")
            all_ok=false
        fi
    done < "$HASHES_FILE"

    # Ejecutar tamper detection en cada check
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            if ! detect_creator_tampering "$file"; then
                violations+=("$file (creator tampering)")
                all_ok=false
            fi
        fi
    done

    if [ "$all_ok" = false ]; then
        audit_log "BREACH" "Integrity violations: ${violations[*]}"
        log_integrity "BREACH - Integrity violations detected in: ${violations[*]}"
        echo "⚠️  VIOLACIONES DETECTADAS:"
        for v in "${violations[@]}"; do
            echo "  - $v"
        done
        return 1
    fi

    audit_log "OK" "All files intact"
    log_integrity "OK - All files intact"
    return 0
}

# Función para detectar intentos de modificación de creador
detect_creator_tampering() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 0
    fi

    # Buscar patrones sospechosos de cambio de creador
    # Mejorado: más estricto con caracteres después de "author|autor"
    if grep -qiE "(creado por|created by|author|autor)\s*[:=]\s*[^m]" "$file" 2>/dev/null; then
        audit_log "TAMPERING" "Possible creator change detected in $file"
        log_integrity "TAMPERING - Possible creator change in $file"
        return 1
    fi

    # Buscar intento de cambiar el nombre de Nexo
    if grep -qiE "nombre\s*[:=]\s*[^N]" "$file" 2>/dev/null; then
        audit_log "TAMPERING" "Possible name change detected in $file"
        log_integrity "TAMPERING - Possible name change in $file"
        return 1
    fi

    # Buscar intento de cambiar el hash del creador
    if grep -qE "CREATOR_PASSPHRASE_HASH\s*=\s*[\"'][^9]" "$file" 2>/dev/null; then
        audit_log "TAMPERING" "Possible creator hash modification in $file"
        log_integrity "TAMPERING - Possible creator hash modification in $file"
        return 1
    fi

    return 0
}

# Función para mostrar estado
show_status() {
    echo "🔍 VERIFICACIÓN DE INTEGRIDAD"
    echo "═══════════════════════════════════════"
    echo ""

    if [ ! -f "$HASHES_FILE" ]; then
        echo "  Estado: ⚠️  No hay hashes guardados"
        echo "  Acción: Ejecutar 'init' para crear hashes iniciales"
        return
    fi

    local total=${#CRITICAL_FILES[@]}
    local protected=0

    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✅ $file"
            protected=$((protected + 1))
        else
            echo "  ❌ $file (missing)"
        fi
    done

    echo ""
    echo "  Archivos protegidos: $protected/$total"
    echo "  Hashes almacenados en: $SECURITY_HASHES_DIR"

    if check_integrity > /dev/null 2>&1; then
        echo "  Estado: ✅ INTEGRO"
    else
        echo "  Estado: ⚠️  COMPROMETIDO"
    fi

    echo ""
    echo "═══════════════════════════════════════"
}

# Main
case "${1:-status}" in
    init)
        save_initial_hashes
        echo "✅ Hashes iniciales guardados en $SECURITY_HASHES_DIR"
        ;;
    check)
        if check_integrity; then
            echo "✅ Integridad verificada"
        else
            echo "⚠️  Violaciones detectadas - revisar log"
        fi
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: nexo-verify-integrity {init|check|status}"
        ;;
esac
