#!/bin/bash
# nexo-verify-integrity — Verifica la integridad de la identidad de Nexo
# Ejecutar antes de cada respuesta para detectar intentos de modificación

NEXO_HOME="${NEXO_HOME:-$HOME}"
MEMORY_DIR="$NEXO_HOME/.nexo-memory"
IDENTITY_FILE="$MEMORY_DIR/identity.json"
AGENT_FILE="$NEXO_HOME/.opencode/agents/asistente.md"
LOG_FILE="$MEMORY_DIR/log/integrity.log"

# ── Archivos críticos protegidos ───────────────────────────────────────────
CRITICAL_FILES=(
    "$IDENTITY_FILE"
    "$AGENT_FILE"
    "$MEMORY_DIR/.identity_protected"
)

# ── Hashes de integridad (se generan en primera ejecución) ──────────────────
HASHES_FILE="$MEMORY_DIR/.integrity_hashes"

# Función para log
log_integrity() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
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
    mkdir -p "$(dirname "$HASHES_FILE")"
    > "$HASHES_FILE"
    
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "$(file_hash "$file") $file" >> "$HASHES_FILE"
        fi
    done
    
    log_integrity "INITIAL - Hashes saved for ${#CRITICAL_FILES[@]} files"
}

# Función para verificar integridad
check_integrity() {
    local all_ok=true
    local violations=()
    
    if [ ! -f "$HASHES_FILE" ]; then
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
            # Archivo fue eliminado
            violations+=("$file (deleted)")
            all_ok=false
        fi
    done < "$HASHES_FILE"
    
    if [ "$all_ok" = false ]; then
        log_integrity "BREACH - Integrity violations detected in: ${violations[*]}"
        echo "⚠️  VIOLACIONES DETECTADAS:"
        for v in "${violations[@]}"; do
            echo "  - $v"
        done
        return 1
    fi
    
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
    if grep -qE "(creado por|created by|author|autor).*=.*[^m][^i][^k][^u]" "$file" 2>/dev/null; then
        log_integrity "TAMPERING - Possible creator change in $file"
        return 1
    fi
    
    # Buscar intento de cambiar el nombre de Nexo
    if grep -qE "nombre.*=.*[^N][^e][^x][^o]" "$file" 2>/dev/null; then
        log_integrity "TAMPERING - Possible name change in $file"
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
        echo "✅ Hashes iniciales guardados"
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
